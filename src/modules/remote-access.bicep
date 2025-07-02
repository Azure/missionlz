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
param delimiter string
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

var jbResourceGroupName = '${tier.namingConvention.resourceGroup}${delimiter}jumpBoxes'

module rg 'resource-group.bicep' = {
  name: 'deploy-ra-rg-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    mlzTags: mlzTags
    name: jbResourceGroupName
    location: location
    tags: tags
  }
}

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-ra-cmk-${deploymentNameSuffix}'
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
    tags: tags
    tier: tier
    workload: 'jumpBoxes'
  }
  dependsOn: [
    rg
  ]
}

module diskEncryptionSet '../modules/disk-encryption-set.bicep' = if (deployLinuxVirtualMachine || deployWindowsVirtualMachine) {
  name: 'deploy-ra-disk-encryption-set-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, jbResourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: customerManagedKeys.outputs.keyUriWithVersion
    keyVaultResourceId: customerManagedKeys.outputs.keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
  }
}

module bastionHost '../modules/bastion-host.bicep' = if (deployBastion) {
  name: 'deploy-ra-bastion-host-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    bastionHostSubnetResourceId: bastionHostSubnetResourceId
    location: location
    mlzTags: mlzTags
    name: tier.namingConvention.bastionHost
    publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    publicIPAddressName: tier.namingConvention.bastionHostPublicIPAddress
    publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    tags: tags
  }
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
    diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
    diskName: '${tier.namingConvention.virtualMachineDisk}${delimiter}lra' // lra = Linux Remote Access
    imageOffer: linuxVmImageOffer
    imagePublisher: linuxVmImagePublisher
    imageSku: linuxVmImageSku
    imageVersion: linuxVmImageVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: '${tier.namingConvention.virtualMachineNetworkInterface}${delimiter}lra' // lra = Linux Remote Access
    networkSecurityGroupResourceId: tier.networkSecurityGroupResourceId
    storageAccountType: linuxVmOsDiskType
    subnetResourceId: tier.subnetResourceId
    tags: tags
    virtualMachineName: '${tier.namingConvention.virtualMachine}lra' // lra = Linux Remote Access
    virtualMachineSize: linuxVmSize
  }
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
    diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
    diskName: '${tier.namingConvention.virtualMachineDisk}${delimiter}wra' // wra = Windows Remote Access
    hybridUseBenefit: hybridUseBenefit
    imageOffer: windowsVmImageOffer
    imagePublisher: windowsVmImagePublisher
    imageSku: windowsVmImageSku
    imageVersion: windowsVmVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: '${tier.namingConvention.virtualMachineNetworkInterface}${delimiter}wra' // wra = Windows Remote Access
    networkSecurityGroupResourceId: tier.networkSecurityGroupResourceId
    storageAccountType: windowsVmStorageAccountType
    subnetResourceId: tier.subnetResourceId
    tags: tags
    virtualMachineName: '${tier.namingConvention.virtualMachine}wra' // wra = Windows Remote Access
    virtualMachineSize: windowsVmSize
  }
}

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = union([
    customerManagedKeys.outputs.keyVaultNetworkInterfaceResourceId
  ],
  deployLinuxVirtualMachine
    ? [
        linuxVirtualMachine.outputs.networkInterfaceResourceId
      ]
    : [],
  deployWindowsVirtualMachine
    ? [
        windowsVirtualMachine.outputs.networkInterfaceResourceId
      ]
    : []
)
