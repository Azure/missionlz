/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
param environmentAbbreviation string
param keyExpirationInDays int = 30
param keyName string
param keyVaultPrivateDnsZoneResourceId string
param location string
param resourceAbbreviations object
param subnetResourceId string
param tags object
param tier object
param tokens object
@allowed([
  'storageAccount'
  'virtualMachine'
])
param type string
@secure()
param virtualMachineAdminPassword string = newGuid()
param virtualMachineAdminUsername string = 'xadmin'
param virtualMachineSize string = 'Standard_D2ds_v4'

var keyVaultPrivateEndpointName = replace(tier.namingConvention.keyVaultPrivateEndpoint, tokens.purpose, workload)
var resourceGroupName = resourceGroup().name
var userAssignedIdentityName = replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, workload)
var virtualMachineName = replace(tier.namingConvention.virtualMachine, tokens.purpose, workload)
var workload = 'cmk'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
  tags: tags
}

// Network interface for the management virtual machine
resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: replace(tier.namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'cmk')
  location: location
  tags: tags
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

// Management virtual machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachineName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-core-g2'
        version: 'latest'
      }
      osDisk: {
        deleteOption: 'Delete'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'None'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        name: replace(tier.namingConvention.virtualMachineDisk, tokens.purpose, workload)
      }
      dataDisks: []
    }
    osProfile: {
      adminPassword: virtualMachineAdminPassword
      adminUsername: virtualMachineAdminUsername
      computerName: virtualMachineName
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
      '${userAssignedIdentity.id}': {}
    }
  }
}

resource roleAssignment_diskEncryptionSetOperator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, '136d308c-0937-4a49-9bd7-edfb42adbffc', resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '136d308c-0937-4a49-9bd7-edfb42adbffc') // Disk Encryption Set Operator for Managed Disks (Purpose: read and create disk encryption sets)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignment_virtualMachineContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, '9980e02c-c2be-4d73-94e8-173b1dc7cf3c', virtualMachine.id)
  scope: virtualMachine
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c') // Virtual Machine Contributor (Purpose: delete the management virtual machine)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${resourceAbbreviations.keyVaults}${uniqueString(tier.subscriptionId, resourceGroupName, replace(tier.namingConvention.keyVault, tokens.purpose, workload))}'
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
    sku: {
      family: 'A'
      name: 'premium'
    }
    softDeleteRetentionInDays: environmentAbbreviation == 'dev' || environmentAbbreviation == 'test' ? 7 : 90
    tenantId: subscription().tenantId
  }
}

resource roleAssignment_keyVaultAdministrator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, '00482a5a-887f-4fb3-b363-3b7fe8e74483', vault.id)
  scope: vault
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483') // Key Vault Administrator
  }
}

resource roleAssignment_keyVaultContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, 'f25e0fa2-a7c8-4377-a976-54943a77a395', vault.id)
  scope: vault
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'f25e0fa2-a7c8-4377-a976-54943a77a395') // Key Vault Contributor
  }
}

resource roleAssignment_keyVaultCryptoServiceEncryptionUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', vault.id)
  scope: vault
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: replace(tier.namingConvention.keyVaultNetworkInterface, tokens.purpose, workload)
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
  dependsOn: [
    roleAssignment_keyVaultAdministrator
    roleAssignment_keyVaultCryptoServiceEncryptionUser
  ]
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: vault.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZoneResourceId
        }
      }
    ]
  }
  dependsOn: [
    roleAssignment_keyVaultAdministrator
    roleAssignment_keyVaultCryptoServiceEncryptionUser
  ]
}

resource key 'Microsoft.Compute/virtualMachines/runCommands@2025-04-01' = {
  parent: virtualMachine
  name: keyName
  location: location
  tags: tags
  properties: {
    asyncExecution: false
    parameters: [
      {
        name: 'DiskEncryptionSetName'
        value: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, workload)
      }
      {
        name: 'KeyExpirationInDays'
        value: string(keyExpirationInDays)
      }
      {
        name: 'KeyName'
        value: keyName
      }
      {
        name: 'KeyVaultResourceId'
        value: vault.id
      }
      {
        name: 'KeyVaultServiceUri'
        value: 'https://${skip(environment().suffixes.keyvaultDns, 1)}'
      }
      {
        name: 'KeyVaultUri'
        value: vault.properties.vaultUri
      }
      {
        name: 'ResourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'SubscriptionId'
        value: tier.subscriptionId
      }
      {
        name: 'Type'
        value: type
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentity.properties.clientId
      }
    ]
    source: {
      script: loadTextContent('../artifacts/New-KeyVaultKey.ps1')
    }
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    privateDnsZoneGroup
    privateEndpoint
  ]
}

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' existing = if (type == 'virtualMachine') {
  name: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, workload)
  dependsOn: [
    key
  ]
}

resource deleteVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  parent: virtualMachine
  name: 'delete-vm-${deploymentNameSuffix}'
  location: location
  tags: tags
  properties: {
    asyncExecution: true
    parameters: [
      {
        name: 'ResourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentity.properties.clientId
      }
      {
        name: 'VirtualMachineResourceId'
        value: virtualMachine.id
      }
    ]
    source: {
      script: loadTextContent('../artifacts/Remove-VirtualMachine.ps1')
    }
    treatFailureAsDeploymentFailure: true
  }
  dependsOn: [
    diskEncryptionSet
    key
    roleAssignment_diskEncryptionSetOperator
    roleAssignment_virtualMachineContributor
    roleAssignment_keyVaultAdministrator
    roleAssignment_keyVaultCryptoServiceEncryptionUser
  ]
}

output diskEncryptionSetResourceId string = type == 'virtualMachine' ? diskEncryptionSet.id : ''
// The following output is needed to setup the diagnostic setting for the key vault
output keyVaultProperties object = {
  diagnosticSettingName: replace(tier.namingConvention.keyVaultDiagnosticSetting, tokens.purpose, workload)
  name: vault.name
  resourceGroupName: resourceGroupName
  subscriptionId: tier.subscriptionId
  tierName: tier.name // This value is used to associate the key vault diagnostic setting with the appropriate storage account
}
output keyName string = keyName
output keyVaultName string = vault.name
output keyVaultUri string = vault.properties.vaultUri
output keyVaultResourceId string = vault.id
output keyVaultNetworkInterfaceResourceId string = privateEndpoint.properties.networkInterfaces[0].id
output userAssignedIdentityResourceId string = userAssignedIdentity.id
