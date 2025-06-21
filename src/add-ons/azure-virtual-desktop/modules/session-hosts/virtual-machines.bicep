param activeDirectorySolution string
param availability string
param availabilitySetNamePrefix string
param availabilityZones array
param avdConfigurationZipFileName string
param batchCount int
param dataCollectionRuleAssociationName string
param dataCollectionRuleResourceId string
param delimiter string
param deployFslogix bool
param deploymentNameSuffix string
param deploymentUserAssignedidentityClientId string
param diskEncryptionSetResourceId string
param diskNamePrefix string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableAcceleratedNetworking bool
param enableAvdInsights bool
param enableDrainMode bool
param enableWindowsUpdate bool
param fslogixContainerType string
param hostPoolResourceId string
param imageOffer string
param imagePublisher string
param imagePurchasePlan object
param imageSku string
param imageVersionResourceId string
param location string
param managementVirtualMachineName string
param netAppFileShares array
param networkInterfaceNamePrefix string
param networkSecurityGroupResourceId string
param organizationalUnitPath string
param profile string
param resourceGroupManagement string
param sessionHostCount int
param sessionHostIndex int
param storageAccountPrefix string
param storageCount int
param storageIndex int
param storageService string
param storageSuffix string
param subnetResourceId string
param tagsNetworkInterfaces object
param tagsVirtualMachines object
param timestamp string = utcNow('yyyyMMddhhmmss')
param uniqueToken string
param virtualMachineNamePrefix string
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string

var amdVmSize = contains(amdVmSizes, virtualMachineSize)
var amdVmSizes = [
  'Standard_NV4as_v4'
  'Standard_NV8as_v4'
  'Standard_NV16as_v4'
  'Standard_NV32as_v4'
]
var fslogixExclusions = '"%TEMP%\\*\\*.VHDX";"%Windir%\\TEMP\\*\\*.VHDX"${fslogixExclusionsCloudCache}${fslogixExclusionsProfileContainers}${fslogixExclusionsOfficeContainers}'
var fslogixExclusionsCloudCache = contains(fslogixContainerType, 'CloudCache') ? ';"%ProgramData%\\fslogix\\Cache\\*";"%ProgramData%\\fslogix\\Proxy\\*"' : ''
var fslogixExclusionsOfficeContainers = contains(fslogixContainerType, 'Office') ? ';"${fslogixOfficeShare}";"${fslogixOfficeShare}.lock";"${fslogixOfficeShare}.meta";"${fslogixOfficeShare}.metadata"' : ''
var fslogixExclusionsProfileContainers = ';"${fslogixProfileShare}";"${fslogixProfileShare}.lock";"${fslogixProfileShare}.meta";"${fslogixProfileShare}.metadata"'
var fslogixOfficeShare = '\\\\${storageAccountToken}.file.${storageSuffix}\\office-containers\\*\\*.VHDX'
var fslogixProfileShare = '\\\\${storageAccountToken}.file.${storageSuffix}\\profile-containers\\*\\*.VHDX'
var imageReference = empty(imageVersionResourceId) ? {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSku
  version: 'latest'
} : {
  id: imageVersionResourceId
}
var intune = contains(activeDirectorySolution, 'IntuneEnrollment')
var nvidiaVmSize = contains(nvidiaVmSizes, virtualMachineSize)
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
var storageAccountToken = '${storageAccountPrefix}??' // The token is used for AntiVirus exclusions. The '??' represents the two digits at the end of each storage account name.

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' existing = {
  name: split(hostPoolResourceId, '/')[8]
  scope: resourceGroup(split(hostPoolResourceId, '/')[2], split(hostPoolResourceId, '/')[4])
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, sessionHostCount): {
  name: '${networkInterfaceNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
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
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: false
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(0, sessionHostCount): {
  name: '${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
  location: location
  tags: tagsVirtualMachines
  identity: {
    type: 'SystemAssigned' // Required for Entra join
  }
  plan: profile == 'ArcGISPro' ? imagePurchasePlan : null
  zones: availability == 'AvailabilityZones' ? [
    availabilityZones[i % length(availabilityZones)]
  ] : null
  properties: {
    availabilitySet: availability == 'AvailabilitySets' ? {
      id: resourceId('Microsoft.Compute/availabilitySets', '${availabilitySetNamePrefix}${delimiter}${padLeft((i + sessionHostIndex) / 200, 2, '0')}')
    } : null
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${diskNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: diskSku
        }
      }
      dataDisks: []
    }
    osProfile: {
      adminPassword: virtualMachineAdminPassword
      adminUsername: virtualMachineAdminUsername
      computerName: '${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: enableWindowsUpdate && hostPool.properties.hostPoolType == 'Personal' ? true : false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface[i].id
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
    licenseType: ((imagePublisher == 'MicrosoftWindowsDesktop') ? 'Windows_Client' : 'Windows_Server')
  }
  dependsOn: [
    networkInterface
  ]
}]

resource extension_IaasAntimalware 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): {
  parent: virtualMachine[i]
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
      Exclusions: deployFslogix ? {
        Paths: fslogixExclusions
      } : {}
    }
  }
}]

resource extension_GuestAttestation 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): {
  parent: virtualMachine[i]
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
}]

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, sessionHostCount): if (enableAvdInsights) {
  parent: virtualMachine[i]
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
}]

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = [for i in range(0, sessionHostCount): if (enableAvdInsights) {
  scope: virtualMachine[i]
  name: dataCollectionRuleAssociationName
  properties: {
    dataCollectionRuleId: dataCollectionRuleResourceId
    description: 'AVD Insights data collection rule association'
  }
  dependsOn: [
    extension_AzureMonitorWindowsAgent
  ]
}]

module setSessionHostConfiguration '../common/run-command.bicep' = [
  for i in range(0, sessionHostCount): {
    name: 'set-config-${batchCount}-${i}-${deploymentNameSuffix}'
    params: {
      location: location
      name: 'Set-SessionHostConfiguration'
      parameters: [
        {
          name: 'ActiveDirectorySolution'
          value: activeDirectorySolution
        }
        {
          name: 'AmdVmSize'
          value: amdVmSize
        }
        {
          name: 'Fslogix' 
          value: deployFslogix
        }
        {
          name: 'FslogixContainerType'
          value: fslogixContainerType
        }
        {
          name: 'NetAppFileShares'
          value: string(netAppFileShares)
        }
        {
          name: 'NvidiaVmSize'
          value: nvidiaVmSize
        }
        {
          name: 'StorageAccountPrefix'
          value: storageAccountPrefix
        }
        {
          name: 'StorageCount'
          value: storageCount
        }
        {
          name: 'StorageIndex'
          value: storageIndex
        }
        {
          name: 'StorageService'
          value: storageService
        }
        {
          name: 'StorageSuffix'
          value: storageSuffix
        }
        {
          name: 'UniqueToken'
          value: uniqueToken
        }
      ]
      script: loadTextContent('../../artifacts/Set-SessionHostConfiguration.ps1')
      tags: tagsVirtualMachines
      virtualMachineName: virtualMachine[i].name
    }
    dependsOn: [
      dataCollectionRuleAssociation
    ]
  }
]

resource installAvdAgents 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [
  for i in range(0, sessionHostCount): {
    parent: virtualMachine[i]
    name: 'DesiredStateConfiguration'
    location: location
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.73'
      autoUpgradeMinorVersion: true
      settings: {
        modulesUrl: 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/${avdConfigurationZipFileName}'
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
]

// Enables drain mode on the session hosts so users cannot login to the hosts immediately after the deployment
module drainMode '../common/run-command.bicep' = if (enableDrainMode) {
  name: 'deploy-drain-mode-${batchCount}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    location: location
    name: 'Set-AvdDrainMode'
    parameters: [
      {
        name: 'Environment'
        value: environment().name
      }
      { 
        name: 'hostPoolName' 
        value: split(hostPoolResourceId, '/')[8]
      }
      {
        name: 'HostPoolResourceGroupName' 
        value: resourceGroupManagement
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'sessionHostCount' 
        value: sessionHostCount
      }
      {
        name: 'sessionHostIndex' 
        value: sessionHostIndex
      }
      {
        name: 'SubscriptionId' 
        value: subscription().subscriptionId
      }
      {
        name: 'TenantId' 
        value: tenant().tenantId
      }
      {
        name: 'userAssignedidentityClientId' 
        value: deploymentUserAssignedidentityClientId
      }
      {
        name: 'virtualMachineNamePrefix' 
        value: virtualMachineNamePrefix
      }
    ]
    script: loadTextContent('../../artifacts/Set-AvdDrainMode.ps1')
    tags: tagsVirtualMachines
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    installAvdAgents
  ]
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): if (contains(activeDirectorySolution, 'DomainServices')) {
  parent: virtualMachine[i]
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
    drainMode
  ]
}]

resource extension_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): if (contains(activeDirectorySolution, 'EntraId')) {
  parent: virtualMachine[i]
  name: 'AADLoginForWindows'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: intune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : null
  }
  dependsOn: [
    drainMode
  ]
}]

resource extension_AmdGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): if (amdVmSize) {
  parent: virtualMachine[i]
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
    extension_JsonADDomainExtension
  ]
}]

resource extension_NvidiaGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): if (nvidiaVmSize) {
  parent: virtualMachine[i]
  name: 'NvidiaGpuDriverWindows'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    // NVv3 VM sizes require a specific driver version: https://learn.microsoft.com/azure/virtual-machines/extensions/hpccompute-gpu-windows#known-issues
    settings: startsWith(virtualMachineSize, 'Standard_NV') && (endsWith(virtualMachineSize, 's_v3') || endsWith(virtualMachineSize, 's_A10_v5')) ? {
      driverVersion: '538.46'
    } : {}
  }
  dependsOn: [
    extension_AADLoginForWindows
    extension_JsonADDomainExtension
  ]
}]
