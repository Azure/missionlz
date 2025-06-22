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
param availabilitySetResourceId string = ''
// param dataCollectionRuleAssociationName string
// param dataCollectionRuleResourceId string
param dataDisks array = []
param diskCaching string = 'ReadWrite'
param diskEncryptionSetResourceId string
param diskName string
param domainJoin bool = false
param domainName string = ''
param hybridUseBenefit bool = false
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersion string
param location string
param mlzTags object
param networkInterfaceName string
param networkSecurityGroupResourceId string
param privateIPAddress string = ''
param storageAccountType string
param subnetResourceId string
param tags object
param timestamp string = utcNow('yyyyMMddhhmmss')
param virtualMachineName string
param virtualMachineSize string

var osType = contains(imagePublisher, 'Windows') ? 'Windows' : 'Linux'

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

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: networkInterfaceName
  location: location
  tags: union(tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAddress: empty(privateIPAddress) ? null : privateIPAddress
          privateIPAllocationMethod: empty(privateIPAddress) ? 'Dynamic' : 'Static'
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupResourceId
    }
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: virtualMachineName
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    availabilitySet: empty(availabilitySetResourceId) ? null : {
      id: availabilitySetResourceId
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize 
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
      computerName: take(virtualMachineName, 15)
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
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion 
      }
      osDisk: {
        caching: diskCaching
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: storageAccountType          
        }
        name: diskName
        osType: osType
      }
      dataDisks: dataDisks
    }
    licenseType: hybridUseBenefit ? 'Windows_Server' : null
  }
}

resource extension_GuestAttestation 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
  name: 'GuestAttestation'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.Security.${osType}Attestation'
    settings: {
      AttestationConfig: {
        AscSettings: {
          ascReportingEndpoint: ''
          ascReportingFrequency: ''
        }
        disableAlerts: 'false'
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
        useCustomToken: 'false'
      }
    }
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
  }
}

resource extension_GuestConfiguration 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
  name: 'Configurationfor${osType}'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.GuestConfiguration'
    type: 'Configurationfor${osType}'
    typeHandlerVersion: '1.0'
  }
}

resource extension_NetworkWatcher 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
  name: 'NetworkWatcherAgent${osType}'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgent${osType}'
    typeHandlerVersion: '1.4'
  }
  dependsOn: [
    extension_GuestConfiguration
  ]
}

resource extension_AzureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
  name: 'AzureMonitor${osType}Agent'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.Monitor'
    settings: osType == 'Windows' ? {} : {
      stopOnMultipleConnections: true
    }
    type: 'AzureMonitor${osType}Agent'
    typeHandlerVersion: '1.0'
  }
  dependsOn: [
    extension_NetworkWatcher
  ]
}

/* resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  scope: virtualMachine
  name: dataCollectionRuleAssociationName
  properties: {
    dataCollectionRuleId: dataCollectionRuleResourceId
    description: 'AVD Insights data collection rule association'
  }
  dependsOn: [
    extension_AzureMonitorAgent
  ]
} */

resource extension_DependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
  name: 'DependencyAgent${osType}'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgent${osType}'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (domainJoin) {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    forceUpdateTag: timestamp
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      Options: '3'
      Restart: 'true'
      User: '${adminUsername}@${domainName}'
    }
    protectedSettings: {
      Password: adminPasswordOrKey
    }
  }
  dependsOn: [
    extension_AzureMonitorAgent
    extension_DependencyAgent
    extension_GuestAttestation
    extension_GuestConfiguration
    extension_NetworkWatcher
  ]
}

output networkInterfaceResourceId string = networkInterface.id
output virtualMachineName string = virtualMachine.name
