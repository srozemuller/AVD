targetScope = 'subscription'

// General Parameters
@description('What is the Azure location to deploy to')
param location string

@description('What is the name of the resource group to deploy to')
param resourceGroupName string

param utc string = utcNow('yyyy.MM.dd')
// Compute Gallery Parameters
@description('What is the Compute Gallery name')
param computeGalleryName string

@description('What is the Compute Gallery image definition name')
param imageDefinitionName string

@description('What is the Compute Gallery image offer')
param imageOffer string

@description('What is the Compute Gallery image SKU')
param imageSKU string

@description('What is the Compute Gallery image publisher')
param imagePublisher string

@description('What is the Compute Gallery image source, resourceId')
param imageSource string

@description('What is the Compute Gallery image HyperVGeneration, V1 or V2')
param hyperVGeneration string

@description('What is the Compute Gallery image OS Type, Windows or Linux')
param osType string

@description('What is the Compute Gallery image OS State, Generalized or Specialized')
param osState string

// AVD Parameters
@description('What is the AVD hostpool name')
param hostpoolName string
@description('What is the AVD hostpool friendly name')
param hostpoolFriendlyName string

@description('What is the AVD max sessions per session host')
param maxSessionLimit int

@description('What is the AVD application group name')
param appGroupName string

@description('What is the AVD application group friendly name')
param appGroupNameFriendlyName string

@description('What is the AVD workspace name')
param workspaceName string
@description('What is the AVD workspace friendly name')
param workspaceNameFriendlyName string
@description('What is the AVD application group type, Desktop or RemoteApp')
param applicationgrouptype string

@description('What is the AVD preferred application group type, Desktop or RemoteApp')
param preferredAppGroupType string

// VNET Parameters
@description('What is the AVD virtual network name')
param vnetName string

@description('What is the AVD virtual network address prefix, i.e. 10.0.0.0/16')
param vnetAddressPrefix string

@description('What is the AVD virtual network subnet name, ie. {name: "DefaultSubnet" addressPrefix: "10.0.0.0/24"}')
param vnetSubnets object

@description('What is the AVD virtual network NSG name')
param nsgName string

// Log Analytics Parameters
@allowed([
  'Free'
  'Standard'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
])
param workspaceSku string

@description('What is the hostpool type, pooled or personal')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string

@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string

param hostpoolLogs object
param appGroupLogs object
param workspaceLogs object

// Session host parameters
param rdshNumberOfInstances int
param rdshInitialNumber int
param rdshVMDiskType string
param rdshVmSize string
param rdshPrefix string

param availabilityZone int
param availabilitySetName string
param availabilityOption string

param aadJoin bool = true
param intune bool = false

// Key Vault Parameters
param keyVaultUserId string

var versionName = utc

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module logAnalyics 'Templates/LogAnalytics/deploy-LogAnalytics.bicep' = {
  name: 'deploy-log-analytics'
  scope: resourceGroup
  params: {
    workspaceName: workspaceName
    workspaceSku: workspaceSku
    location: location
  }
}

module vnets 'Templates/Network/deploy-vnet-with-subnet.bicep' = {
  name: 'deploy-vnet'
  scope: resourceGroup
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    vnetSubnets: vnetSubnets
    nsgName: nsgName
  }
}

module computeGallery 'Templates/ComputeGallery/deploy-shared-image-gallery.bicep' = {
  name: 'deploy-gallery'
  scope: resourceGroup
  params: {
    location: location
    galleryName: computeGalleryName
    imageDefinitionName: imageDefinitionName
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSKU: imageSKU
    versionName: versionName
    imageSource: imageSource
    hyperVGeneration: hyperVGeneration
    osState: osState
    osType: osType
  }
}


module avdEnvironment 'Templates/AVD/deploy-avd-environment.bicep' = {
  name: 'deploy-avd-environment'
  scope: resourceGroup
  dependsOn: [
    logAnalyics
    computeGallery
  ]
  params: {
    hostpoolName: hostpoolName
    hostpoolFriendlyName: hostpoolFriendlyName
    maxSessionLimit: maxSessionLimit
    appGroupName: appGroupName
    appGroupNameFriendlyName: appGroupNameFriendlyName
    workspaceName: workspaceName
    workspaceNameFriendlyName: workspaceNameFriendlyName
    applicationgrouptype: applicationgrouptype
    preferredAppGroupType: preferredAppGroupType
    location: location
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
  }
}

module avdSessionhosts 'Templates/AVD/deploy-avd-sessionhosts.bicep' = {
  name: 'deploy-avd-sessionhosts'
  scope: resourceGroup
  dependsOn: [
    avdEnvironment
    vnets
  ]
  params: {
    hostpoolName: hostpoolName
    location: location
    subnetId: vnets.outputs.subnetId
    hostpoolToken: avdEnvironment.outputs.hostpoolToken
    imageResourceId: computeGallery.outputs.imageVersionId
    aadJoin: aadJoin
    intune: intune
    rdshNumberOfInstances: rdshNumberOfInstances
    rdshInitialNumber: rdshInitialNumber
    rdshVMDiskType: rdshVMDiskType
    rdshVmSize: rdshVmSize
    rdshPrefix: rdshPrefix
    availabilityZone: availabilityZone
    availabilitySetName: availabilitySetName
    availabilityOption: availabilityOption
  }
}


module avdDiagnostics 'Templates/AVD/deploy-avd-diagnostics.bicep' = {
  name: 'deploy-avd-diagnostics'
  scope: resourceGroup
  dependsOn: [
    logAnalyics
    avdEnvironment
  ]
  params: {
    hostpoolName: hostpoolName
    appGroupName: appGroupName
    workspaceName: workspaceName
    workspaceId: logAnalyics.outputs.workspaceId
    hostpoolLogs: hostpoolLogs
    appGroupLogs: appGroupLogs
    workspaceLogs: workspaceLogs
  }
}


module keyVault 'Templates/KeyVault/deploy-keyvault-with-secret.bicep' = {
  name: 'deploy-keyvault'
  scope: resourceGroup
  dependsOn: [
   avdSessionhosts
  ]
  params: {
    location: location
    principalId: keyVaultUserId
    keyVaultName: concat('kv-avd',uniqueString(subscription().id))
    skuName: 'standard'
    secretsObject: {
      secrets: [
        {
          secretName: 'kv-avd-secret'
          secretValue: avdSessionhosts.outputs.localPass
        }
      ]
    }
  }
}
