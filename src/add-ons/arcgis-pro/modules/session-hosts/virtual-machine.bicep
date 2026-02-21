param activeDirectorySolution string
param avdConfigurationZipFileUri string
param dataCollectionRuleAssociationName string
param dataCollectionRuleResourceId string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param diskNamePrefix string
param fileShare string
param hostPoolResourceId string
param location string
param networkInterfaceNamePrefix string
param networkSecurityGroupResourceId string
param subnetResourceId string
param tagsNetworkInterfaces object
param tagsVirtualMachines object
param virtualMachineNamePrefix string
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string

var amdVmSizes = [
  'Standard_NV4as_v4'
  'Standard_NV8as_v4'
  'Standard_NV16as_v4'
  'Standard_NV32as_v4'
  'Standard_NV4ads_V710_v5'
  'Standard_NV8ads_V710_v5'
  'Standard_NV12ads_V710_v5'
  'Standard_NV24ads_V710_v5'
  'Standard_NV28adms_V710_v5'
]
var intune = contains(activeDirectorySolution, 'IntuneEnrollment')
var nvidiaVmSizes = [
  'Standard_NV6'
  'Standard_NV12'
  'Standard_NV24'
  'Standard_NV12s_v3'
  'Standard_NV24s_v3'
  'Standard_NV48s_v3'
  'Standard_NC4as_T4_v3'
  'Standard_NC8as_T4_v3'
  'Standard_NC16as_T4_v3'
  'Standard_NC64as_T4_v3'
  'Standard_NV6ads_A10_v5'
  'Standard_NV12ads_A10_v5'
  'Standard_NV18ads_A10_v5'
  'Standard_NV36ads_A10_v5'
  'Standard_NV36adms_A10_v5'
  'Standard_NV72ads_A10_v5'
]

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' existing = {
  name: split(hostPoolResourceId, '/')[8]
  scope: resourceGroup(split(hostPoolResourceId, '/')[2], split(hostPoolResourceId, '/')[4])
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${networkInterfaceNamePrefix}-0'
  location: location
  tags: tagsNetworkInterfaces
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
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
    networkSecurityGroup: {
      id: networkSecurityGroupResourceId
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${virtualMachineNamePrefix}-0'
  location: location
  tags: tagsVirtualMachines
  identity: {
    type: 'SystemAssigned' // Required for Entra join
  }
  plan: {
    name: 'pro-byol-36'
    publisher: 'esri'
    product: 'pro-byol'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'esri'
        offer: 'pro-byol'
        sku: 'pro-byol-36'
        version: 'latest'
      }
      osDisk: {
        name: '${diskNamePrefix}-0'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: []
    }
    osProfile: {
      adminPassword: virtualMachineAdminPassword
      adminUsername: virtualMachineAdminUsername
      computerName: '${virtualMachineNamePrefix}-0'
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
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
      securityType: 'trustedLaunch'
      encryptionAtHost: true
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Client'
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

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: virtualMachine
  name: 'AzureMonitorWindowsAgent'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  scope: virtualMachine
  name: dataCollectionRuleAssociationName
  properties: {
    dataCollectionRuleId: dataCollectionRuleResourceId
    description: 'AVD Insights data collection rule association'
  }
  dependsOn: [
    extension_AzureMonitorWindowsAgent
  ]
}

module setSessionHostConfiguration '../../../azure-virtual-desktop/modules/common/run-command.bicep' = {
  name: 'set-config-${deploymentNameSuffix}'
  params: {
    location: location
    name: 'Set-SessionHostConfiguration'
    parameters: [
      {
        name: 'FileShare'
        value: fileShare
      }
    ]
    script: loadTextContent('../../artifacts/Set-SessionHostConfiguration.ps1')
    tags: tagsVirtualMachines
    virtualMachineName: virtualMachine.name
  }
  dependsOn: [
    dataCollectionRuleAssociation
  ]
}

resource installAvdAgents 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'DesiredStateConfiguration'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: avdConfigurationZipFileUri
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: split(hostPoolResourceId, '/')[8]
        registrationInfoTokenCredential: {
          UserName: 'PLACEHOLDER_DO_NOT_USE'
          Password: 'PrivateSettingsRef:RegistrationInfoToken'
        }
        aadJoin: contains(activeDirectorySolution, 'EntraId')
        UseAgentDownloadEndpoint: false
        mdmId: intune ? '0000000a-0000-0000-c000-000000000000' : ''
      }
    }
    protectedSettings: {
      Items: {
        RegistrationInfoToken: hostPool.listRegistrationTokens().value[0].token
      }
    }
  }
  dependsOn: [
    setSessionHostConfiguration
  ]
}

// resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (contains(activeDirectorySolution, 'DomainServices')) {
//   parent: virtualMachine
//   name: 'JsonADDomainExtension'
//   location: location
//   tags: tagsVirtualMachines
//   properties: {
//     forceUpdateTag: timestamp
//     publisher: 'Microsoft.Compute'
//     type: 'JsonADDomainExtension'
//     typeHandlerVersion: '1.3'
//     autoUpgradeMinorVersion: true
//     settings: {
//       Name: domainName
//       Options: '3'
//       OUPath: organizationalUnitPath
//       Restart: 'true'
//       User: domainJoinUserPrincipalName
//     }
//     protectedSettings: {
//       Password: domainJoinPassword
//     }
//   }
//   dependsOn: [
//     setSessionHostConfiguration
//   ]
// }

resource extension_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (contains(
  activeDirectorySolution,
  'EntraId'
)) {
  parent: virtualMachine
  name: 'AADLoginForWindows'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: intune
      ? {
          mdmId: '0000000a-0000-0000-c000-000000000000'
        }
      : null
  }
  dependsOn: [
    setSessionHostConfiguration
  ]
}

resource extension_AmdGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (contains(
  amdVmSizes,
  virtualMachineSize
)) {
  parent: virtualMachine
  name: 'AmdGpuDriverWindows'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'AmdGpuDriverWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    extension_AADLoginForWindows
    //extension_JsonADDomainExtension
  ]
}

resource extension_NvidiaGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (contains(
  nvidiaVmSizes,
  virtualMachineSize
)) {
  parent: virtualMachine
  name: 'NvidiaGpuDriverWindows'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    // NVv3 VM sizes require a specific driver version: https://learn.microsoft.com/azure/virtual-machines/extensions/hpccompute-gpu-windows#known-issues
    settings: startsWith(virtualMachineSize, 'Standard_NV') && (endsWith(virtualMachineSize, 's_v3') || endsWith(
        virtualMachineSize,
        's_A10_v5'
      ))
      ? {
          driverVersion: '538.46'
        }
      : {}
  }
  dependsOn: [
    extension_AADLoginForWindows
    //extension_JsonADDomainExtension
  ]
}
