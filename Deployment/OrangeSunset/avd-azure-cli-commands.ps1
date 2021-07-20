$location='westeurope'
$resourceGroupName='RG-ROZ-ORANGESUNSET'
az group create --name $resourceGroupName --location $location

$deployNsg = az network nsg create --name nsg-roz-orangesunset --resource-group $resourceGroupName 
$nsg = $deployNsg | ConvertFrom-Json

$deployVnet = az network vnet create --name vnet-roz-orangesunset --resource-group $resourceGroupName --address-prefixes 10.4.0.0/22 --network-security-group $nsg.NewNSG.name
$vnet = $deployVnet | ConvertFrom-Json
$deployDefaultSubnet = az network vnet subnet create --name DefaultSubnet --address-prefixes 10.4.1.0/24 --resource-group $resourceGroupName --vnet-name $vnet.newVNet.name
$deployAvdSubnet = az network vnet subnet create --name AVD-Orange-Subnet --address-prefixes 10.4.2.0/24 --resource-group $resourceGroupName --vnet-name $vnet.newVNet.name

$deploySig = az sig create --gallery-name Sunset_Gallery --resource-group $resourceGroupName

$gallery = $deploySig | ConvertFrom-Json
$deploySigDefinition = az sig image-definition create --gallery-image-definition Win-Orange-Definition --gallery-name $gallery.name `
--resource-group $resourceGroupName --os-type Windows --hyper-v-generation V2 `
--offer Orange --publisher Sweet --sku Sunset

$initialImage = az vm image list --publisher MicrosoftWindowsDesktop --sku 21h1-evd-g2 --all
$lastImage = ($initialImage | ConvertFrom-Json)[-1]

$subnet = $deployAvdSubnet | ConvertFrom-Json
$deployVm = az vm create --name orange-vm --resource-group $resourceGroupName --image $lastImage.urn `
--size Standard_D2s_v3 --vnet-name $vnet.newVNet.name --subnet $subnet.name --admin-username 'localadmin' --admin-password 'verytS3cr3t!'

$vm = $deployVm | ConvertFrom-Json
az vm run-command invoke  --command-id RunPowerShellScript --name $vm.id.Split("/")[-1] --resource-group $resourceGroupName --scripts 'param([string]$sysprep,[string]$arg) Start-Process -FilePath $sysprep -ArgumentList $arg' --parameters "sysprep=C:\Windows\System32\Sysprep\Sysprep.exe" "arg=/generalize /oobe /shutdown /quiet /mode:vm" 

az vm generalize --name $vm --resource-group $resourceGroupName


$gallery = $deploySig | ConvertFrom-Json
$imageDef = $deploySigDefinition | ConvertFrom-Json
$vm = $deployVm | ConvertFrom-Json

$deployImageVersion = az sig image-version create --resource-group $resourceGroupName --gallery-image-version 2021.1907.01 `
--gallery-image-definition $imageDef.name --gallery-name $gallery.name --managed-image $vm.id
          


$date = (Get-Date).AddHours(4).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK")
$deployAvdHostpool = az desktopvirtualization hostpool create --location $location --resource-group $resourceGroupName  --name Sunset-Hostpool  `
--description "For a nice relaxing sunset" --friendly-name "Orange Sunset Hostpool" --host-pool-type "Pooled" --load-balancer-type "BreadthFirst" `
--max-session-limit 10 --personal-desktop-assignment-type "Automatic" --registration-info expiration-time=$date registration-token-operation="Update" --custom-rdp-property "targetisaadjoined:i:1"


$hostpool = $deployAvdHostpool | ConvertFrom-Json
$deployAvdApplicationGroup = az desktopvirtualization applicationgroup create --location $location --resource-group $resourceGroupName --name "Orange-ApplicationGroup" `
--description "Application group with oranges" --application-group-type "RemoteApp" --friendly-name "The Sweet Orange Sunset group" --host-pool-arm-path $hostpool.id 

$applicationGroup = $deployAvdApplicationGroup | ConvertFrom-Json
$deployAvdWorkspace = az desktopvirtualization workspace create --location $location --resource-group $resourceGroupName --name "Sweet-Workspace" `
--description "A Sweet Workspace" --friendly-name "Sweet Workplace" --application-group-references $applicationGroup.id

$deployLogAnalytics = az monitor log-analytics workspace create --resource-group $resourceGroupName --workspace-name Orange-LA-Workspace

$workspace = $deployLogAnalytics | ConvertFrom-Json
$logs = '[{""category"": ""Checkpoint"", ""categoryGroup"": null, ""enabled"": true, ""retentionPolicy"": {  ""days"": 0, ""enabled"": false }},{""category"": ""Error"",""categoryGroup"": null,""enabled"": true,""retentionPolicy"": {""days"": 0,""enabled"": false}}]'
$deployDiagnostics = az monitor diagnostic-settings create --name avd-diag-settings --resource $hostpool.id --workspace $workspace.id --logs $logs


$deployKeyVault = az keyvault create --location $location --resource-group $resourceGroupName --name SweetOrange-KeyVault

$keyvault = $deployKeyVault | ConvertFrom-Json
$deploySecretPass = az keyvault secret set --name vmjoinerPassword --vault-name  $keyvault.name --value 'JKHQnLWZXWiFupq}r'


$sessionHostCount = 1
$initialNumber = 1
$VMLocalAdminUser = "LocalAdminUser"
$adminpassword = az KeyVault secret show --vault-name $keyvault.name --name vmjoinerPassword --query value
$avdPrefix = "sun-"
$vmSize = "Standard_D2s_v3"
$image = $deployImageVersion | ConvertFrom-Json

# Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"
$domainJoinSettings  = '{""mdmId"": ""0000000a-0000-0000-c000-000000000000""}'

# AVD Azure AD Join domain extension
$moduleLocation = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_6-1-2021.zip"
$avdExtensionName = "DSC"
$avdExtensionPublisher = "Microsoft.Powershell"
$avdExtensionVersion = "2.73"
$avdExtensionSetting = '{""modulesUrl"": ""'+$moduleLocation+'"",""ConfigurationFunction"":""Configuration.ps1\\AddSessionHost"",""Properties"": {""hostPoolName"": ""'+ $($hostpool.name) + '"",""registrationInfoToken"": ""'+ $($hostpool.registrationInfo.token) + '"", ""aadJoin"": "'+ $true + '"}}'

Do {
    $vmName = $avdPrefix+"$initialNumber"
    az vm create --name $vmName --resource-group $resourceGroupName --image $image.id --size $vmSize --vnet-name $vnet.newVNet.name --subnet $subnet.name --admin-username $VMLocalAdminUser --admin-password $adminpassword --public-ip-address '""' --nsg '""'
    az vm identity assign --name $vmName --resource-group $resourceGroupName --identities System
    az vm extension set --vm-name $vmName --resource-group $resourceGroupName --name $domainJoinName --publisher $domainJoinPublisher --version $domainJoinVersion --settings $domainJoinSettings
    az vm extension set --vm-name $vmName --resource-group $resourceGroupName --name $avdExtensionName --publisher $avdExtensionPublisher --version $avdExtensionVersion --settings $avdExtensionSetting

    $initialNumber++
    $sessionHostCount--
    Write-Output "$vmName deployed"
}
while ($sessionHostCount -ne 0) {
    Write-Verbose "Session hosts are created"
}
