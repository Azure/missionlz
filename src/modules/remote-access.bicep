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
param hubNetworkSecurityGroupResourceId string
param hubResourceGroupName string
param hubSubnetResourceId string
param hybridUseBenefit bool
param keyVaultResourceId string
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

module key '../modules/key-vault-key.bicep' = if (deployLinuxVirtualMachine || deployWindowsVirtualMachine) {
  name: 'deploy-ra-key-${deploymentNameSuffix}'
  scope: resourceGroup(split(keyVaultResourceId, '/')[2], split(keyVaultResourceId, '/')[4])
  params: {
    keyName: tier.namingConvention.diskEncryptionSet
    keyVaultName: split(keyVaultResourceId, '/')[8]
  }
}

module diskEncryptionSet '../modules/disk-encryption-set.bicep' = if (deployLinuxVirtualMachine || deployWindowsVirtualMachine) {
  name: 'deploy-ra-disk-encryption-set-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, hubResourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: key.outputs.keyUriWithVersion
    keyVaultResourceId: keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
  }
}

module bastionHost '../modules/bastion-host.bicep' = if (deployBastion) {
  name: 'deploy-ra-bastion-host-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, hubResourceGroupName)
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
  scope: resourceGroup(tier.subscriptionId, hubResourceGroupName)
  params: {
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    // dataCollectionRuleAssociationName: dataCollectionRuleAssociationName
    // dataCollectionRuleResourceId: dataCollectionRuleResourceId
    diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
    diskName: '${tier.namingConvention.virtualMachineDisk}${tier.delimiter}lra' // lra = Linux Remote Access
    imageOffer: linuxVmImageOffer
    imagePublisher: linuxVmImagePublisher
    imageSku: linuxVmImageSku
    imageVersion: linuxVmImageVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: '${tier.namingConvention.virtualMachineNetworkInterface}${tier.delimiter}lra' // lra = Linux Remote Access
    networkSecurityGroupResourceId: hubNetworkSecurityGroupResourceId
    storageAccountType: linuxVmOsDiskType
    subnetResourceId: hubSubnetResourceId
    tags: tags
    virtualMachineName: '${tier.namingConvention.virtualMachine}lra' // lra = Linux Remote Access
    virtualMachineSize: linuxVmSize
  }
}

module windowsVirtualMachine '../modules/virtual-machine.bicep' = if (deployWindowsVirtualMachine) {
  name: 'deploy-ra-windows-vm-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, hubResourceGroupName)
  params: {
    adminPasswordOrKey: windowsVmAdminPassword
    adminUsername: windowsVmAdminUsername
    authenticationType: 'password'
    // dataCollectionRuleAssociationName: dataCollectionRuleAssociationName
    // dataCollectionRuleResourceId: dataCollectionRuleResourceId
    diskEncryptionSetResourceId: diskEncryptionSet.outputs.resourceId
    diskName: '${tier.namingConvention.virtualMachineDisk}${tier.delimiter}wra' // wra = Windows Remote Access
    hybridUseBenefit: hybridUseBenefit
    imageOffer: windowsVmImageOffer
    imagePublisher: windowsVmImagePublisher
    imageSku: windowsVmImageSku
    imageVersion: windowsVmVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: '${tier.namingConvention.virtualMachineNetworkInterface}${tier.delimiter}wra' // wra = Windows Remote Access
    networkSecurityGroupResourceId: hubNetworkSecurityGroupResourceId
    storageAccountType: windowsVmStorageAccountType
    subnetResourceId: hubSubnetResourceId
    tags: tags
    virtualMachineName: '${tier.namingConvention.virtualMachine}wra' // wra = Windows Remote Access
    virtualMachineSize: windowsVmSize
  }
}

output networkInterfaceResourceIds array = union(
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
