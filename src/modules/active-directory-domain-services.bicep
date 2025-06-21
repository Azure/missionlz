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
param dnsForwarder string = '168.63.129.16'
param domainName string
param hybridUseBenefit bool
param identity object
param identityResourceGroupName string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersion string
param keyUrl string
param keyVaultResourceId string
param location string = deployment().location
param mlzTags object
@secure()
param safeModeAdminPassword string
param storageAccountType string
param subnetResourceId string
param tags object = {}
param vmCount int = 2
param vmSize string

var resourceGroupName = '${identity.namingConvention.resourceGroup}${delimiter}domainControllers'

module rg 'resource-group.bicep' = {
  name: 'deploy-rg-${identity.name}-${deploymentNameSuffix}'
  params: {
    mlzTags: mlzTags
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module diskEncryptionSet 'disk-encryption-set.bicep' = {
  name: 'deploy-adds-des-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: identity.namingConvention.diskEncryptionSet
    keyUrl: keyUrl
    keyVaultResourceId: keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
    workloadShortName: 'adds'
  }
  dependsOn: [
    rg
  ]
}

module availabilitySet 'availability-set.bicep' = {
  name: 'deploy-adds-availability-set-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    availabilitySetName: identity.namingConvention.availabilitySet
    location: location
    mlzTags: mlzTags
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

module domainControllers 'domain-controller.bicep' = [for i in range(0, vmCount): {
  name: 'deploy-adds-dc-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    availabilitySetResourceId: availabilitySet.outputs.resourceId
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
    dnsForwarder: dnsForwarder
    domainName: domainName
    hybridUseBenefit: hybridUseBenefit
    identity: identity
    identityResourceGroupName: identityResourceGroupName
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    imageVersion: imageVersion
    index: i
    location: location
    mlzTags: mlzTags
    safeModeAdminPassword: safeModeAdminPassword
    storageAccountType: storageAccountType
    subnetResourceId: subnetResourceId
    tags: tags
    vmSize: vmSize
  }
  dependsOn: [
    rg
  ]
}]
