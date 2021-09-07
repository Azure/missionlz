param location string = resourceGroup().location
param tags object = {
  'resourceIdentifier': resourceIdentifier
}

param hubVirtualNetworkName string
param hubSubnetResourceId string
param hubNetworkSecurityGroupResourceId string

param bastionHostName string = 'bastionHost'
param bastionHostSubnetAddressPrefix string = '10.0.100.160/27'
param bastionHostPublicIPAddressName string = 'bastionHostPublicIPAddress'
param bastionHostPublicIPAddressSkuName string = 'Standard'
param bastionHostPublicIPAddressAllocationMethod string = 'Static'
param bastionHostPublicIPAddressAvailabilityZones array = []
param bastionHostIPConfigurationName string = 'bastionHostIPConfiguration'

param linuxVmName string = 'linuxVirtualMachine'
param linuxVmSize string = 'Standard_B2s'
param linuxVmOsDiskCreateOption string = 'FromImage'
param linuxVmOsDiskType string = 'Standard_LRS'
param linuxVmImagePublisher string = 'Canonical'
param linuxVmImageOffer string = 'UbuntuServer'
param linuxVmImageSku string = '18.04-LTS'
param linuxVmImageVersion string = 'latest'
param linuxVmAdminUsername string = 'azureuser'

@allowed([
  'sshPublicKey'
  'password'
])
param linuxVmAuthenticationType string = 'password'
@secure()
param linuxVmAdminPasswordOrKey string

param linuxVmNetworkInterfaceName string = 'linuxVmNetworkInterface'
param linuxVmNetworkInterfaceIpConfigurationName string = 'linuxVmIpConfiguration'
param linuxVmNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

param resourceIdentifier string = '${bastionHostName}${uniqueString(bastionHostName)}'

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: hubVirtualNetworkName
}

module bastionHost './modules/bastionHost.bicep' = {
  name: 'bastionHost'

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

module linuxVirtualMachine './modules/linuxVirtualMachine.bicep' = {
  name: 'linuxVirtualMachine'
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

    networkInterfaceName: linuxVmNetworkInterfaceName
    networkInterfaceIpConfigurationName: linuxVmNetworkInterfaceIpConfigurationName
    networkInterfaceSubnetId: hubSubnetResourceId
    networkInterfaceNetworkSecurityGroupId: hubNetworkSecurityGroupResourceId
    networkInterfacePrivateIPAddressAllocationMethod: linuxVmNetworkInterfacePrivateIPAddressAllocationMethod
  }
}
