param artifactsUri string
param azurePowerShellModuleMsiName string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityResourceId string
param diskEncryptionSetResourceId string
param diskNamePrefix string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param location string
param networkInterfaceNamePrefix string
param organizationalUnitPath string
param securityLogAnalyticsWorkspaceResourceId string
param subnet string
param tagsNetworkInterfaces object
param tagsVirtualMachines object
param timestamp string = utcNow('yyyyMMddhhmmss')
param virtualNetwork string
param virtualNetworkResourceGroup string
param virtualMachineMonitoringAgent string
param virtualMachineNamePrefix string
@secure()
param virtualMachinePassword string
param virtualMachineUsername string

var networkInterfaceName = '${networkInterfaceNamePrefix}mgt'
var securitylogAnalyticsWorkspaceName = securityMonitoring ? split(securityLogAnalyticsWorkspaceResourceId, '/')[8] : ''
var securityLogAnalyticsWorkspaceResourceGroupName = securityMonitoring ? split(securityLogAnalyticsWorkspaceResourceId, '/')[4] : resourceGroup().name
var securityLogAnalyticsWorkspaceSubscriptionId = securityMonitoring ? split(securityLogAnalyticsWorkspaceResourceId, '/')[2] : subscription().subscriptionId
var securityMonitoring = empty(securityLogAnalyticsWorkspaceResourceId) ? false : true
var virtualMachineName = '${virtualMachineNamePrefix}mgt'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (securityMonitoring) {
  scope: resourceGroup(securityLogAnalyticsWorkspaceSubscriptionId, securityLogAnalyticsWorkspaceResourceGroupName)
  name: securitylogAnalyticsWorkspaceName
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName
  location: location
  tags: tagsNetworkInterfaces
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork, subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachineName
  location: location
  tags: tagsVirtualMachines
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-core-g2'
        version: 'latest'
      }
      osDisk: {
        deleteOption: 'Delete'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'None'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: diskSku
        }
        name: '${diskNamePrefix}mgt'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: virtualMachineUsername
      adminPassword: virtualMachinePassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
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
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
      encryptionAtHost: true
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Server'
  }
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${deploymentUserAssignedIdentityResourceId}': {}
    }
  }
}

resource extension_IaasAntimalware 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'IaaSAntimalware'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: 'true'
      ScheduledScanSettings: {
        isEnabled: 'true'
        day: '7' // Day of the week for scheduled scan (1-Sunday, 2-Monday, ..., 7-Saturday)
        time: '120' // When to perform the scheduled scan, measured in minutes from midnight (0-1440). For example: 0 = 12AM, 60 = 1AM, 120 = 2AM.
        scanType: 'Quick' //Indicates whether scheduled scan setting type is set to Quick or Full (default is Quick)
      }
      Exclusions: {}
    }
  }
}

resource extension_GuestAttestation 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
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

resource extension_MicrosoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (securityMonitoring && virtualMachineMonitoringAgent == 'LogAnalyticsAgent') {
  parent: virtualMachine
  name: 'MicrosoftmonitoringAgent'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.monitoring'
    type: 'MicrosoftmonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: securityMonitoring ? logAnalyticsWorkspace.properties.customerId : null
    }
    protectedSettings: {
      workspaceKey: securityMonitoring ? listKeys(securityLogAnalyticsWorkspaceResourceId, '2021-06-01').primarySharedKey : null
    }
  }
  dependsOn: [
    extension_IaasAntimalware
  ]
}

module extension_CustomScriptExtension '../common/customScriptExtensions.bicep' = {
  name: 'CSE_InstallAzurePowerShellAzModule_${timestamp}'
  params: {
    fileUris: [
      '${artifactsUri}${azurePowerShellModuleMsiName}'
      '${artifactsUri}Install-AzurePowerShellAzModule.ps1'
    ]
    location: location
    parameters: '-Installer ${azurePowerShellModuleMsiName}'
    scriptFileName: 'Install-AzurePowerShellAzModule.ps1'
    tags: tagsVirtualMachines
    virtualMachineName: virtualMachine.name
    userAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
  }
  dependsOn: [
    extension_MicrosoftMonitoringAgent
  ]
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: location
  tags: tagsVirtualMachines
  properties: {
    forceUpdateTag: timestamp
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      Options: '3'
      OUPath: organizationalUnitPath
      Restart: 'true'
      User: domainJoinUserPrincipalName
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    extension_CustomScriptExtension
  ]
}

output Name string = virtualMachine.name
