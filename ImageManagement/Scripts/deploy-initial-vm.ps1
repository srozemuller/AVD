param
(
    [Parameter (Mandatory)]
    [string] $VirtualMachineName,
    
    [Parameter (Mandatory)]
    [string] $ImageSKU,

    [Parameter (Mandatory)]
    [string] $ImageOffer,

    [Parameter (Mandatory)]
    [string] $ImagePublisher
)

function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs = ""
    return [String]$characters[$random]
}
function New-RandomString($type) {
    if ($type -eq 'string') {
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

$adminUsername = New-RandomString -type string
$adminPassword = New-RandomString -type password
$vmLocalAdminSecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $vmLocalAdminSecurePassword);
$location = "WestEurope"
$vmSize = "Standard_B2ms"
$computerName = 'initvm'
$resourceGroupName = "rg-$VirtualMachineName"
$diskSizeGB = 128


$subnetParameters = @{
    Name          = "sbn-$($VirtualMachineName)" 
    AddressPrefix = "10.0.0.0/24"
}
$subnet = New-AzVirtualNetworkSubnetConfig @subnetParameters
$vnetParameters = @{
    Name              = "vnet-$($VirtualMachineName)" 
    ResourceGroupName = $resourceGroupName
    Location          = $location
    AddressPrefix     = "10.0.0.0/16" 
    Subnet            = $subnet
}
$vnet = New-AzVirtualNetwork @vnetParameters
$subnetId = (Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet.Name).Id
$nicParameters = @{
    Name              = "nic-$($VirtualMachineName)"
    ResourceGroupName = $resourceGroupName
    Location          = $location
    SubnetId          = $subnetId
}
$nic = New-AzNetworkInterface @nicParameters
Write-Output "##vso[task.setvariable variable=Subnet;isOutput=true]$($subnet.id)"
Write-Output "Subnet is $subnet"


$VirtualMachine = New-AzVMConfig -VMName $VirtualMachineName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $computerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
$VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $diskSizeGB
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version latest

New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $VirtualMachine
Write-Host "##vso[task.setvariable variable=VirtualMachineName;isOutput=true;issecret=false]$VirtualMachineName"