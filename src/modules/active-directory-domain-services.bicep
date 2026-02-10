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
param environmentAbbreviation string
param firewallPolicyResourceId string
param hybridUseBenefit bool
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersion string
param ipAddresses array
param keyVaultPrivateDnsZoneResourceId string
param location string = deployment().location
param mlzTags object
param resourceAbbreviations object
@secure()
param safeModeAdminPassword string
param tags object = {}
param tiers array
param tokens object
param vmCount int = 2
param vmSize string

var identityTier = filter(tiers, tier => tier.name == 'identity')[0]

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: replace(identityTier.namingConvention.resourceGroup, tokens.purpose, 'domainControllers')
  location: location
  tags: union(tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-adds-cmk-${deploymentNameSuffix}'
  scope: rg
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(identityTier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: identityTier.subnetResourceId
    tags: tags
    tier: identityTier
    tokens: tokens
    type: 'virtualMachine'
  }
}

resource getFirewallPolicy 'Microsoft.Network/firewallPolicies@2022-05-01' existing = {
  name: split(firewallPolicyResourceId, '/')[8]
  scope: resourceGroup(split(firewallPolicyResourceId, '/')[2], split(firewallPolicyResourceId, '/')[4])
}

module updateFirewallPolicy 'firewall-policy.bicep' = {
  name: 'update-fw-policy-${deploymentNameSuffix}'
  scope: resourceGroup(split(firewallPolicyResourceId, '/')[2], split(firewallPolicyResourceId, '/')[4])
  params: {
    dnsServers: ipAddresses
    enableProxy: getFirewallPolicy.properties.dnsSettings.enableProxy
    intrusionDetectionMode: getFirewallPolicy.properties.intrusionDetection.mode
    location: getFirewallPolicy.location
    name: getFirewallPolicy.name
    skuTier: getFirewallPolicy.properties.sku.tier
    tags: getFirewallPolicy.tags
    threatIntelMode: getFirewallPolicy.properties.threatIntelMode
  }
  dependsOn: [
    customerManagedKeys
  ]
}

module availabilitySet 'availability-set.bicep' = {
  name: 'deploy-adds-availability-set-${deploymentNameSuffix}'
  scope: rg
  params: {
    availabilitySetName: replace(identityTier.namingConvention.availabilitySet, tokens.purpose, 'domainControllers')
    location: location
    mlzTags: mlzTags
    tags: tags
  }
}

@batchSize(1)
module domainControllers 'domain-controller.bicep' = [
  for i in range(0, vmCount): {
    name: 'deploy-adds-dc-${i}-${deploymentNameSuffix}'
    scope: rg
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
      privateIPAddressOffset: 5
      safeModeAdminPassword: safeModeAdminPassword
      subnetResourceId: identityTier.subnetResourceId
      tags: tags
      tier: identityTier
      tokens: tokens
      vmSize: vmSize
    }
    dependsOn: [
      updateFirewallPolicy
    ]
  }
]

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = [
  customerManagedKeys.outputs.keyVaultNetworkInterfaceResourceId
  domainControllers[0].outputs.networkInterfaceResourceId
  domainControllers[1].outputs.networkInterfaceResourceId
]
output virtualMachineResourceIds array = [
  domainControllers[0].outputs.virtualMachineResourceId
  domainControllers[1].outputs.virtualMachineResourceId
]
