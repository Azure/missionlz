param name string
param location string
param tags object = {}

param networkInterfaceName string

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
param authenticationType string
@secure()
@minLength(14)
param adminPasswordOrKey string

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
param workspaceId string

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: networkInterfaceName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: name
  location: location
  tags: tags

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
          id: networkInterface.id
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

resource vmName_Microsoft_Azure_NetworkWatcher 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/Microsoft.Azure.NetworkWatcher'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    virtualMachine
  ]
}

resource vmName_OMSExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(workspaceId, '2015-11-01-preview').customerId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(workspaceId, '2015-11-01-preview').primarySharedKey
    }
  }
  dependsOn: [
    virtualMachine
    vmName_Microsoft_Azure_NetworkWatcher
  ]
}

resource vmName_DependencyAgentLinux 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/DependencyAgentLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    virtualMachine
    vmName_OMSExtension
  ]
}

output adminUsername string = adminUsername
output authenticationType string = authenticationType
