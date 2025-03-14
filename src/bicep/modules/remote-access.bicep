/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionHostPublicIPAddressAllocationMethod string
param bastionHostPublicIPAddressAvailabilityZones array
param bastionHostPublicIPAddressSkuName string
param bastionHostSubnetResourceId string
param deployBastion bool
param deployLinuxVirtualMachine bool
param deployWindowsVirtualMachine bool
param diskEncryptionSetResourceId string
param hub object
param hubNetworkSecurityGroupResourceId string
param hubResourceGroupName string
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
param linuxVmImagePublisher string
param linuxVmImageOffer string
param linuxVmImageSku string
param linuxVmSize string
param linuxVmOsDiskCreateOption string
param linuxVmOsDiskType string
param location string
param logAnalyticsWorkspaceId string
param mlzTags object
param serviceToken string
param supportedClouds array
param tags object

@secure()
@minLength(12)
param windowsVmAdminPassword string
param windowsVmAdminUsername string
param windowsVmCreateOption string
param windowsVmImageOffer string
param windowsVmImagePublisher string
param windowsVmImageSku string
param windowsVmNetworkInterfacePrivateIPAddressAllocationMethod string
param windowsVmSize string
param windowsVmStorageAccountType string
param windowsVmVersion string

module bastionHost '../modules/bastion-host.bicep' =
  if (deployBastion) {
    name: 'remoteAccess-bastionHost'
    scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
    params: {
      bastionHostSubnetResourceId: bastionHostSubnetResourceId
      location: location
      mlzTags: mlzTags
      name: hub.namingConvention.bastionHost
      publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
      publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
      publicIPAddressName: hub.namingConvention.bastionHostPublicIPAddress
      publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
      tags: tags
    }
  }

module linuxVirtualMachine '../modules/linux-virtual-machine.bicep' =
  if (deployLinuxVirtualMachine) {
    name: 'remoteAccess-linuxVirtualMachine'
    scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
    params: {
      adminPasswordOrKey: linuxVmAdminPasswordOrKey
      adminUsername: linuxVmAdminUsername
      authenticationType: linuxVmAuthenticationType
      diskEncryptionSetResourceId: diskEncryptionSetResourceId
      diskName: replace(hub.namingConvention.virtualMachineDisk, serviceToken, 'remoteAccess-linux')
      location: location
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      mlzTags: mlzTags
      name: replace(hub.namingConvention.virtualMachine, serviceToken, 'ral')
      networkInterfaceName: replace(hub.namingConvention.virtualMachineNetworkInterface, serviceToken, 'remoteAccess-linux')
      networkSecurityGroupResourceId: hubNetworkSecurityGroupResourceId
      osDiskCreateOption: linuxVmOsDiskCreateOption
      osDiskType: linuxVmOsDiskType
      privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
      subnetResourceId: hubSubnetResourceId
      tags: tags
      supportedClouds: supportedClouds
      vmImagePublisher: linuxVmImagePublisher
      vmImageOffer: linuxVmImageOffer
      vmImageSku: linuxVmImageSku
      vmSize: linuxVmSize
    }
  }

module windowsVirtualMachine '../modules/windows-virtual-machine.bicep' =
  if (deployWindowsVirtualMachine) {
    name: 'remoteAccess-windowsVirtualMachine'
    scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
    params: {
      adminPassword: windowsVmAdminPassword
      adminUsername: windowsVmAdminUsername
      createOption: windowsVmCreateOption
      diskEncryptionSetResourceId: diskEncryptionSetResourceId
      diskName: replace(hub.namingConvention.virtualMachineDisk, serviceToken, 'remoteAccess-windows')
      hybridUseBenefit: hybridUseBenefit
      location: location
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      mlzTags: mlzTags
      name: replace(hub.namingConvention.virtualMachine, serviceToken, 'raw')
      networkInterfaceName: replace(hub.namingConvention.virtualMachineNetworkInterface, serviceToken, 'remoteAccess-windows')
      networkSecurityGroupResourceId: hubNetworkSecurityGroupResourceId
      offer: windowsVmImageOffer
      privateIPAddressAllocationMethod: windowsVmNetworkInterfacePrivateIPAddressAllocationMethod
      publisher: windowsVmImagePublisher
      size: windowsVmSize
      sku: windowsVmImageSku
      storageAccountType: windowsVmStorageAccountType
      subnetResourceId: hubSubnetResourceId
      supportedClouds: supportedClouds
      tags: tags
      version: windowsVmVersion
    }
  }

output networkInterfaceResourceIds array = union(
  deployLinuxVirtualMachine ? [
    linuxVirtualMachine.outputs.networkInterfaceResourceId
  ] : [], 
  deployWindowsVirtualMachine ? [
    windowsVirtualMachine.outputs.networkInterfaceResourceId
  ] : [])
