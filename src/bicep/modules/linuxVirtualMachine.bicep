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
@minLength(12)
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
param logAnalyticsWorkspaceId string

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

resource networkWatcher 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/Microsoft.Azure.NetworkWatcher'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
  dependsOn: [
    policyExtension
  ]
}

resource policyExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: virtualMachine
  name: 'AzurePolicyforLinux'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource omsExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.13'
    settings: {
      workspaceId: reference(logAnalyticsWorkspaceId , '2015-11-01-preview').customerId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceId , '2015-11-01-preview').primarySharedKey
    }
  }
  dependsOn: [
    networkWatcher
  ]
}

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachine.name}/DependencyAgentLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    omsExtension
  ]
}

output adminUsername string = adminUsername
output authenticationType string = authenticationType
