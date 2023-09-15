param location string = resourceGroup().location
param vnetResources object
param nsgResources object

resource networkSecGroups 'Microsoft.Network/networkSecurityGroups@2023-04-01' = [for nsg in nsgResources.nsgs: {
  name: nsg.name
  location: location
  properties: {
    securityRules: []
  }
}]


resource virtualNetworks 'Microsoft.Network/virtualNetworks@2023-04-01' = [for vnet in vnetResources.vnets: {
  name: vnet.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet.addresprefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: vnet.subnets
  }
}]
