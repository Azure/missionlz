/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param environmentAbbreviation string
param keyName string
param keyVaultPrivateDnsZoneResourceId string
param location string
param mlzTags object
param resourceAbbreviations object
param resourceGroupName string
param tags object
param tier object
param tokens object
@allowed([
  'storageAccount'
  'virtualMachine'
])
param type string

var workload = 'cmk'

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-${workload}-id-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    tags: tags
    userAssignedIdentityName: replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, workload)
  }
}

module keyVault 'key-vault.bicep' = {
  name: 'deploy-${workload}-kv-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    environmentAbbreviation: environmentAbbreviation
    keyName: keyName
    keyVaultName: '${resourceAbbreviations.keyVaults}${uniqueString(tier.subscriptionId, resourceGroupName, replace(tier.namingConvention.keyVault, tokens.purpose, workload))}'
    keyVaultNetworkInterfaceName: replace(tier.namingConvention.keyVaultNetworkInterface, tokens.purpose, workload)
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: replace(tier.namingConvention.keyVaultPrivateEndpoint, tokens.purpose, workload)
    location: location
    mlzTags: mlzTags
    subnetResourceId: tier.subnetResourceId
    tags: tags
  }
  dependsOn: [
    userAssignedIdentity
  ]
}

module diskEncryptionSet 'disk-encryption-set.bicep' = if (type == 'virtualMachine') {
  name: 'deploy-${workload}-des-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, workload)
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
  }
}

output diskEncryptionSetResourceId string = type == 'virtualMachine' ? diskEncryptionSet!.outputs.resourceId : ''
// The following output is needed to setup the diagnostic setting for the key vault
output keyVaultProperties object = {
  diagnosticSettingName: replace(tier.namingConvention.keyVaultDiagnosticSetting, tokens.purpose, workload)
  name: keyVault.outputs.keyVaultName
  resourceGroupName: resourceGroupName
  subscriptionId: tier.subscriptionId
  tierName: tier.name // This value is used to associate the key vault diagnostic setting with the appropriate storage account
}
output keyName string = keyVault.outputs.keyName
output keyUriWithVersion string = keyVault.outputs.keyUriWithVersion
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output keyVaultResourceId string = keyVault.outputs.keyVaultResourceId
output keyVaultNetworkInterfaceResourceId string = keyVault.outputs.networkInterfaceResourceId
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
