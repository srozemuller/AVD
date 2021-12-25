[CmdletBinding()]
param
(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [parameter()]
    [ValidateNotNullOrEmpty()]
    [switch]$AADJoin,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$HostpoolName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$hostpoolDescription,
    
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$location,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Pooled", "Personal")]
    [string]$hostPoolType,

    [parameter(Mandatory)]
    [ValidateSet("BreadthFirst", "DepthFirst")]
    [ValidateNotNullOrEmpty()]
    [string]$loadBalancerType,

    [parameter(Mandatory)]
    [ValidateSet("Desktop", "RemoteApp")]
    [ValidateNotNullOrEmpty()]
    [string]$preferredAppGroupType,
        
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [boolean]$validationEnvironment = $true,

    [parameter()]
    [ValidateNotNullOrEmpty()]
    [boolean]$startVMOnConnect = $true,
        
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Automatic", "Direct")]
    [string]$PersonalDesktopAssignmentType = "Automatic",

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1, 999999)]
    [int]$maxSessionLimit,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StartOnConnectRoleName,

    [parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$prefix,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$appGroupName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$appGroupFriendlyName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$appGroupDescription,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Desktop", "RemoteApp")]
    [string]$appGroupType,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceFriendlyName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceDescription,

    [parameter()]
    [ValidateNotNullOrEmpty()]
    [switch]$Force
)
Install-Module -Name Az.Avd -AllowPrerelease -Force -Verbose -Scope CurrentUser
Import-Module -Name Az.Avd

Set-AzContext -Subscription $subscriptionId

$hostpoolParameters = @{
    HostpoolName          = $hostpoolName
    Description           = $hostpoolDescription
    ResourceGroupName     = $ResourceGroupName
    Location              = $location
    HostpoolType          = $hostPoolType
    LoadBalancerType      = $loadBalancerType
    preferredAppGroupType = $preferredAppGroupType
}

Write-Verbose "Deploying hostpool $hostpoolName"
$avdHostpool = New-AvdHostpool @hostpoolParameters

if ($AADJoin) {
    Update-AvdHostpool -HostpoolName $HostpoolName -ResourceGroupName $ResourceGroupName -CustomRdpProperty "targetisaadjoined:i:1"
}

$applicationGroupParameters = @{
    Name                 = $appGroupName
    ResourceGroupName    = $ResourceGroupName
    Location             = $location
    FriendlyName         = $appGroupFriendlyName
    Description          = $appGroupDescription
    HostPoolArmPath      = "$($avdHostpool.id)"
    ApplicationGroupType = $appGroupType
}
$applicationGroup = New-AvdApplicationGroup @applicationGroupParameters
  
Add-AvdApplicationGroupPermissions -ResourceId $($applicationGroup.id) -GroupName "All Users"

$workSpaceParameters = @{
    Name                      = $workSpaceName
    ResourceGroupName         = $ResourceGroupName
    Location                  = $location
    FriendlyName              = $workspaceFriendlyName
    ApplicationGroupReference = "$($applicationGroup.Id)"
    Description               = $workspaceDescription
}
$workspace = New-AvdWorkspace @workspaceParameters
  
Write-Host "##vso[task.setvariable variable=workspaceId;isOutput=true;issecret=false]$($workspace.id)"
Write-Host "##vso[task.setvariable variable=applicationGroupId;isOutput=true;issecret=false]$($applicationGroup.id)"
Write-Host "##vso[task.setvariable variable=hostpoolId;isOutput=true;issecret=false]$($avdHostpool.id)"
Write-Host "##vso[task.setvariable variable=hostpoolName;isOutput=true;issecret=false]$hostpoolName"
Write-Host "##vso[task.setvariable variable=hostpoolResourceGroup;isOutput=true;issecret=false]$ResourceGroupName"