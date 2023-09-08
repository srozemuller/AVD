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
