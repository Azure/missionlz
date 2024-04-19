/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionHostPublicIPAddressAllocationMethod string
param bastionHostPublicIPAddressAvailabilityZones array
param bastionHostPublicIPAddressSkuName string 
param bastionHostSubnetResourceId string
param diskEncryptionSetResourceId string
param hubNetworkSecurityGroupResourceId string
param hubProperties object
param hubSubnetResourceId string
param hybridUseBenefit bool
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string
@secure()
@minLength(12)
param linuxVmAdminPasswordOrKey string
param linuxVmAdminUsername string
@allowed([
  'sshPublicKey'
  'password'
])
param linuxVmAuthenticationType string
param linuxVmImageOffer string 
param linuxVmImagePublisher string
param linuxVmImageSku string
param linuxVmImageVersion string
param linuxVmOsDiskCreateOption string
param linuxVmOsDiskType string
param linuxVmSize string
param location string
param logAnalyticsWorkspaceId string
param mlzTags object
param tags object
param windowsNetworkInterfacePrivateIPAddressAllocationMethod string
@secure()
@minLength(12)
param windowsVmAdminPassword string
param windowsVmAdminUsername string
param windowsVmCreateOption string
param windowsVmOffer string
param windowsVmPublisher string
param windowsVmSize string
param windowsVmSku string
param windowsVmStorageAccountType string
param windowsVmVersion string

module bastionHost '../modules/bastion-host.bicep' = {
  name: 'remoteAccess-bastionHost'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    bastionHostSubnetResourceId: bastionHostSubnetResourceId
    ipConfigurationName: hubProperties.bastionHostIPConfigurationName
    location: location
    mlzTags: mlzTags
    name: hubProperties.bastionHostName
    publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    publicIPAddressName: hubProperties.bastionHostPublicIPAddressName
    publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    tags: tags
  }
}

module linuxNetworkInterface '../modules/network-interface.bicep' = {
  name: 'remoteAccess-linuxNetworkInterface'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    ipConfigurationName: hubProperties.linuxNetworkInterfaceIpConfigurationName
    location: location
    mlzTags: mlzTags
    name: hubProperties.linuxNetworkInterfaceName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
    tags: tags
  }
}

module linuxVirtualMachine '../modules/linux-virtual-machine.bicep' = {
  name: 'remoteAccess-linuxVirtualMachine'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: hubProperties.linuxDiskName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    mlzTags: mlzTags
    name: hubProperties.linuxVmName
    networkInterfaceName: linuxNetworkInterface.outputs.name
    osDiskCreateOption: linuxVmOsDiskCreateOption
    osDiskType: linuxVmOsDiskType
    tags: tags
    vmImageOffer: linuxVmImageOffer
    vmImagePublisher: linuxVmImagePublisher
    vmImageSku: linuxVmImageSku
    vmImageVersion: linuxVmImageVersion
    vmSize: linuxVmSize
  }
}

module windowsNetworkInterface '../modules/network-interface.bicep' = {
  name: 'remoteAccess-windowsNetworkInterface'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    ipConfigurationName: hubProperties.windowsNetworkInterfaceIpConfigurationName
    location: location
    mlzTags: mlzTags
    name: hubProperties.windowsNetworkInterfaceName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
    tags: tags
  }
}

module windowsVirtualMachine '../modules/windows-virtual-machine.bicep' = {
  name: 'remoteAccess-windowsVirtualMachine'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    adminPassword: windowsVmAdminPassword
    adminUsername: windowsVmAdminUsername
    createOption: windowsVmCreateOption
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: hubProperties.windowsDiskName
    hybridUseBenefit: hybridUseBenefit
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    mlzTags: mlzTags
    name: hubProperties.windowsVmName
    networkInterfaceName: windowsNetworkInterface.outputs.name
    offer: windowsVmOffer
    publisher: windowsVmPublisher
    size: windowsVmSize
    sku: windowsVmSku
    storageAccountType: windowsVmStorageAccountType
    tags: tags
    version: windowsVmVersion
  }
}
