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
param hubNetworkSecurityGroupResourceId string
param hubSubnetResourceId string
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
    name: linuxNetworkInterfaceName
    location: location
    tags: tags
    
    ipConfigurationName: linuxNetworkInterfaceIpConfigurationName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
  }
}

module linuxVirtualMachine '../modules/linux-virtual-machine.bicep' = {
  name: 'remoteAccess-linuxVirtualMachine'
  params: {
    name: linuxVmName
    location: location
    tags: tags

    vmSize: linuxVmSize
    osDiskCreateOption: linuxVmOsDiskCreateOption
    osDiskType: linuxVmOsDiskType
    vmImagePublisher: linuxVmImagePublisher
    vmImageOffer: linuxVmImageOffer
    vmImageSku: linuxVmImageSku
    vmImageVersion: linuxVmImageVersion
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    networkInterfaceName: linuxNetworkInterface.outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module windowsNetworkInterface '../modules/network-interface.bicep' = {
  name: 'remoteAccess-windowsNetworkInterface'
  params: {
    name: windowsNetworkInterfaceName
    location: location
    tags: tags
    
    ipConfigurationName: windowsNetworkInterfaceIpConfigurationName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
  }
}

module windowsVirtualMachine '../modules/windows-virtual-machine.bicep' = {
  name: 'remoteAccess-windowsVirtualMachine'
  params: {
    name: windowsVmName
    location: location
    tags: tags

    size: windowsVmSize
    adminUsername: windowsVmAdminUsername
    adminPassword: windowsVmAdminPassword
    publisher: windowsVmPublisher
    offer: windowsVmOffer
    sku: windowsVmSku
    version: windowsVmVersion
    createOption: windowsVmCreateOption
    storageAccountType: windowsVmStorageAccountType
    networkInterfaceName: windowsNetworkInterface.outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}
