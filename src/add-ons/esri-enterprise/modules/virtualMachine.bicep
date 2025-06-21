
param architecture string
param availabilitySetName string
param domainJoinOptions int = 3
param enableMonitoring bool
param externalDnsHostName string
param joinWindowsDomain bool
param joinEntraDomain bool
param location string = resourceGroup().location
param networkInterfaceName string
param ouPath string
param serverFunction string
param storageAccountName string
param subnetResourceId string
param tags object
param userAssignedIdentityResourceId string
param virtualMachineName string
@secure()
param virtualMachineAdminPassword string
param virtualMachineSize string
param virtualMachineAdminUsername string
@secure()
param windowsDomainAdministratorPassword string
param windowsDomainAdministratorUserName string
param windowsDomainName string

var roleDefinitionId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader
var windowsDomainNameNetBios = split(windowsDomainName, '.')[0]
var nicDnsSuffix ='${split(externalDnsHostName, '.')[1]}.${split(externalDnsHostName, '.')[2]}'

var availabilitySetId = {
  id: availabilitySet.id
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-09-01' existing = {
  name: availabilitySetName
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: networkInterfaceName
  location: location
  tags: tags[?'Microsoft.Network/networkInterfaces'] ?? {}
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachineName
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: (serverFunction != 'fileshare' && architecture == 'multitier') ? availabilitySetId : null
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'esri'
        offer: 'arcgis-enterprise'
        sku: 'byol-111'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: '${virtualMachineName}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Detach'
        diskSizeGB: 128
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: virtualMachineAdminUsername
      adminPassword: virtualMachineAdminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(virtualMachineName, roleDefinitionId, storageAccountName)
  properties: {
    principalId: virtualMachine.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

resource aadLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (joinEntraDomain && (!joinWindowsDomain)) {
  parent: virtualMachine
  name: 'AADLoginForWindows'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings : null
  }
  dependsOn: [
  ]
}

resource jsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (!empty(windowsDomainAdministratorUserName) && !empty(windowsDomainName) && !empty(ouPath) && (joinWindowsDomain)) {
  parent: virtualMachine
  name: 'joindomain'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: joinWindowsDomain ? windowsDomainName : 'None'
      ouPath: joinWindowsDomain ? ouPath : 'None'
      user: joinWindowsDomain ? '${windowsDomainNameNetBios}\\${windowsDomainAdministratorUserName}' : 'None'
      restart: true
      options: joinWindowsDomain ? domainJoinOptions : 'None'
    }
    protectedSettings: {
      Password: joinWindowsDomain ? windowsDomainAdministratorPassword : 'None'
    }
  }
}

resource guestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'GuestAttestation'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
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

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
}

resource policyExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource networkWatcher 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: virtualMachine
  name: 'Microsoft.Azure.NetworkWatcher'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
  }
}

resource azureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = if (enableMonitoring) {
  parent: virtualMachine
  name: 'AzureMonitorWindowsAgent'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          'identifier-name': enableMonitoring? split(userAssignedIdentityResourceId, '/')[8] : 'None'
          'identifier-value': enableMonitoring ? userAssignedIdentityResourceId : 'None'
         }
      }
    }
  }
}

resource dnsSuffix 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = if (joinEntraDomain && (!joinWindowsDomain)) {
  name: 'rc-esriDnsSuffix'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'Domain'
        value: nicDnsSuffix
      }
    ]
    source: {
      script: loadTextContent('../artifacts/Set-DnsClient.ps1')
    }
  }
  dependsOn: [
    jsonADDomainExtension
    aadLoginForWindows
  ]
}

output virtualMachineName string = virtualMachine.name
output availabilitySetResourceId string = architecture == 'multitier' ? availabilitySet.id : 'null'
output networkInterfaceInternalDomainNameSuffix string = networkInterface.properties.dnsSettings.internalDomainNameSuffix
