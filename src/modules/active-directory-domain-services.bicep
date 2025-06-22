/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@secure()
param adminPassword string
param adminUsername string
param delimiter string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param dnsForwarder string = '168.63.129.16'
param domainName string
param environmentAbbreviation string
param hybridUseBenefit bool
param identityResourceGroupName string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersion string
param keyVaultPrivateDnsZoneResourceId string
param location string = deployment().location
param mlzTags object
param resourceAbbreviations object
@secure()
param safeModeAdminPassword string
param storageAccountType string
param subnetResourceId string
param tags object = {}
param tier object
param vmCount int = 2
param vmSize string

var hubSubscriptionId = subscription().subscriptionId
var identitySubscriptionId = tier.subscriptionId
var resourceGroupName = '${tier.namingConvention.resourceGroup}${delimiter}domainControllers'

module rg 'resource-group.bicep' = {
  name: 'deploy-adds-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    mlzTags: mlzTags
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module keyVault 'key-vault.bicep' = if (hubSubscriptionId != identitySubscriptionId) {
  name: 'deploy-adds-kv-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    environmentAbbreviation: environmentAbbreviation
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: mlzTags
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: subnetResourceId
    tags: tags
    tier: tier
  }
  dependsOn: [
    rg
  ]
}

module diskEncryptionSet 'disk-encryption-set.bicep' = if (hubSubscriptionId != identitySubscriptionId) {
  name: 'deploy-adds-des-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: keyVault.outputs.disksKeyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

module availabilitySet 'availability-set.bicep' = {
  name: 'deploy-adds-availability-set-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: tier.namingConvention.availabilitySet
    location: location
    mlzTags: mlzTags
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

@batchSize(1)
module domainControllers 'domain-controller.bicep' = [
  for i in range(0, vmCount): {
    name: 'deploy-adds-dc-${i}-${deploymentNameSuffix}'
    scope: resourceGroup(tier.subscriptionId, resourceGroupName)
    params: {
      adminPassword: adminPassword
      adminUsername: adminUsername
      availabilitySetResourceId: availabilitySet.outputs.resourceId
      delimiter: delimiter
      deploymentNameSuffix: deploymentNameSuffix
      diskEncryptionSetResourceId: hubSubscriptionId == identitySubscriptionId
        ? diskEncryptionSetResourceId
        : diskEncryptionSet.outputs.resourceId
      dnsForwarder: dnsForwarder
      domainName: domainName
      hybridUseBenefit: hybridUseBenefit
      identityResourceGroupName: identityResourceGroupName
      imageOffer: imageOffer
      imagePublisher: imagePublisher
      imageSku: imageSku
      imageVersion: imageVersion
      index: i
      location: location
      mlzTags: mlzTags
      privateIPAddressOffset: hubSubscriptionId == identitySubscriptionId ? 3 : 4
      safeModeAdminPassword: safeModeAdminPassword
      storageAccountType: storageAccountType
      subnetResourceId: subnetResourceId
      tags: tags
      tier: tier
      vmSize: vmSize
    }
    dependsOn: [
      rg
    ]
  }
]
