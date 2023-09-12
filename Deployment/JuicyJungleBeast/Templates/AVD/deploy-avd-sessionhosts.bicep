@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'


@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
@description('The availability option for the VMs.')
param availabilityOption string = 'None'

@description('The name of avaiability set to be used when create the VMs.')
param availabilitySetName string = ''

@allowed([
  1
  2
  3
])
@description('The number of availability zone to be used when create the VMs.')
param availabilityZone int = 1

@description('This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param rdshPrefix string = take(toLower(resourceGroup().name), 10)

@description('Number of session hosts that will be created and added to the hostpool.')
param rdshNumberOfInstances int

@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
@description('The VM disk type for the VM: HDD or SSD.')
param rdshVMDiskType string

@description('The size of the session host VMs.')
param rdshVmSize string

@description('Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs.')
param enableAcceleratedNetworking bool = false

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
param vmAdministratorAccountUsername string = uniqueString(resourceGroup().id,subscription().subscriptionId)

@description('Location for all resources to be created in.')
param location string = resourceGroup().location


@description('The tags to be assigned to the network interfaces')
param networkInterfaceTags object = {}


@description('VM name prefix initial number.')
param rdshInitialNumber int

@description('The name of the hostpool')
param hostpoolName string


@description('IMPORTANT: Please don\'t use this parameter as AAD Join is not supported yet. True if AAD Join, false if AD join')
param aadJoin string

@description('IMPORTANT: Please don\'t use this parameter as intune enrollment is not supported yet. True if intune enrollment is selected.  False otherwise')
param intune string
@description('The tags to be assigned to the virtual machines')
param virtualMachineTags object = {}

param imageResourceId string

param subnetId string

param hostpoolToken string

var emptyArray = []


var vmAvailabilitySetResourceId = {
  id: resourceId('Microsoft.Compute/availabilitySets/', availabilitySetName)
}

var password = concat('P', uniqueString(subscription().id), 'x', '!')


resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}-nic'
  location: location
  tags: networkInterfaceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}-vm'
  location: location
  tags: virtualMachineTags
  identity: {
    type: (aadJoin == 'true' ? 'SystemAssigned' : 'None')
  }
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: ((availabilityOption == 'AvailabilitySet') ? vmAvailabilitySetResourceId : null)
    osProfile: {
      computerName: '${rdshPrefix}-${(i + rdshInitialNumber)}'
      adminUsername: vmAdministratorAccountUsername
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        id: imageResourceId
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: rdshVMDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${rdshPrefix}${(i + rdshInitialNumber)}-nic')
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Client'
  }
  zones: ((availabilityOption == 'AvailabilityZone') ? array(availabilityZone) : emptyArray)
  dependsOn: [
    nic
  ]
}]

resource vm_DSC 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}-vm/Microsoft.PowerShell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpoolName
        registrationInfoToken: hostpoolToken
        aadJoin: aadJoin
      }
    }
  }
  dependsOn: [
    vm
  ]
}]

resource vm_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, rdshNumberOfInstances): if (aadJoin == 'true' && intune == 'false') {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}-vm/AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vm_DSC
  ]
}]

resource vm_AADLoginForWindowsWithIntune 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, rdshNumberOfInstances): if (aadJoin == 'true' && intune == 'true') {
  name: '${rdshPrefix}${(i + rdshInitialNumber)}-vm/AADLoginForWindowsWithIntune'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    }
  }
  dependsOn: [
    vm_DSC
  ]
}]

output localPass string = password
