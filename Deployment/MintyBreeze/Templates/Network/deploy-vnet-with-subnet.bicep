param location string = resourceGroup().location
param vnetName string
param vnetAddressPrefix string

param vnetSubnets object

param nsgName string

var subnets = [for item in vnetSubnets.subnets: {
  name: item.name
  properties: {
    addressPrefix: item.addressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}]


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: []
  }
}


resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: subnets
  }
}

output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
