@description('The name of the Hostpool.')
param hostpoolId string

@description('The name of the Application Group to be created.')
param appGroupName string

@description('The friendly name of the Application Group to be created.')
param appGroupFriendlyName string = ''

@description('The description of the Application Group to be created.')
param appGroupDescription string = ''

@description('The type of the Application Group to be created.')
param appGroupType string = 'RemoteApp'

@description('The location where the resources will be deployed.')
param location string

@description('Selected Role Assignments to add in Application Group')
param roleAssignments array = []

@description('Selected Application Group tags')
param applicationGroupTags object = {}

@description('WVD api version')
param apiVersion string = '2019-12-10-preview'

@description('GUID for the deployment')
param deploymentId string = ''

var noRoleAssignments = empty(roleAssignments)
var desktopVirtualizationUserRoleDefinition = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'

resource appGroupName_resource 'Microsoft.DesktopVirtualization/applicationgroups@[parameters(\'apiVersion\')]' = {
  name: appGroupName
  location: location
  tags: applicationGroupTags
  properties: {
    hostpoolarmpath: hostpoolId
    friendlyName: appGroupFriendlyName
    description: appGroupDescription
    applicationGroupType: appGroupType
  }
}

module Asgmt_linkedTemplate_deploymentId './nested_Asgmt_linkedTemplate_deploymentId.bicep' = [for i in range(0, (noRoleAssignments ? 1 : length(roleAssignments))): {
  name: 'Asgmt${i}-linkedTemplate-${deploymentId}'
  params: {
    variables_desktopVirtualizationUserRoleDefinition: desktopVirtualizationUserRoleDefinition
    appGroupName: appGroupName
    roleAssignments: roleAssignments
  }
  dependsOn: [
    appGroupName_resource
  ]
}]