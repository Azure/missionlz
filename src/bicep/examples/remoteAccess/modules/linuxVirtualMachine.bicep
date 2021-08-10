param name string
param location string
param tags object = {}

param vmSize string

param osDiskCreateOption string
param osDiskType string

param vmImagePublisher string
param vmImageOffer string
param vmImageSku string
param vmImageVersion string

param adminUsername string
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'
@secure()
param adminPasswordOrKey string

param networkInterfaceName string
param networkInterfaceIpConfigurationName string
param networkInterfaceSubnetId string
param networkInterfaceNetworkSecurityGroupId string
param networkInterfacePrivateIPAddressAllocationMethod string

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

module networkInterface './networkInterface.bicep' = {
  name: 'networkInterface'

  params: {
    name: networkInterfaceName
    location: location
    tags: tags

    ipConfigurationName: networkInterfaceIpConfigurationName
    subnetId: networkInterfaceSubnetId
    networkSecurityGroupId: networkInterfaceNetworkSecurityGroupId
    privateIPAddressAllocationMethod: networkInterfacePrivateIPAddressAllocationMethod
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: osDiskCreateOption
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: vmImageVersion
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.outputs.id
        }
      ]
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
}

output adminUsername string = adminUsername
output authenticationType string = authenticationType
