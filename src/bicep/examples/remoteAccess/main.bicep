param location string = resourceGroup().location

param hubVirtualNetworkName string
param hubSubnetResourceId string
param hubNetworkSecurityGroupResourceId string
param logAnalyticsWorkspaceResourceId string

param bastionHostName string = 'bastionHost'
param bastionHostSubnetAddressPrefix string = '10.0.100.160/27'
param bastionHostPublicIPAddressName string = 'bastionHostPublicIPAddress'
param bastionHostPublicIPAddressSkuName string = 'Standard'
param bastionHostPublicIPAddressAllocationMethod string = 'Static'
param bastionHostPublicIPAddressAvailabilityZones array = []
param bastionHostIPConfigurationName string = 'bastionHostIPConfiguration'

param linuxNetworkInterfaceName string = 'linuxVmNetworkInterface'
param linuxNetworkInterfaceIpConfigurationName string = 'linuxVmIpConfiguration'
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

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
@minLength(12)
param linuxVmAdminPasswordOrKey string

param windowsNetworkInterfaceName string = 'windowsVmNetworkInterface'
param windowsNetworkInterfaceIpConfigurationName string = 'windowsVmIpConfiguration'
param windowsNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'
param windowsVmName string = 'windowsVm'
param windowsVmSize string = 'Standard_DS1_v2'
param windowsVmAdminUsername string = 'azureuser'
@secure()
@minLength(12)
param windowsVmAdminPassword string
param windowsVmPublisher string = 'MicrosoftWindowsServer'
param windowsVmOffer string = 'WindowsServer'
param windowsVmSku string = '2019-datacenter-gensecond'
param windowsVmVersion string = 'latest'
param windowsVmCreateOption string = 'FromImage'
param windowsVmStorageAccountType string = 'StandardSSD_LRS'

param nowUtc string = utcNow()

module remoteAccess '../../modules/remoteAccess.bicep' = {
  name: 'deploy-remoteAccess-Example-${nowUtc}'
  params: {
    location: location
    
    hubVirtualNetworkName: hubVirtualNetworkName
    hubSubnetResourceId: hubSubnetResourceId
    hubNetworkSecurityGroupResourceId: hubNetworkSecurityGroupResourceId

    bastionHostName: bastionHostName
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    bastionHostPublicIPAddressName: bastionHostPublicIPAddressName
    bastionHostPublicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    bastionHostPublicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    bastionHostPublicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    bastionHostIPConfigurationName: bastionHostIPConfigurationName

    linuxNetworkInterfaceName: linuxNetworkInterfaceName
    linuxNetworkInterfaceIpConfigurationName: linuxNetworkInterfaceIpConfigurationName
    linuxNetworkInterfacePrivateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod

    linuxVmName: linuxVmName
    linuxVmSize: linuxVmSize
    linuxVmOsDiskCreateOption: linuxVmOsDiskCreateOption
    linuxVmOsDiskType: linuxVmOsDiskType
    linuxVmImagePublisher: linuxVmImagePublisher
    linuxVmImageOffer: linuxVmImageOffer
    linuxVmImageSku: linuxVmImageSku
    linuxVmImageVersion: linuxVmImageVersion
    linuxVmAdminUsername: linuxVmAdminUsername
    linuxVmAuthenticationType: linuxVmAuthenticationType
    linuxVmAdminPasswordOrKey: linuxVmAdminPasswordOrKey

    windowsNetworkInterfaceName: windowsNetworkInterfaceName
    windowsNetworkInterfaceIpConfigurationName: windowsNetworkInterfaceIpConfigurationName
    windowsNetworkInterfacePrivateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod

    windowsVmName: windowsVmName
    windowsVmSize: windowsVmSize
    windowsVmAdminUsername: windowsVmAdminUsername
    windowsVmAdminPassword: windowsVmAdminPassword
    windowsVmPublisher: windowsVmPublisher
    windowsVmOffer: windowsVmOffer
    windowsVmSku: windowsVmSku
    windowsVmVersion: windowsVmVersion
    windowsVmCreateOption: windowsVmCreateOption
    windowsVmStorageAccountType: windowsVmStorageAccountType

    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
}
