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
param location string
param logAnalyticsWorkspaceId string
param mlzTags object
param name string
param networkInterfaceName string
param networkSecurityGroupResourceId string
param osDiskCreateOption string
param osDiskType string
param privateIPAddressAllocationMethod string
param subnetResourceId string
param supportedClouds array
param tags object
param vmImagePublisher string
param vmImageOffer string
param vmImageSku string
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

module networkInterface '../modules/network-interface.bicep' = {
    name: 'remoteAccess-linuxNetworkInterface'
    params: {
      location: location
      mlzTags: mlzTags
      name: networkInterfaceName
      networkSecurityGroupResourceId: networkSecurityGroupResourceId
      privateIPAddressAllocationMethod: privateIPAddressAllocationMethod
      subnetResourceId: subnetResourceId
      tags: tags
    }
  }

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
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
          id: networkInterface.outputs.id
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
        version: 'latest'
      }
    }
    licenseType: null
  }
}

resource guestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: virtualMachine
  name: 'GuestAttestation'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.Security.LinuxAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
        AscSettings: {
          ascReportingEndpoint: ''
          ascReportingFrequency: ''
        }
        useCustomToken: 'false'
        disableAlerts: 'false'
      }
    }
  }
}

resource policyExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'AzurePolicyforLinux'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource networkWatcher 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'Microsoft.Azure.NetworkWatcher'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
  dependsOn: [
    policyExtension
  ]
}

resource linuxAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (contains(supportedClouds, environment().name)) {
  parent: virtualMachine
  name: 'AzureMonitorLinuxAgent'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.21'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      stopOnMultipleConnections: true
    }
  }
  dependsOn: [
    networkWatcher
  ]
}

resource omsExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if (!contains(supportedClouds, environment().name)) {
  parent: virtualMachine
  name: 'OMSExtension'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.19'
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

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (!contains(supportedClouds, environment().name)) {
  parent: virtualMachine
  name: 'DependencyAgentLinux'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
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
output networkInterfaceResourceId string = networkInterface.outputs.id
