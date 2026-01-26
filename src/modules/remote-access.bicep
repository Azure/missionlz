/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionHostPublicIPAddressAllocationMethod string
param bastionHostPublicIPAddressAvailabilityZones array
param bastionHostPublicIPAddressSkuName string
param bastionHostSubnetResourceId string
// param dataCollectionRuleAssociationName string
// param dataCollectionRuleResourceId string
param deployBastion bool
param deployLinuxVirtualMachine bool
param deploymentNameSuffix string
param deployWindowsVirtualMachine bool
param environmentAbbreviation string
param hybridUseBenefit bool
param keyVaultPrivateDnsZoneResourceId string
@secure()
@minLength(12)
param linuxVmAdminPasswordOrKey string
param linuxVmAdminUsername string
@allowed([
  'sshPublicKey'
  'password'
])
param linuxVmAuthenticationType string
param linuxVmImagePublisher string
param linuxVmImageOffer string
param linuxVmImageSku string
param linuxVmImageVersion string
param linuxVmSize string
param linuxVmOsDiskType string
param location string
param mlzTags object
param resourceAbbreviations object
param tags object
param tier object
param tokens object
@secure()
@minLength(12)
param windowsVmAdminPassword string
param windowsVmAdminUsername string
param windowsVmImageOffer string
param windowsVmImagePublisher string
param windowsVmImageSku string
param windowsVmSize string
param windowsVmStorageAccountType string
param windowsVmVersion string

var jbResourceGroupName = replace(tier.namingConvention.resourceGroup, tokens.purpose, 'jumpBoxes')

module rg 'resource-group.bicep' = if (deployLinuxVirtualMachine || deployWindowsVirtualMachine) {
  name: 'deploy-ra-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    mlzTags: mlzTags
    name: jbResourceGroupName
    location: location
    tags: tags
  }
}

module customerManagedKeys 'customer-managed-keys.bicep' = if (deployLinuxVirtualMachine || deployWindowsVirtualMachine) {
  name: 'deploy-ra-cmk-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: mlzTags
    resourceAbbreviations: resourceAbbreviations
    resourceGroupName: jbResourceGroupName
    tags: tags
    tier: tier
    tokens: tokens
    type: 'virtualMachine'
  }
  dependsOn: [
    rg
  ]
}

module linuxVirtualMachine '../modules/virtual-machine.bicep' = if (deployLinuxVirtualMachine) {
  name: 'deploy-ra-linux-vm-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, jbResourceGroupName)
  params: {
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    // dataCollectionRuleAssociationName: dataCollectionRuleAssociationName
    // dataCollectionRuleResourceId: dataCollectionRuleResourceId
    diskEncryptionSetResourceId: customerManagedKeys!.outputs.diskEncryptionSetResourceId
    diskName: replace(tier.namingConvention.virtualMachineDisk, tokens.purpose, 'lra') // lra = Linux Remote Access
    imageOffer: linuxVmImageOffer
    imagePublisher: linuxVmImagePublisher
    imageSku: linuxVmImageSku
    imageVersion: linuxVmImageVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: replace(tier.namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'lra') // lra = Linux Remote Access
    networkSecurityGroupResourceId: tier.networkSecurityGroupResourceId
    storageAccountType: linuxVmOsDiskType
    subnetResourceId: tier.subnetResourceId
    tags: tags
    virtualMachineName: replace(tier.namingConvention.virtualMachine, tokens.purpose, 'lra') // lra = Linux Remote Access
    virtualMachineSize: linuxVmSize
  }
  dependsOn: [
    rg
  ]
}

module windowsVirtualMachine '../modules/virtual-machine.bicep' = if (deployWindowsVirtualMachine) {
  name: 'deploy-ra-windows-vm-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, jbResourceGroupName)
  params: {
    adminPasswordOrKey: windowsVmAdminPassword
    adminUsername: windowsVmAdminUsername
    authenticationType: 'password'
    // dataCollectionRuleAssociationName: dataCollectionRuleAssociationName
    // dataCollectionRuleResourceId: dataCollectionRuleResourceId
    diskEncryptionSetResourceId: customerManagedKeys!.outputs.diskEncryptionSetResourceId
    diskName: replace(tier.namingConvention.virtualMachineDisk, tokens.purpose, 'wra') // wra = Windows Remote Access
    hybridUseBenefit: hybridUseBenefit
    imageOffer: windowsVmImageOffer
    imagePublisher: windowsVmImagePublisher
    imageSku: windowsVmImageSku
    imageVersion: windowsVmVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: replace(tier.namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'wra') // wra = Windows Remote Access
    networkSecurityGroupResourceId: tier.networkSecurityGroupResourceId
    storageAccountType: windowsVmStorageAccountType
    subnetResourceId: tier.subnetResourceId
    tags: tags
    virtualMachineName: replace(tier.namingConvention.virtualMachine, tokens.purpose, 'wra') // wra = Windows Remote Access
    virtualMachineSize: windowsVmSize
  }
  dependsOn: [
    rg
  ]
}

module bastionHost '../modules/bastion-host.bicep' = if (deployBastion) {
  name: 'deploy-ra-bastion-host-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    bastionHostSubnetResourceId: bastionHostSubnetResourceId
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.bastionHost, tokens.purpose, '')
    publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    publicIPAddressName: replace(tier.namingConvention.bastionHostPublicIPAddress, tokens.purpose, '')
    publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    tags: tags
  }
}

output keyVaultProperties object = deployLinuxVirtualMachine || deployWindowsVirtualMachine ? customerManagedKeys!.outputs.keyVaultProperties : {}
output networkInterfaceResourceIds array = union(
  deployLinuxVirtualMachine || deployWindowsVirtualMachine 
    ? [
        customerManagedKeys!.outputs.keyVaultNetworkInterfaceResourceId
      ] 
    : [],
  deployLinuxVirtualMachine
    ? [
        linuxVirtualMachine!.outputs.networkInterfaceResourceId
      ]
    : [],
  deployWindowsVirtualMachine
    ? [
        windowsVirtualMachine!.outputs.networkInterfaceResourceId
      ]
    : []
)
