param artifactsUri string
param artifactsUserAssignedIdentityClientId string
param artifactsUserAssignedIdentityResourceId string
param acceleratedNetworking string
param activeDirectorySolution string
param availability string
param availabilitySetNamePrefix string
param availabilityZones array
param avdAgentBootLoaderMsiName string
param avdAgentMsiName string
param batchCount int
param dataCollectionRuleAssociationName string
param dataCollectionRuleResourceId string
param deploymentUserAssignedidentityClientId string
param diskEncryptionSetResourceId string
param diskNamePrefix string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableDrainMode bool
param fslogix bool
param fslogixContainerType string
param hostPoolName string
param hostPoolType string
param imageDefinitionResourceId string
param imageOffer string
param imagePublisher string
param imageSku string
param location string
param logAnalyticsWorkspaceName string
param managementVirtualMachineName string
param monitoring bool
param netAppFileShares array
param networkInterfaceNamePrefix string
param organizationalUnitPath string
param resourceGroupControlPlane string
param resourceGroupManagement string
param securityLogAnalyticsWorkspaceResourceId string
param sessionHostCount int
param sessionHostIndex int
param storageAccountPrefix string
param storageCount int
param storageIndex int
param storageService string
param storageSuffix string
param subnet string
param tagsNetworkInterfaces object
param tagsVirtualMachines object
param timestamp string
param virtualMachineMonitoringAgent string
param virtualMachineNamePrefix string
@secure()
param virtualMachinePassword string
param virtualMachineSize string
param virtualMachineUsername string
param virtualNetwork string
param virtualNetworkResourceGroup string

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
var fslogixOfficeShare = '\\\\${storageAccountPrefix}??.file.${storageSuffix}\\office-containers\\*\\*.VHDX'
var fslogixProfileShare = '\\\\${storageAccountPrefix}??.file.${storageSuffix}\\profile-containers\\*\\*.VHDX'
var imageReference = empty(imageDefinitionResourceId) ? {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSku
  version: 'latest'
} : {
  id: imageDefinitionResourceId
}
var intune = contains(activeDirectorySolution, 'intuneEnrollment')
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
var pooledHostPool = (split(hostPoolType, ' ')[0] == 'Pooled')
var securitylogAnalyticsWorkspaceName = securityMonitoring ? split(securityLogAnalyticsWorkspaceResourceId, '/')[8] : ''
var securityLogAnalyticsWorkspaceResourceGroupName = securityMonitoring ? split(securityLogAnalyticsWorkspaceResourceId, '/')[4] : resourceGroup().name
var securityLogAnalyticsWorkspaceSubscriptionId = securityMonitoring ? split(securityLogAnalyticsWorkspaceResourceId, '/')[2] : subscription().subscriptionId
var securityMonitoring = empty(securityLogAnalyticsWorkspaceResourceId) ? false : true
var securityWorkspaceKey = securityMonitoring ? listKeys(securityLogAnalyticsWorkspaceResourceId, '2021-06-01').primarySharedKey : 'NotApplicable'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (securityMonitoring) {
  name: securitylogAnalyticsWorkspaceName
  scope: resourceGroup(securityLogAnalyticsWorkspaceSubscriptionId, securityLogAnalyticsWorkspaceResourceGroupName)
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
            id: resourceId(subscription().subscriptionId, virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork, subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: acceleratedNetworking == 'True' ? true : false
    enableIPForwarding: false
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(0, sessionHostCount): {
  name: '${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
  location: location
  tags: tagsVirtualMachines
  zones: availability == 'AvailabilityZones' ? [
    availabilityZones[i % length(availabilityZones)]
  ] : null
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${artifactsUserAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    availabilitySet: availability == 'AvailabilitySets' ? {
      id: resourceId('Microsoft.Compute/availabilitySets', '${availabilitySetNamePrefix}${padLeft((i + sessionHostIndex) / 200, 2, '0')}')
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
      computerName: '${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
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
          id: resourceId('Microsoft.Network/networkInterfaces', '${networkInterfaceNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}')
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
      Exclusions: fslogix ? {
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

resource extension_MicrosoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): if (monitoring && virtualMachineMonitoringAgent == 'LogAnalyticsAgent') {
  parent: virtualMachine[i]
  name: 'MicrosoftmonitoringAgent'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.monitoring'
    type: 'MicrosoftmonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: monitoring ? reference(resourceId(resourceGroupManagement, 'Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName), '2015-03-20').customerId : null
    }
    protectedSettings: {
      workspaceKey: monitoring ? listKeys(resourceId(resourceGroupManagement, 'Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName), '2015-03-20').primarySharedKey : null
    }
  }
  dependsOn: [
    extension_IaasAntimalware
  ]
}]

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, sessionHostCount): if (monitoring && virtualMachineMonitoringAgent == 'AzureMonitorAgent') {
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

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = [for i in range(0, sessionHostCount): if (monitoring && virtualMachineMonitoringAgent == 'AzureMonitorAgent') {
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

resource extension_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): {
  parent: virtualMachine[i]
  name: 'CustomScriptExtension'
  location: location
  tags: tagsVirtualMachines
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsUri}${avdAgentBootLoaderMsiName}'
        '${artifactsUri}${avdAgentMsiName}'
        '${artifactsUri}Set-SessionHostConfiguration.ps1'
      ]
      timestamp: timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -activeDirectorySolution ${activeDirectorySolution} -amdVmSize ${amdVmSize} -avdAgentBootLoaderMsiName "${avdAgentBootLoaderMsiName}" -avdAgentMsiName "${avdAgentMsiName}" -Environment ${environment().name} -fslogix ${fslogix} -fslogixContainerType ${fslogixContainerType} -hostPoolName ${hostPoolName} -HostPoolRegistrationToken "${reference(resourceId(resourceGroupControlPlane, 'Microsoft.DesktopVirtualization/hostpools', hostPoolName), '2019-12-10-preview').registrationInfo.token}" -imageOffer ${imageOffer} -imagePublisher ${imagePublisher} -netAppFileShares ${netAppFileShares} -nvidiaVmSize ${nvidiaVmSize} -pooledHostPool ${pooledHostPool} -securityMonitoring ${securityMonitoring} -SecurityWorkspaceId ${securityMonitoring ? logAnalyticsWorkspace.properties.customerId : 'NotApplicable'} -securityWorkspaceKey "${securityWorkspaceKey}" -storageAccountPrefix ${storageAccountPrefix} -storageCount ${storageCount} -storageIndex ${storageIndex} -storageService ${storageService} -storageSuffix ${storageSuffix}'
      managedidentity: {
        clientId: artifactsUserAssignedIdentityClientId
      }
    }
  }
  dependsOn: [
    dataCollectionRuleAssociation
    extension_MicrosoftMonitoringAgent
  ]
}]

// Enables drain mode on the session hosts so users cannot login to hosts immediately after the deployment
module drainMode '../common/customScriptExtensions.bicep' = if (enableDrainMode) {
  name: 'CSE_DrainMode_${batchCount}_${timestamp}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    fileUris: [
      '${artifactsUri}Set-AvdDrainMode.ps1'
    ]
    location: location
    parameters: '-Environment ${environment().name} -hostPoolName ${hostPoolName} -HostPoolResourceGroupName ${resourceGroupControlPlane} -sessionHostCount ${sessionHostCount} -sessionHostIndex ${sessionHostIndex} -SubscriptionId ${subscription().subscriptionId} -TenantId ${tenant().tenantId} -userAssignedidentityClientId ${deploymentUserAssignedidentityClientId} -virtualMachineNamePrefix ${virtualMachineNamePrefix}'
    scriptFileName: 'Set-AvdDrainMode.ps1'
    tags: tagsVirtualMachines
    userAssignedIdentityClientId: deploymentUserAssignedidentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    extension_CustomScriptExtension
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

resource extension_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, sessionHostCount): if (!contains(activeDirectorySolution, 'DomainServices')) {
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
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    extension_AADLoginForWindows
    extension_JsonADDomainExtension
  ]
}]
