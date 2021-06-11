//define parameters
param localAdminName string = 'localadmin'

@secure()
param localAdminPassword string = concat('P', uniqueString(resourceGroup().id, ''), 'x', '!')


param vmSize string
param vmOs string
param vmOffer string
param vmName string


param vnetName string
param subnetName string
//define variables
var defaultLocation = resourceGroup().location
var defaultVmNicName = '${vmName}-nic'

var privateIPAllocationMethod = 'Dynamic'

//create nic
resource vmNic 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: defaultVmNicName
  location: defaultLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: privateIPAllocationMethod
        }
      }
    ]
  }
}

//create VM
resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: defaultLocation
  properties: {
    osProfile: {
      computerName: vmName
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
