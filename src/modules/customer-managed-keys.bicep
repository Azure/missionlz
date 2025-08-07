/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param delimiter string
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
@allowed([
  'storageAccount'
  'virtualMachine'
])
param type string

var workload = 'cmk'

module keyVault 'key-vault.bicep' = {
  name: 'deploy-cmk-kv-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    environmentAbbreviation: environmentAbbreviation
    keyName: keyName
    keyVaultName: '${resourceAbbreviations.keyVaults}${uniqueString(tier.subscriptionId, resourceGroupName, tier.namingConvention.keyVault, workload)}'
    keyVaultNetworkInterfaceName: '${tier.namingConvention.keyVaultNetworkInterface}${delimiter}${workload}'
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: '${tier.namingConvention.keyVaultPrivateEndpoint}${delimiter}${workload}'
    location: location
    mlzTags: mlzTags
    subnetResourceId: tier.subnetResourceId
    tags: tags
  }
}

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-cmk-id-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    mlzTags: mlzTags
    tags: tags
    userAssignedIdentityName: '${tier.namingConvention.userAssignedIdentity}${delimiter}${workload}'
  }
}

module diskEncryptionSet 'disk-encryption-set.bicep' = if (type == 'virtualMachine') {
  name: 'deploy-cmk-des-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: '${tier.namingConvention.diskEncryptionSet}${delimiter}${workload}'
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet!.outputs.resourceId
// The following output is needed to setup the diagnostic setting for the key vault
output keyVaultProperties object = {
  diagnosticSettingName: '${tier.namingConvention.keyVaultDiagnosticSetting}${delimiter}${workload}'
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
