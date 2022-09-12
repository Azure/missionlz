/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@description('Deployment location')
param location string = resourceGroup().location

@description('Key Vault Name')
param keyVaultName string

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param keyVaultSKU string = 'standard'

@description('Key Vault Resource Tags')
param keyVaultTags object = {}

@description('Specifies whether public network access is enabled')
@allowed([
  'disabled'
  'enabled'
])
param publicNetworkAccess string = 'enabled'

@description('Specifies the Network Access Control Lists Default Action.')
@allowed([
  'Deny'
  'Allow'
])
param networkAclsDefaultAction string = 'Allow'

@description('Specifies if the vault is enabled for a VM deployment')
@allowed([
  true
  false
])
param enableVaultForDeployment bool = true

@description('Specifies if the azure platform has access to the vault for enabling disk encryption scenarios.')
@allowed([
  true
  false
])
param enableVaultForDiskEncryption bool = true
@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForTemplateDeployment bool = true

@description('Specifies whether to enable the Soft Delete feature.')
@allowed([
  true
  false
])
param enableSoftDelete bool = true

@description('Specifies whether to enable the Purge Protection feature.')
@allowed([
  true
  false
])
param enablePurgeProtection bool = true

@description('Tenant Id the KeyVault gets configured with')
param tenantId string = subscription().tenantId

@description('Enable RBAC authorization mode')
param enableRbacAuthorization bool = true

@description('Access policies, if not in RBAC mode')
param accessPolicies array = []

@description('Resource Id of the Log Analytics Workspace the diagnostics logs get sent to')
param logAnalyticsWorkspaceResourceId string

@description('Whether or not audit events get shipped to the Log Analytics Workspace')
param logAuditEvent bool = true

@description('Whether or not all VNET metrics get shipped to the Log Analytics Workspace')
param allMetrics bool = false

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  tags: keyVaultTags
  properties: {
    enabledForDeployment: enableVaultForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enableVaultForDiskEncryption
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    tenantId: tenantId
    enableRbacAuthorization: enableRbacAuthorization
    accessPolicies: ((accessPolicies == json('[]')) ? json('null') : accessPolicies)
    sku: {
      name: keyVaultSKU
      family: 'A'
    }
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: networkAclsDefaultAction
      bypass: 'AzureServices'
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: keyVaultName_resource
  name: '${keyVaultName}-diagSettings1'
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: logAuditEvent
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: allMetrics
      }
    ]
  }
}

output keyVaultResourceId string = keyVaultName_resource.id
output keyVaultUri string = keyVaultName_resource.properties.vaultUri
