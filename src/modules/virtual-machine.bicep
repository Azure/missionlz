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
// List of supported image SKUs for the Dependency Agent based on the documenation:
// - https://learn.microsoft.com/azure/virtual-machines/extensions/agent-dependency-windows
// - https://learn.microsoft.com/azure/virtual-machines/extensions/agent-dependency-linux
var dependencyAgentSupport = [
  '74-gen2' // RedHat 7.4 Gen2
  '75-gen2' // RedHat 7.5 Gen2
  '76-gen2' // RedHat 7.6 Gen2
  '77-gen2' // RedHat 7.7 Gen2
  '78-gen2' // RedHat 7.8 Gen2
  '79-gen2' // RedHat 7.9 Gen2
  '8-gen2' // RedHat 8 Gen2
  '8-lvm-gen2' // RedHat 8 LVM Gen2
  '81-ci-gen2' // RedHat 8.1 Gen2
  '81gen2' // RedHat 8.1 Gen2
  '82-gen2' // RedHat 8.2 Gen2
  '83-gen2' // RedHat 8.3 Gen2
  '84-gen2' // RedHat 8.4 Gen2
  '85-gen2' // RedHat 8.5 Gen2
  '86-gen2' // RedHat 8.6 Gen2
  '16_04-daily-lts-gen2' // Ubuntu 16.04 LTS Gen2
  '16_04-lts-gen2' // Ubuntu 16.04 LTS Gen2
  '16_04_0-lts-gen2' // Ubuntu 16.04 LTS Gen2
  '18_04-daily-lts-gen2' // Ubuntu 18.04 LTS Gen2
  '18_04-lts-gen2' // Ubuntu 18.04 LTS Gen2
  '20_04-lts-gen2' // Ubuntu 20.04 LTS Gen2
  '2016-Datacenter' // Windows Server 2016 Datacenter
  '2016-datacenter-gensecond' // Windows Server 2016 Datacenter Gen2
  '2016-datacenter-gs' // Windows Server 2016 Datacenter Gen2 with Storage Spaces
  '2016-Datacenter-smalldisk' // Windows Server 2016 Datacenter Small Disk
  '2016-datacenter-smalldisk-g2' // Windows Server 2016 Datacenter Small Disk Gen2
  '2016-Datacenter-with-Containers' // Windows Server 2016 Datacenter with Containers
  '2016-datacenter-with-containers-g2' // Windows Server 2016 Datacenter with Containers Gen2
  '2016-Datacenter-zhcn' // Windows Server 2016 Datacenter Chinese
  '2016-datacenter-zhcn-g2' // Windows Server 2016 Datacenter Chinese Gen2
  '2019-Datacenter' // Windows Server 2019 Datacenter
  '2019-datacenter-gensecond' // Windows Server 2019 Datacenter Gen2
  '2019-datacenter-gs' // Windows Server 2019 Datacenter Gen2 with Storage Spaces
  '2019-datacenter-gs-g2' // Windows Server 2019 Datacenter Gen2 with Storage Spaces Gen2
  '2019-Datacenter-smalldisk' // Windows Server 2019 Datacenter Small Disk
  '2019-datacenter-smalldisk-g2' // Windows Server 2019 Datacenter Small Disk Gen2
  '2019-Datacenter-with-Containers' // Windows Server 2019 Datacenter with Containers
  '2019-datacenter-with-containers-g2' // Windows Server 2019 Datacenter with Containers Gen2
  '2019-datacenter-with-containers-gs' // Windows Server 2019 Datacenter with Containers Gen2 with Storage Spaces
  '2019-Datacenter-with-Containers-smalldisk' // Windows Server 2019 Datacenter with Containers Small Disk
  '2019-datacenter-with-containers-smalldisk-g2' // Windows Server 2019 Datacenter with Containers Small Disk Gen2
  '2019-Datacenter-zhcn' // Windows Server 2019 Datacenter Chinese
  '2019-datacenter-zhcn-g2' // Windows Server 2019 Datacenter Chinese Gen2
  '2022-datacenter' // Windows Server 2022 Datacenter
  '2022-datacenter-azure-edition' // Windows Server 2022 Datacenter Azure Edition
  '2022-datacenter-azure-edition-core' // Windows Server 2022 Datacenter Azure Edition Core
  '2022-datacenter-azure-edition-core-smalldisk' // Windows Server 2022 Datacenter Azure Edition Core Small Disk
  '2022-datacenter-azure-edition-hotpatch' // Windows Server 2022 Datacenter Azure Edition Hotpatch
  '2022-datacenter-azure-edition-hotpatch-smalldisk' // Windows Server 2022 Datacenter Azure Edition Hotpatch Small Disk
  '2022-datacenter-azure-edition-smalldisk' // Windows Server 2022 Datacenter Azure Edition Small Disk
  '2022-datacenter-core' // Windows Server 2022 Datacenter Core
  '2022-datacenter-core-g2' // Windows Server 2022 Datacenter Core Gen2
  '2022-datacenter-core-smalldisk' // Windows Server 2022 Datacenter Core Small Disk
  '2022-datacenter-core-smalldisk-g2' // Windows Server 2022 Datacenter Core Small Disk Gen2
  '2022-datacenter-g2' // Windows Server 2022 Datacenter Gen2
  '2022-datacenter-smalldisk' // Windows Server 2022 Datacenter Small Disk
  '2022-datacenter-smalldisk-g2' // Windows Server 2022 Datacenter Small Disk Gen2
]

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
      dataDisks: dataDisks
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

resource extension_DependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = if (contains(dependencyAgentSupport, imageSku)) {
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
output virtualMachineResourceId string = virtualMachine.id
