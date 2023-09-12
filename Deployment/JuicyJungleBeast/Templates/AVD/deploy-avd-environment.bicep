//Define WVD deployment parameters
param hostpoolName string
param hostpoolFriendlyName string
param maxSessionLimit int
param appGroupName string
param appGroupNameFriendlyName string
param workspaceName string
param workspaceNameFriendlyName string
param applicationgrouptype string
param preferredAppGroupType string
param location string

param now string = utcNow('u')
@description('What is the hostpool type, pooled or personal')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string

@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string

// Create AVD Hostpool
resource hp 'Microsoft.DesktopVirtualization/hostPools@2022-10-14-preview' = {
  name: hostpoolName
  location: location
  properties: {
    friendlyName: hostpoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    maxSessionLimit: maxSessionLimit
    registrationInfo: {
      expirationTime: dateTimeAdd(now, 'P1D')
      registrationTokenOperation: 'Update'
    }
  }
}

// Create AVD AppGroup
resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2022-10-14-preview' = {
  name: appGroupName
  location: location
  properties: {
    friendlyName: appGroupNameFriendlyName
    applicationGroupType: applicationgrouptype
    hostPoolArmPath: hp.id
  }
}

// Create AVD Workspace
resource ws 'Microsoft.DesktopVirtualization/workspaces@2022-10-14-preview' = {
  name: workspaceName
  location: location
  properties: {
    friendlyName: workspaceNameFriendlyName
    applicationGroupReferences: [
      ag.id
    ]
  }
}

output hostpoolToken string = reference(hp.id, '2021-01-14-preview').registrationInfo.token
