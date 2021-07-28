$resourceGroupName = "RG-ROZ-COCONUTBEACH-COCKTAIL"
$location = "WestEurope"
$parameters = @{
    ResourceGroup = $resourceGroupName
    Location      = $location
}
New-AzResourceGroup @parameters

$nsgParameters = @{
    ResourceGroupName = $resourceGroupName 
    Location          = $location 
    Name              = "nsg-coconut"
}
$networkSecurityGroup = New-AzNetworkSecurityGroup @nsgParameters

$subnetParameters = @{
    defaultSubnet = "10.0.1.0/24"
    avdSubnet     = "10.0.2.0/24"
}

$subnets = $subnetParameters.GetEnumerator().ForEach( {
        New-AzVirtualNetworkSubnetConfig -Name $_.Name -AddressPrefix $_.Value -NetworkSecurityGroup $networkSecurityGroup
    })

$vnetParameters = @{
    name              = "vnet-coconutbeach"
    ResourceGroupName = $resourceGroupName
    Location          = $location
    AddressPrefix     = "10.0.0.0/16" 
    Subnet            = $subnets
    DnsServer         = "10.3.1.4"
}
$virtualNetwork = New-AzVirtualNetwork @vnetParameters 


$galleryParameters = @{
    GalleryName       = "CoconutBeachGallery"
    ResourceGroupName = $resourceGroupName
    Location          = $location
    Description       = "Shared Image Gallery for my beach party"
}

$gallery = New-AzGallery @galleryParameters

$galleryContributor = New-AzAdGroup -DisplayName "Gallery Contributor" -MailNickname "GalleryContributor" -Description "This group had shared image gallery contributor permissions"

$galleryRoleParameters = @{
    ObjectId           = $GalleryContributor.Id
    RoleDefinitionName = "contributor"
    ResourceName       = $gallery.Name
    ResourceType       = "Microsoft.Compute/galleries" 
    ResourceGroupName  = $gallery.ResourceGroupName
}

New-AzRoleAssignment @galleryRoleParameters

$imageDefinitionParameters = @{
    GalleryName       = $gallery.Name
    ResourceGroupName = $gallery.ResourceGroupName
    Location          = $gallery.Location
    Name              = "CoconutDefinition"
    OsState           = "Generalized"
    OsType            = "Windows"
    Publisher         = "Coconut"
    Offer             = "Beach"
    Sku               = "Party"
    HyperVGeneration  = "V2"
}
$imageDefinition = New-AzGalleryImageDefinition @imageDefinitionParameters


$VMLocalAdminUser = "LocalAdminUser"
$VMLocalPassword = "V3rySecretP@ssw0rd"
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalPassword -AsPlainText -Force

$VMName = "vm-coconut"
$VMSize = "Standard_D2s_v3"
$ImageSku = "21h1-evd-g2"
$ImageOffer = "Windows-10"
$ImagePublisher = "MicrosoftWindowsDesktop"
$ComputerName = $VMName
$DiskSizeGB = 512
$nicName = "nic-$vmName"

$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $location -SubnetId ($virtualNetwork.Subnets | Where { $_.Name -eq "avdSubnet" }).Id
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $DiskSizeGB
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSku -Version latest

$initialVM = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

$content = 
@"
    param (
        `$sysprep,
        `$arg
    )
    Start-Process -FilePath `$sysprep -ArgumentList `$arg -Wait
"@

Set-Content -Path .\sysprep.ps1 -Value $content
$vm = Get-AzVM -Name $VMName
$vm | Invoke-AzVMRunCommand -CommandId "RunPowerShellScript" -ScriptPath .\sysprep.ps1 -Parameter @{sysprep = "C:\Windows\System32\Sysprep\Sysprep.exe"; arg = "/generalize /oobe /shutdown /quiet /mode:vm" }

$vm | Set-AzVm -Generalized

$imageVersionParameters = @{
    GalleryImageDefinitionName = $imageDefinition.Name
    GalleryImageVersionName    = (Get-Date -f "yyyy.MM.dd")
    GalleryName                = $gallery.Name
    ResourceGroupName          = $gallery.ResourceGroupName
    Location                   = $gallery.Location
    SourceImageId              = $vm.id.ToString()
}
$imageVersion = New-AzGalleryImageVersion @imageVersionParameters

$JsonParameters = Get-Content .\Parameters\avd-environment.json | ConvertFrom-Json
$hostpoolParameters = @{
    Name                  = "CoconutBeach-Hostpool"
    Description           = "A nice coconut on a sunny beach"
    ResourceGroupName     = $resourceGroupName
    Location              = $location
    HostpoolType          = "Pooled"
    LoadBalancerType      = "BreadthFirst"
    preferredAppGroupType = "Desktop"
    ValidationEnvironment = $true
    StartVMOnConnect      = $true
}

$avdHostpool = New-AzWvdHostPool @hostpoolParameters
$startVmParameters = @{
    HostpoolName      = $avdHostpool.Name
    ResourceGroupName = $hostpoolParameters.resourceGroupName
    HostResourceGroup = $hostpoolParameters.resourceGroupName
}
$startVmOnConnect = Enable-AvdStartVmOnConnect @startVmParameters

$applicationGroupParameters = @{
    ResourceGroupName    = $ResourceGroupName
    Name                 = "CoconutBeachApplications"
    Location             = $location
    FriendlyName         = "Applications on the beach"
    Description          = "From the CoconutBeach-deployment"
    HostPoolArmPath      = $avdHostpool.Id
    ApplicationGroupType = "Desktop"
}
$applicationGroup = New-AzWvdApplicationGroup @applicationGroupParameters

$workSpaceParameters = @{
    ResourceGroupName         = $ResourceGroupName
    Name                      = "Party-Workspace"
    Location                  = $location
    FriendlyName              = "The party workspace"
    ApplicationGroupReference = $applicationGroup.Id
    Description               = "This is the place to party"
}
$workSpace = New-AzWvdWorkspace @workSpaceParameters

$keyVaultParameters = @{
    Name              = "CoconutKeyVault"
    ResourceGroupName = $resourceGroupName
    Location          = $location
}
$keyVault = New-AzKeyVault @keyVaultParameters

$secretParameters = @{
    VaultName   = $keyVault.VaultName
    Name        = "vmjoinerPassword"
    SecretValue = ConvertTo-SecureString -String "V3ryS3cretP4sswOrd!" -AsPlainText -Force
}
$secret = Set-AzKeyVaultSecret @secretParameters

$sessionHostCount = 1
$initialNumber = 0
$VMLocalAdminUser = "LocalAdminUser"
[securestring]$domainPassword = ConvertTo-SecureString (Get-AzKeyVaultSecret -VaultName $keyVault.Vaultname -Name $secret.Name -AsPlainText ) -AsPlainText -Force
$avdPrefix = "avdac-"
$VMSize = "Standard_D2s_v3"
$DiskSizeGB = 512
$domainUser = "vmjoiner@rozemuller.local"
$domain = $domainUser.Split("@")[-1]
$ouPath = "OU=Computers,OU=WVD,DC=rozemuller,DC=local"

$registrationToken = Update-AvdRegistrationToken -HostpoolName $avdHostpool.name $resourceGroupName
$moduleLocation = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"

Do {
    $VMName = $avdPrefix + "$initialNumber"
    $ComputerName = $VMName
    $nicName = "nic-$vmName"
    $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $location -SubnetId ($virtualNetwork.Subnets | Where { $_.Name -eq "avdSubnet" }).Id
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $domainPassword)

    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $DiskSizeGB
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -Id $imageVersion.id

    $sessionHost = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

    $domainJoinSettings = @{
        Name                   = "joindomain"
        Type                   = "JsonADDomainExtension" 
        Publisher              = "Microsoft.Compute"
        typeHandlerVersion     = "1.3"
        SettingString          = '{
            "name": "'+ $($domain) + '",
            "ouPath": "'+ $($ouPath) + '",
            "user": "'+ $($domainUser) + '",
            "restart": "'+ $true + '",
            "options": 3
        }'
        ProtectedSettingString = '{
            "password":"' + $(Get-AzKeyVaultSecret -VaultName $keyVault.Vaultname -Name $secret.Name -AsPlainText) + '"}'
        VMName                 = $VMName
        ResourceGroupName      = $resourceGroupName
        location               = $Location
    }
    Set-AzVMExtension @domainJoinSettings


    $avdDscSettings = @{
        Name               = "Microsoft.PowerShell.DSC"
        Type               = "DSC" 
        Publisher          = "Microsoft.Powershell"
        typeHandlerVersion = "2.73"
        SettingString      = "{
            ""modulesUrl"":'$avdModuleLocation',
            ""ConfigurationFunction"":""Configuration.ps1\\AddSessionHost"",
            ""Properties"": {
                ""hostPoolName"": ""$($fileParameters.avdSettings.avdHostpool.Name)"",
                ""registrationInfoToken"": ""$($registrationToken.token)"",
                ""aadJoin"": true
            }
        }"
        VMName             = $VMName
        ResourceGroupName  = $resourceGroupName
        location           = $Location
    }
    Set-AzVMExtension @avdDscSettings

    $initialNumber++
    $sessionHostCount--
    Write-Output "$VMName deployed"
}
while ($sessionHostCount -ne 0) {
    Write-Verbose "Session hosts are created"
}


$loganalyticsParameters = @{
    Location = $Location 
    Name = "log-analytics-avd-" + (Get-Random -Maximum 99999)
    Sku = "Standard" 
    ResourceGroupName = $resourceGroupName
}


$laws = New-AzOperationalInsightsWorkspace @loganalyticsParameters

$diagnosticsParameters = @{
    Name = "AVD-Diagnostics"
    ResourceId = $avdHostpool.id
    WorkspaceId = $laws.ResourceId
    Enabled = $true
    Category = @("Checkpoint","Error","Management","Connection","HostRegistration")
}

$avdDiagnotics = Set-AzDiagnosticSetting  @diagnosticsParameters

