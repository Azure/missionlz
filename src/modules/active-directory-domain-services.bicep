/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@secure()
param adminPassword string
param adminUsername string
param deploymentNameSuffix string
param dnsForwarder string = '168.63.129.16'
param domainName string
param environmentAbbreviation string
param hybridUseBenefit bool
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersion string
param keyVaultPrivateDnsZoneResourceId string
param location string = deployment().location
@secure()
param safeModeAdminPassword string
param tags object = {}
param tier object
param vmCount int = 2
param vmSize string

var hubSubscriptionId = subscription().subscriptionId
var identitySubscriptionId = tier.subscriptionId
var resourceGroupName = '${tier.namingConvention.resourceGroup}${tier.delimiter}domainControllers'

module rg 'resource-group.bicep' = {
  name: 'deploy-adds-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    mlzTags: tier.mlzTags
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-adds-cmk-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: tier.namingConvention.diskEncryptionSet
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    tags: tags
    tier: tier
  }
  dependsOn: [
    rg
  ]
}

module diskEncryptionSet 'disk-encryption-set.bicep' = {
  name: 'deploy-adds-des-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: customerManagedKeys.outputs.keyUriWithVersion
    keyVaultResourceId: customerManagedKeys.outputs.keyVaultResourceId
    location: location
    mlzTags: tier.mlzTags
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
    mlzTags: tier.mlzTags
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
      delimiter: tier.delimiter
      deploymentNameSuffix: deploymentNameSuffix
      diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
      dnsForwarder: dnsForwarder
      domainName: domainName
      hybridUseBenefit: hybridUseBenefit
      imageOffer: imageOffer
      imagePublisher: imagePublisher
      imageSku: imageSku
      imageVersion: imageVersion
      index: i
      location: location
      mlzTags: tier.mlzTags
      privateIPAddressOffset: hubSubscriptionId == identitySubscriptionId ? 3 : 4
      safeModeAdminPassword: safeModeAdminPassword
      subnetResourceId: tier.subnetResourceId
      tags: tags
      tier: tier
      vmSize: vmSize
    }
    dependsOn: [
      rg
    ]
  }
]

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = [
  customerManagedKeys.outputs.keyVaultNetworkInterfaceResourceId
  domainControllers[0].outputs.networkInterfaceResourceId
  domainControllers[1].outputs.networkInterfaceResourceId
]
