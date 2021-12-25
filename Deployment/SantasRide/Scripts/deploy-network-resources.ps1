[CmdletBinding()]
param (
    [Parameter()]
    [string]$subscriptionId,

    [Parameter()]
    [string]$resourceGroup,

    [Parameter()]
    [string]$location,

    [Parameter()]
    [string]$nsgName,

    [Parameter()]
    [string]$subnetName,

    [Parameter()]
    [string]$subnetPrefix,

    [Parameter()]
    [string]$vnetName,

    [Parameter()]
    [string]$vnetPrefix

)

Set-AzContext -Subscription $subscriptionId

$nsgParameters = @{
    ResourceGroupName = $resourceGroup 
    Location = $location 
    Name =  $nsgName
}
$networkSecurityGroup = New-AzNetworkSecurityGroup @nsgParameters


$subnetParameters = @{
    Name = $subnetName 
    AddressPrefix = $subnetPrefix 
    NetworkSecurityGroup = $networkSecurityGroup
}
$subnet = New-AzVirtualNetworkSubnetConfig @subnetParameters

$vnetParameters = @{
    name = $vnetName 
    ResourceGroupName = $resourceGroup 
    Location = $location 
    AddressPrefix = $vnetPrefix 
    Subnet = $subnet
}
$virtualNetwork = New-AzVirtualNetwork @vnetParameters
$subnetId = $virtualNetwork.Subnets | Where-Object {$_.Name -eq $subnetName} | Select-Object Id

Write-Host "##vso[task.setvariable variable=nsgId;isOutput=true;]$($networkSecurityGroup.id)"
Write-Host "##vso[task.setvariable variable=subnetId;isOutput=true;]$($subnetId.id)"
Write-Host "##vso[task.setvariable variable=vnetId;isOutput=true;]$($virtualNetwork.id)"