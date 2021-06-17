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
param availabilityZone int

@description('Provide the image gallery resourcegroup')
param galleryResourceGroup string = ''

param galleryName string = ''

param galleryImageDefinitionName string = ''
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
param rdshVmSize string = 'Standard_A2'

@description('Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs.')
param enableAcceleratedNetworking bool = false

@description('The username for the domain admin.')
param administratorAccountUsername string

@description('The password that corresponds to the existing domain username.')
@secure()
param administratorAccountPassword string

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
param vmAdministratorAccountUsername string = ''

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
@secure()
param vmAdministratorAccountPassword string = ''

@description('Give the VNET ResourceGroup.')
param vnetResourceGroup string

param vnetName string
param subnetName string

@description('Location for all resources to be created in.')
param location string = resourceGroup().location

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool = false

@description('The resource id of an existing network security group')
param networkSecurityGroupId string = ''

@description('The rules to be given to the new network security group')
param networkSecurityGroupRules array = []

@description('The tags to be assigned to the network interfaces')
param networkInterfaceTags object = {}

@description('The tags to be assigned to the network security groups')
param networkSecurityGroupTags object = {}

@description('VM name prefix initial number.')
param vmInitialNumber int
param guidValue string = newGuid()

@description('The token for adding VMs to the hostpool')
param hostpoolToken string

@description('The name of the hostpool')
param hostpoolName string

@description('OUPath for the domain join')
param ouPath string = ''

@description('Domain to join')
param domain string = ''

@description('IMPORTANT: Please don\'t use this parameter as AAD Join is not supported yet. True if AAD Join, false if AD join')
param aadJoin bool = false

@description('IMPORTANT: Please don\'t use this parameter as intune enrollment is not supported yet. True if intune enrollment is selected.  False otherwise')
param intune bool = false
@description('The tags to be assigned to the virtual machines')
param virtualMachineTags object = {}

var emptyArray = []
var domain_var = ((domain == '') ? last(split(administratorAccountUsername, '@')) : domain)
var storageAccountType = rdshVMDiskType
var newNsgName = '${rdshPrefix}nsg-${guidValue}'
var nsgId = (createNetworkSecurityGroup ? resourceId('Microsoft.Network/networkSecurityGroups', newNsgName) : networkSecurityGroupId)
var isVMAdminAccountCredentialsProvided = ((!(vmAdministratorAccountUsername == '')) && (!(vmAdministratorAccountPassword == '')))
var vmAdministratorUsername = (isVMAdminAccountCredentialsProvided ? vmAdministratorAccountUsername : first(split(administratorAccountUsername, '@')))
var vmAdministratorPassword = (isVMAdminAccountCredentialsProvided ? vmAdministratorAccountPassword : administratorAccountPassword)
var vmAvailabilitySetResourceId = {
  id: resourceId('Microsoft.Compute/availabilitySets/', availabilitySetName)
}
var imageReference = resourceId(galleryResourceGroup,'Microsoft.Compute/galleries/images/versions', '${galleryName}', '${galleryImageDefinitionName}','latest')
var subnetId = resourceId(vnetResourceGroup,'Microsoft.Network/virtualNetworks/subnets','${vnetName}','${subnetName}')

module NSG '../Network/deploy-nsg.bicep' = {
  name: 'NSG-linkedTemplate'
  params: {
    createNetworkSecurityGroup: createNetworkSecurityGroup
    newNsgName: newNsgName
    location: location
    networkSecurityGroupTags: networkSecurityGroupTags
    networkSecurityGroupRules: networkSecurityGroupRules
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2018-11-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}-nic'
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
    networkSecurityGroup: (empty(networkSecurityGroupId) ? json('null') : json('{"id": "${nsgId}"}'))
  }
  dependsOn: [
    NSG
  ]
}]

resource vm 'Microsoft.Compute/virtualMachines@2018-10-01' = [for i in range(0, rdshNumberOfInstances): {
  name: concat('${rdshPrefix}, ${(i + vmInitialNumber)}-')
  location: location
  tags: virtualMachineTags
  identity: {
    type: (aadJoin ? 'SystemAssigned' : 'None')
  }
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: ((availabilityOption == 'AvailabilitySet') ? vmAvailabilitySetResourceId : json('null'))
    osProfile: {
      computerName: concat(rdshPrefix, (i + vmInitialNumber))
      adminUsername: vmAdministratorUsername
      adminPassword: vmAdministratorPassword
    }
    storageProfile: {
      imageReference: {
        id: imageReference
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${rdshPrefix}${(i + vmInitialNumber)}-nic')
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

resource vm_DSC 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/Microsoft.PowerShell.DSC'
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

resource vm_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): if (aadJoin && !intune) {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/AADLoginForWindows'
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

resource vm_AADLoginForWindowsWithIntune 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): if (aadJoin && intune) {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/AADLoginForWindowsWithIntune'
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

resource vm_joindomain 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): if (!aadJoin) {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domain_var
      ouPath: ouPath
      user: administratorAccountUsername
      restart: 'true'
      options: '3'
    }
    protectedSettings: {
      password: administratorAccountPassword
    }
  }
  dependsOn: [
    vm_DSC
  ]
}]
