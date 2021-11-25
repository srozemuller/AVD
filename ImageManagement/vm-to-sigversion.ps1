param(

    [parameter(Mandatory)]
    [string]$subscriptionId,
    
    [parameter(Mandatory, ValueFromPipelineByPropertyName)]
    $SysprepScript,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VirtualMachineName,

    [parameter(Mandatory)]
    [string]$imageVersion
)

Install-Module -Name Az.Avd -Force -Verbose -Scope CurrentUser
Import-Module az.compute


Set-Azcontext -Subscription $subscriptionId

$hostpoolParameters = @{ 
    HostpoolName = $HostpoolName
    ResourceGroupName =  $HostpoolResourceGroup
}

function test-VMstatus($virtualMachineName) {
    $vmStatus = Get-AzVM -name $virtualMachineName -Status
    return "$virtualMachineName status " + $vmstatus.PowerState
}
Write-Verbose "No parameter path provided, looking for existing enviroment"
$sessionHosts = Get-AvdSessionHostResources @hostpoolParameters | Select-Object -Last 1

Write-Host "Found sessionhost, latest is $($sessionHosts.name)"
$imageReference = $sessionHosts.vmResources.properties.storageprofile.ImageReference
if ($null -ne $imageReference.ExactVersion) {
    $galleryImageDefinition = Get-AzGalleryImageDefinition -ResourceId $imageReference.id
    $gallery = Get-AzGallery -ResourceGroupName $galleryImageDefinition.ResourceGroupName | Where-Object {$imageReference.id -match $_.id}
    $SnapshotName = ($imageVersion + "-BS")
}
else {
    Throw "No exact version found, looks like an image is used instead of SIG version."
}

try {
    $vm = Get-AzVM -name $virtualMachineName
}
catch {
    Throw "Virtual machine $virtualMachineName not found. $_"
}

# Write-Output "Stopping VM $virtualMachineName"
# Stopping VM for creating clean snapshot

#$vm | Stop-AzVM -Force -StayProvisioned
# If VM is stopped, create snapshot Before Sysprep
$SnapshotConfig = New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $gallery.location -CreateOption copy
$snapshotName = ($virtualMachineName + "-BS")
Write-Output "Creating snapshot $snapshotName for $virtualMachineName"
New-AzSnapshot -Snapshot $SnapshotConfig -SnapshotName $snapshotName -ResourceGroupName $gallery.ResourceGroupName

$ImageParameters = @{
    GalleryImageDefinitionName = $galleryImageDefinition.Name
    GalleryImageVersionName    = $imageVersion
    GalleryName                = $gallery.Name
    ResourceGroupName          = $gallery.ResourceGroupName
    Location                   = $gallery.Location
    SourceImageId              = $vm.id.ToString()
}

$vm | Invoke-AzVMRunCommand -CommandId 'RunPowerShellScript' -ScriptPath $SysprepScript
Write-Output "$virtualMachineName is going to be generalized, waiting till vm is stopped"
do {
    $status = test-vmStatus -virtualMachineName $virtualMachineName
    $status
    Start-Sleep 10
} until ( $status -match "stopped")
Write-Output "$virtualMachineName has status $status"
$vm | Set-AzVm -Generalized

Write-Output "Creating imageversion $ImageVersion in $galleryImageDefintion"
New-AzGalleryImageVersion @ImageParameters

# Testing if evertything went OK.
try {
    Get-AzGalleryImageVersion -ResourceGroupName $gallery.ResourceGroupName -GalleryName $gallery.Name -GalleryImageDefinitionName $galleryImageDefintion -Name $imageVersion
}
catch {
    Throw $_
}