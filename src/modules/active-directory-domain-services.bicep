/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@secure()
param adminPassword string
param adminUsername string
param delimiter string
param deployEntraCloudSync bool
param deploymentNameSuffix string
param dnsForwarder string = '168.63.129.16'
param domainName string
param environmentAbbreviation string
@secure()
param hybridIdentityAdministratorPassword string
param hybridIdentityAdministratorUserPrincipalName string
param hybridUseBenefit bool
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
param tags object = {}
param tier object
param vmCount int = 2
param vmSize string

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

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-adds-cmk-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: tier.namingConvention.diskEncryptionSet
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: mlzTags
    resourceAbbreviations: resourceAbbreviations
    resourceGroupName: resourceGroupName
    tags: tags
    tier: tier
    type: 'virtualMachine'
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
      diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
      dnsForwarder: dnsForwarder
      domainName: domainName
      hybridUseBenefit: hybridUseBenefit
      imageOffer: imageOffer
      imagePublisher: imagePublisher
      imageSku: imageSku
      imageVersion: imageVersion
      index: i
      location: location
      mlzTags: mlzTags
      privateIPAddressOffset: 4 // This is the offset / index for the first available IP address in the subnet. The key vault is using the first available (offset 3) IP address.
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

module entraCloudSync 'entra-cloud-sync.bicep' = if (deployEntraCloudSync) {
  name: 'deploy-entra-cloud-sync-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    location: location
    mlzTags: mlzTags
    name: 'Install-EntraCloudSync'
    tags: tags
    virtualMachineNames: [
      domainControllers[0].outputs.virtualMachineName
      domainControllers[1].outputs.virtualMachineName
    ]
    hybridIdentityAdministratorPassword: hybridIdentityAdministratorPassword
    hybridIdentityAdministratorUserPrincipalName: hybridIdentityAdministratorUserPrincipalName
    subnetResourceId: tier.subnetResourceId
    tier: tier
  }
}

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = [
  customerManagedKeys.outputs.keyVaultNetworkInterfaceResourceId
  domainControllers[0].outputs.networkInterfaceResourceId
  domainControllers[1].outputs.networkInterfaceResourceId
]
