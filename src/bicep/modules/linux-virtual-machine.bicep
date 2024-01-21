/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@secure()
@minLength(12)
param adminPasswordOrKey string
param adminUsername string
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string
param diskEncryptionSetResourceId string
param diskName string
param hybridUseBenefit bool
param location string
param name string
param networkInterfaceName string
param osDiskCreateOption string
param osDiskType string
param tags object
param vmImageOffer string
param vmImagePublisher string
param vmImageSku string
param vmImageVersion string
param vmSize string

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

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'trustedLaunch'
      encryptionAtHost: true
    }
    storageProfile: {
      osDisk: {
        caching: 'ReadWrite'
        createOption: osDiskCreateOption
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: osDiskType
        }
        name: diskName
        osType: 'Linux'
      }
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: vmImageVersion
      }
    }
    licenseType: hybridUseBenefit ? 'Windows_Server' : null
  }
}

resource networkWatcher 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'Microsoft.Azure.NetworkWatcher'
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

resource policyExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
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

resource omsExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'OMSExtension'
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

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'DependencyAgentLinux'
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
