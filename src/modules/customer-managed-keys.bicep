/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
param environmentAbbreviation string
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

var resourceGroupName = resourceGroup().name
var userAssignedIdentityName = replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, workload)
var virtualMachineName = replace(tier.namingConvention.virtualMachine, tokens.purpose, workload)
var workload = 'cmk'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' =  {
  name: userAssignedIdentityName
  location: location
  tags: tags
}

resource roleAssignment_keyVaultContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', resourceGroup().id)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'f25e0fa2-a7c8-4377-a976-54943a77a395')  // Key Vault Contributor
  }
}

resource roleAssignment_keyVaultCryptoServiceEncryptionUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', resourceGroup().id)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')  // Key Vault Crypto Service Encryption User
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: replace(tier.namingConvention.networkInterface, tokens.purpose, 'cmk')
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
        name: replace(tier.namingConvention.disk, tokens.purpose, workload)
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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, 'a959dbd1-f747-45e3-8ba6-dd80f235f97c', virtualMachine.id)
  scope: virtualMachine
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c') // Desktop Virtualization Virtual Machine Contributor (Purpose: remove the management virtual machine)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

module keyVault 'key-vault.bicep' = {
  name: 'deploy-${workload}-kv-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    keyName: keyName
    keyVaultName: '${resourceAbbreviations.keyVaults}${uniqueString(tier.subscriptionId, resourceGroupName, replace(tier.namingConvention.keyVault, tokens.purpose, workload))}'
    keyVaultNetworkInterfaceName: replace(tier.namingConvention.keyVaultNetworkInterface, tokens.purpose, workload)
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: replace(tier.namingConvention.keyVaultPrivateEndpoint, tokens.purpose, workload)
    location: location
    managementVirtualMachineName: virtualMachine.name
    subnetResourceId: tier.subnetResourceId
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentity.properties.clientId
  }
}

module diskEncryptionSet 'disk-encryption-set.bicep' = if (type == 'virtualMachine') {
  name: 'deploy-${workload}-des-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, workload)
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    tags: tags
  }
}

module deleteVirtualMachine 'run-command.bicep' = {
  name: 'delete-vm-${deploymentNameSuffix}'
  params: {
    asyncExecution: true
    location: location
    name: 'Remove-VirtualMachine'
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
    script: loadTextContent('../artifacts/Remove-VirtualMachine.ps1')
    tags: tags
    treatFailureAsDeploymentFailure: true
    virtualMachineName: virtualMachine.name
  }
  dependsOn: [
    diskEncryptionSet
    keyVault
    roleAssignment
  ]
}

output diskEncryptionSetResourceId string = type == 'virtualMachine' ? diskEncryptionSet!.outputs.resourceId : ''
// The following output is needed to setup the diagnostic setting for the key vault
output keyVaultProperties object = {
  diagnosticSettingName: replace(tier.namingConvention.keyVaultDiagnosticSetting, tokens.purpose, workload)
  name: keyVault.outputs.keyVaultName
  resourceGroupName: resourceGroupName
  subscriptionId: tier.subscriptionId
  tierName: tier.name // This value is used to associate the key vault diagnostic setting with the appropriate storage account
}
output keyName string = keyVault.outputs.keyName
output keyUriWithVersion string = keyVault.outputs.keyUriWithVersion
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output keyVaultResourceId string = keyVault.outputs.keyVaultResourceId
output keyVaultNetworkInterfaceResourceId string = keyVault.outputs.networkInterfaceResourceId
output userAssignedIdentityResourceId string = userAssignedIdentity.id
