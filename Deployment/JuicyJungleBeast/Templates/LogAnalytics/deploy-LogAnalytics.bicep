// Define Log Analytics parameters
param workspaceName string
param workspaceSku string
param location string

// Create Log Analytics Workspace
resource avdla 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: workspaceSku
    }
  }
}


output workspaceId string = avdla.id
