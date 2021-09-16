param location string
param tags object = {}

param hubVirtualNetworkName string
param hubSubnetResourceId string
param hubNetworkSecurityGroupResourceId string

param bastionHostName string
param bastionHostSubnetAddressPrefix string
param bastionHostPublicIPAddressName string
param bastionHostPublicIPAddressSkuName string 
param bastionHostPublicIPAddressAllocationMethod string
param bastionHostPublicIPAddressAvailabilityZones array
param bastionHostIPConfigurationName string

param linuxVmName string
param linuxVmSize string
param linuxVmOsDiskCreateOption string
param linuxVmOsDiskType string
param linuxVmImagePublisher string
param linuxVmImageOffer string 
param linuxVmImageSku string
param linuxVmImageVersion string
param linuxVmAdminUsername string

@allowed([
  'sshPublicKey'
  'password'
])
param linuxVmAuthenticationType string
@secure()
param linuxVmAdminPasswordOrKey string

param linuxVmNetworkInterfaceName string
param linuxNetworkInterfaceIpConfigurationName string
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: hubVirtualNetworkName
}

module bastionHost './bastionHost.bicep' = {
  name: 'remoteAccess-bastionHost'

  params: {
    name: bastionHostName
    location: location
    tags: tags

    virtualNetworkName: hubVirtualNetwork.name
    subnetAddressPrefix: bastionHostSubnetAddressPrefix
    publicIPAddressName: bastionHostPublicIPAddressName
    publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    ipConfigurationName: bastionHostIPConfigurationName
  }
}

module linuxNetworkInterface './networkInterface.bicep' = {
  name: 'remoteAccess-linuxNetworkInterface'
  params: {
    name: linuxVmNetworkInterfaceName
    location: location
    tags: tags
    
    ipConfigurationName: linuxNetworkInterfaceIpConfigurationName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
  }
}

module linuxVirtualMachine './linuxVirtualMachine.bicep' = {
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
  }
}
