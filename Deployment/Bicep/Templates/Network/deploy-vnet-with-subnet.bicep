param location string = resourceGroup().location
param vnetName string
param addressPrefix string

param vnetSubnets object

var subnets = [for item in vnetSubnets.subnets: {
  name: item.name
  properties: {
    addressPrefix: item.addressPrefix
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: subnets
  }
}
