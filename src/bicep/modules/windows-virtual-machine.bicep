/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@secure()
@minLength(12)
param adminPassword string
param adminUsername string
param createOption string
param dataDisks array = []
param diskEncryptionSetResourceId string
param diskName string
param hybridUseBenefit bool
param location string
param logAnalyticsWorkspaceId  string
param mlzTags object
param name string
param networkInterfaceName string
param networkSecurityGroupResourceId string
param offer string
param privateIPAddressAllocationMethod string
param publisher string
param size string
param sku string
param storageAccountType string
param subnetResourceId string
param supportedClouds array
param tags object
param version string

module networkInterface '../modules/network-interface.bicep' = {
    name: 'remoteAccess-windowsNetworkInterface'
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
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    hardwareProfile: {
      vmSize: size 
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
      computerName: take(name, 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
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
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: version 
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: createOption
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: storageAccountType          
        }
        name: diskName
        osType: 'Windows'
      }
      dataDisks: dataDisks
    }
    licenseType: hybridUseBenefit ? 'Windows_Server' : null
  }
}

resource extension_GuestAttestation 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: virtualMachine
  name: 'GuestAttestation'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
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

resource extension_GuestConfiguration 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'AzurePolicyforWindows'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource extension_NetworkWatcher 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'Microsoft.Azure.NetworkWatcher'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
  }
  dependsOn: [
    extension_GuestConfiguration
  ]
}

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (contains(supportedClouds, environment().name)) {
  parent: virtualMachine
  name: 'AzureMonitorWindowsAgent'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource extension_MicrosoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (!contains(supportedClouds, environment().name)) {
  parent: virtualMachine
  name: 'MMAExtension'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    settings: {
      workspaceId: reference(logAnalyticsWorkspaceId , '2015-11-01-preview').customerId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceId , '2015-11-01-preview').primarySharedKey
    }
  }
  dependsOn: [
    extension_NetworkWatcher
  ]
}

resource extension_DependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (!contains(supportedClouds, environment().name)) {
  parent: virtualMachine
  name: 'DependencyAgentWindows'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_MicrosoftMonitoringAgent
  ]
}

output networkInterfaceResourceId string = networkInterface.outputs.id
