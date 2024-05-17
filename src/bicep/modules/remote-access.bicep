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
param serviceToken string
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
      vmImageOffer: linuxVmImageOffer
      vmImagePublisher: linuxVmImagePublisher
      vmImageSku: linuxVmImageSku
      vmImageVersion: linuxVmImageVersion
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
      offer: windowsVmOffer
      privateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod
      publisher: windowsVmPublisher
      size: windowsVmSize
      sku: windowsVmSku
      storageAccountType: windowsVmStorageAccountType
      subnetResourceId: hubSubnetResourceId
      tags: tags
      version: windowsVmVersion
    }
  }
