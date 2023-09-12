//Define diagnostic setting  parameters
param hostpoolName string
param appGroupName string
param workspaceName string
param workspaceId string
param hostpoolLogs object
param appGroupLogs object
param workspaceLogs object

var hpLogs = [for cat in hostpoolLogs.categories: {
  category: cat
  enabled: true
}]

var apLogs = [for cat in appGroupLogs.categories: {
  category: cat
  enabled: true
}]

var wpLogs = [for cat in workspaceLogs.categories: {
  category: cat
  enabled: true
}]


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2020-11-02-preview' existing = {
  name: hostpoolName
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2022-10-14-preview' existing = {
  name: appGroupName
}


resource workspace 'Microsoft.DesktopVirtualization/workspaces@2020-11-02-preview' existing = {
  name: workspaceName
}

resource avdhpdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: hostPool
  name: 'hostpool-diag'
  properties: {
    workspaceId: workspaceId
    logs: hpLogs
  }
}

resource avdappGroupdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appGroup
  name: 'appgroup-diag'
  properties: {
    workspaceId: workspaceId
    logs: apLogs
  }
}

resource avdwsdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: workspace
  name: 'workspacepool-diag'
  properties: {
    workspaceId: workspaceId
    logs: wpLogs
  }
}
