[CmdletBinding()]
param
(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$HostpoolName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$HostpoolResourceGroup,
    
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [int]$SessionHostCount,

    [parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Prefix,

    [parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VmSize,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Publisher,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Offer,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Sku,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$LocalAdmin,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$LocalPass,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubNetId,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DiskType
)
Install-Module -Name Az.Avd -AllowPrerelease -Force -Verbose -Scope CurrentUser
Import-Module -Name Az.Avd

Set-AzContext -Subscription $subscriptionId

$avdHostParameters = @{
    HostpoolName = $HostpoolName 
    HostpoolResourceGroup = $HostpoolResourceGroup 
    ResourceGroupName = $ResourceGroupName
    sessionHostCount = $SessionHostCount 
    Location = $Location 
    Publisher = $Publisher
    Offer = $Offer
    Sku = $Sku
    Prefix = $Prefix
    DiskType = $DiskType
    LocalAdmin = $LocalAdmin
    LocalPass = $LocalPass
    SubNetId = $SubNetId
    VmSize = $VmSize
}

New-AvdAadSessionHost @avdHostParameters