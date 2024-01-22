/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param bastionHostIPConfigurationName string
param bastionHostName string
param bastionHostPublicIPAddressAllocationMethod string
param bastionHostPublicIPAddressAvailabilityZones array
param bastionHostPublicIPAddressName string
param bastionHostPublicIPAddressSkuName string 
param bastionHostSubnetResourceId string
param diskEncryptionSetResourceId string
param hubNetworkSecurityGroupResourceId string
param hubSubnetResourceId string
param hybridUseBenefit bool
param linuxDiskName string
param linuxNetworkInterfaceIpConfigurationName string
param linuxNetworkInterfaceName string
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
param linuxVmName string
param linuxVmOsDiskCreateOption string
param linuxVmOsDiskType string
param linuxVmSize string
param location string
param logAnalyticsWorkspaceId string
param tags object
param windowsDiskName string
param windowsNetworkInterfaceIpConfigurationName string
param windowsNetworkInterfaceName string
param windowsNetworkInterfacePrivateIPAddressAllocationMethod string
@secure()
@minLength(12)
param windowsVmAdminPassword string
param windowsVmAdminUsername string
param windowsVmCreateOption string
param windowsVmName string
param windowsVmOffer string
param windowsVmPublisher string
param windowsVmSize string
param windowsVmSku string
param windowsVmStorageAccountType string
param windowsVmVersion string

module bastionHost '../modules/bastion-host.bicep' = {
  name: 'remoteAccess-bastionHost'
  params: {
    bastionHostSubnetResourceId: bastionHostSubnetResourceId
    ipConfigurationName: bastionHostIPConfigurationName
    location: location
    name: bastionHostName
    publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    publicIPAddressName: bastionHostPublicIPAddressName
    publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    tags: tags
  }
}

module linuxNetworkInterface '../modules/network-interface.bicep' = {
  name: 'remoteAccess-linuxNetworkInterface'
  params: {
    ipConfigurationName: linuxNetworkInterfaceIpConfigurationName
    location: location
    name: linuxNetworkInterfaceName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
    tags: tags
  }
}

module linuxVirtualMachine '../modules/linux-virtual-machine.bicep' = {
  name: 'remoteAccess-linuxVirtualMachine'
  params: {
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: linuxDiskName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    name: linuxVmName
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
  params: {
    ipConfigurationName: windowsNetworkInterfaceIpConfigurationName
    location: location
    name: windowsNetworkInterfaceName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
    tags: tags
  }
}

module windowsVirtualMachine '../modules/windows-virtual-machine.bicep' = {
  name: 'remoteAccess-windowsVirtualMachine'
  params: {
    adminPassword: windowsVmAdminPassword
    adminUsername: windowsVmAdminUsername
    createOption: windowsVmCreateOption
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: windowsDiskName
    hybridUseBenefit: hybridUseBenefit
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    name: windowsVmName
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
