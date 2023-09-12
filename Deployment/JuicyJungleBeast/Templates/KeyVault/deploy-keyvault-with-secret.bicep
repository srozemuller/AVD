// Also: 
// * KeyVaults secrets CANNOT BE EXPORTED into ARM/Bicep format via the Template Export capability. 
// * documentation on key vault secret resource types: 
//   https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets?tabs=json
// * 201/key-vault-secret=create in pre-decompiled ARM format
//   https://github.com/Azure/azure-quickstart-templates/tree/master/201-key-vault-secret-create

@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = false

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string = ''

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'list'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'list'
  'get'
]

@allowed([
  'standard'
  'premium'
])
@description('Specifies whether the key vault is a standard vault or a premium vault.')
param skuName string


@description('Specifies all secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
param secretsObject object

@description('Specifies the role definition id for the role assignment. Default: Azure Key Vault Secrets User')
param roleDefinitionId string = '4633458b-17de-408a-b874-0445c86b69e6'

@description('Specifies the principal id for the role assignment.')
param principalId string

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: {
    displayName: 'KeyVault'
  }
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableRbacAuthorization: true
    tenantId: tenantId
    accessPolicies: []
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = [for secret in secretsObject.secrets: {
  name: '${vault.name}/${secret.secretName}'
  properties: {
    value: secret.secretValue
  }
}]

@description('the role deffinition is collected')
resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  name: roleDefinitionId
}

resource rbacAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${vault.name}-${roleDefinitionId}-${principalId}')
  scope: vault
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: roleDefinition.id
  }
}
