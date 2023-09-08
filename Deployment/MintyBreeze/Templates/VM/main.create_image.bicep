// Define deployment scope
targetScope = 'resourceGroup'

// Define parameters

@description('The name of the resource group that contains the resources to deploy.')
var resourceGroupName  = uniqueString(subscription().id)

@description('The location of the resource group that contains the resources to deploy.')
param location string

@description('The VMs local admin to create.')
param localAdminName string = 'localadmin'

@secure()
param localAdminPassword string = concat('P', uniqueString(subscription().id), 'x', '!')

@description('The VMs size to create')
param vmSize string

@description('The VMs OS sku to create, eg. win11-22h2-avd')
param vmOs string

@description('The VMs OS sku to create, eg. Windows-10')
param vmOffer string

@description('The temporary subnets to create')
param vnetSubnets object

@description('The temporary vnet prefix to create')
param vnetAddressPrefix string


var vnetName = '${uniqueString(resourceGroupName)}-vnet'
var vmName = '${uniqueString(resourceGroupName)}-vm'
var nicName = '${uniqueString(resourceGroupName)}-nic'
var nsgName = '${uniqueString(resourceGroupName)}-nsg'

// Create VNET
module vnets '../../Templates/Network/deploy-vnet-with-subnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    vnetSubnets: vnetSubnets
    nsgName: nsgName
  }
}

// Create NIC
resource vmNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'DefaultSubnet')
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

//create VM
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    osProfile: {
      computerName: '${uniqueString(resourceGroupName)}'
      adminUsername: localAdminName
      adminPassword: localAdminPassword
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: vmOffer
        sku: vmOs
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
      }
    }
    licenseType: 'Windows_Client'
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: vmNic.id
        }
      ]
    }
  }
}

output vmPassword string = localAdminPassword
output vmId string = vm.id
