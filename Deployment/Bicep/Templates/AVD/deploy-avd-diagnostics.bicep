//Define diagnostic setting  parameters
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceSku string 
param hostpoolName string
param workspaceName string
param hostpoolLogs object
param workspaceLogs object

var hpLogs = [for cat in hostpoolLogs.categories: {
  category: cat
  enabled: true
}]

var wpLogs = [for cat in workspaceLogs.categories: {
  category: cat
  enabled: true
}]
//Create Log Analytics Workspace
resource avdla 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: resourceGroup().location
  properties: {
    sku: {
      name: logAnalyticsWorkspaceSku
    }
  }
}


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2020-11-02-preview' existing = {
  name: hostpoolName
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2020-11-02-preview' existing = {
  name: workspaceName
}


resource avdhpdiag 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'hostpool-diag'
  properties: {
    workspaceId:  avdla.id
    logs: hpLogs
  }
}

resource avdwsdiag 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'workspacepool-diag'
  properties: {
    workspaceId: avdla.id
    logs: wpLogs
  }
}
