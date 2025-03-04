param deploymentUserAssignedIdentityPrincipalId string
param deploymentUserAssignedIdentityResourceId string
param diskEncryptionSetResourceId string
param diskName string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param hostPoolResourceId string
param location string
param mlzTags object
param networkInterfaceName string
param organizationalUnitPath string
param subnetResourceId string
param tags object
param timestamp string = utcNow('yyyyMMddhhmmss')
param virtualMachineName string
@secure()
param virtualMachinePassword string
param virtualMachineUsername string

var tagsVirtualMachines = union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName
  location: location
  tags: union({
    'cm-resource-parent': hostPoolResourceId
  }, tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
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
        name: diskName
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
    type: 'UserAssigned'
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
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, 'a959dbd1-f747-45e3-8ba6-dd80f235f97c', virtualMachine.id)
  scope: virtualMachine
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c') // Desktop Virtualization Virtual Machine Contributor (Purpose: remove the management virtual machine)
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output name string = virtualMachine.name
output resourceId string = virtualMachine.id
