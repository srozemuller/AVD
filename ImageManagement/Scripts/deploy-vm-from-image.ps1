<#
    .SYNOPSIS
    This script creates a VM from an image version based on an AVD session host.
    .DESCRIPTION
    The script searches for a last session host in an AVD hostpool. From that host, the script searches for the image gallery to take the lastest version.
    Based on that version, it will create a new VM in a temporary resource group. If needed, it will also assign a public ip to the VM.
    .PARAMETER resourceGroupName
    The temporary resource group name
    .PARAMETER diskSizeGB
    Fill in the disksize in GB
    .PARAMETER VirtualMachineName
    Fill in the virtual machine name which will be created.

    #>
param(
    [parameter(Mandatory)]
    [string]$subscriptionId,

    [parameter(Mandatory)]
    [string]$GalleryName, 

    [parameter(Mandatory)]
    [string]$GalleryResourceGroupName,

    [parameter(Mandatory)]
    [string]$GalleryDefinitionName, 
    
    [parameter()]
    [int]$diskSizeGB,
    
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VirtualMachineName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Identifier

)

Set-Azcontext -Subscription $subscriptionId


function New-RandomString($type) {
    function Get-RandomCharacters($length, $characters) {
        $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
        $private:ofs = ""
        return [String]$characters[$random]
    }
    if ($type -eq 'username') {
        $username = Get-RandomCharacters -length 8 -characters 'abcdefghiklmnoprstuvwxyz'
        return $username
    }
    if ($type -eq 'password') {
        $password = Get-RandomCharacters -length 6 -characters 'abcdefghiklmnoprstuvwxyz'
        $password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
        $password += Get-RandomCharacters -length 2 -characters '1234567890'
        $password += Get-RandomCharacters -length 2 -characters '!%&()=#+'
        return $password
    }
}

$updateVmTags = @{
    Type = "Update VM"
}
#Testing if there is allready an AVD VM with an update status
$testUpdateVM = Get-AzVM | Where-Object { $_.Tags['Type'] -like $updateVmTags.Values }
if ($testUpdateVM) {
    Write-Error "There is already an update VM: $($($testUpdateVM).Name)"
    Throw "There is allready an update virutal machine $($($testUpdateVM).Name), $_"
}

# Determine disksize
if ($DiskSizeGB -gt 0) {
    "New disk size provided, $DiskSizeGB GB"
}
else { 
    $DiskSizeGB = 128
}


$resourceGroupName = "rg-$($Identifier)"
$location = 'WestEurope'
$subnet = New-AzVirtualNetworkSubnetConfig -Name "tmp$($Identifier)" -AddressPrefix "10.0.0.0/24"
$vnet = New-AzVirtualNetwork -Name "tmpVnet$($Identifier)" -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet
$subnetId = (Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet.Name).Id
Write-Output "##vso[task.setvariable variable=Subnet;isOutput=true]$($subnet.id)"
Write-Output "Subnet is $subnet"

$nicParameters = @{
    Name              = "nic-$($Identifier)"
    ResourceGroupName = $resourceGroupName
    Location          = $location
    SubnetId          = $subnetId
}
$nic = New-AzNetworkInterface @nicParameters
$vmSize = "Standard_B2MS"
$adminUsername = New-RandomString -type username
$adminPassword = New-RandomString -type password
$computerName = 'cn' + $VirtualMachineName.Replace(".", "")
if ($VirtualMachineName.Length -gt 15) {
    Write-Warning "Computername $computername is longer than 15 chars, renaming it to the first 15 chars."
    $computerName = $computerName.Substring(0, 15)
}

$password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $password)
$VirtualMachine = New-AzVMConfig -VMName $VirtualMachineName -VMSize $VmSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $computerName -ProvisionVMAgent -EnableAutoUpdate -Credential $Credential
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $DiskSizeGB
#Image source definition
try {
    $versionParameters = @{
        ResourceGroupName          = $GalleryResourceGroupName
        GalleryName                = $GalleryName
        GalleryImageDefinitionName = $GalleryDefinitionName
    }
    $galleryImageVersion = Get-AzGalleryImageVersion @versionParameters | Select-Object Id, Name -Last 1
    if ($null -eq $galleryImageVersion) {
        Write-Warning "No image version found, it looks like definition $GalleryDefinitionName is empty."
    }
    else {
        $galleryVersionId = $galleryImageVersion.id
        $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Id $galleryVersionId
    }
}
catch {
    Throw "No image version found in gallery $GalleryName under $GalleryDefinitionName!"
}
try {
    New-AzVM -ResourceGroupName $resourceGroupName -Location $Location -VM $VirtualMachine
    Write-Host "Username $adminUsername"
    Write-Host "Password $adminPassword"
    Write-Host "Created $VirtualMachineName"
    Write-Output "##vso[task.setvariable variable=VirtualMachineName;isOutput=true]$VirtualMachineName"
    Write-Output "##vso[task.setvariable variable=resourceGroupName;isOutput=true]$resourceGroupName"
    Write-Output "##vso[task.setvariable variable=VmAdminUsername;isOutput=true]$adminUsername"
    Write-Output "##vso[task.setvariable variable=VmAdminPassword;isOutput=true]$adminPassword"
}
catch {
    Write-Error $_
}