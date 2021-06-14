//Define Log Analytics parameters
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceSku string 


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

output laWorkspaceId string = avdla.id
