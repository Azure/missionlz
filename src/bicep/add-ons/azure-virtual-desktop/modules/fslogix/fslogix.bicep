targetScope = 'subscription'

param activeDirectorySolution string
param availability string
param azureFilesPrivateDnsZoneResourceId string
param subnets array
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
param dnsServers string
@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param domainName string
param encryptionUserAssignedIdentityResourceId string
param fileShares array
param fslogixContainerType string
param fslogixShareSizeInGB int
param fslogixStorageService string
param functionAppPrincipalId string
param hostPoolResourceId string
param keyVaultUri string
param location string
param managementVirtualMachineName string
param mlzTags object
param namingConvention object
param netbios string
param organizationalUnitPath string
param recoveryServices bool
param resourceGroupManagement string
param resourceGroupName string
param securityPrincipalObjectIds array
param securityPrincipalNames array
param serviceToken string
param storageCount int
param storageEncryptionKeyName string
param storageIndex int
param storageSku string
param storageService string
param subnetResourceId string
param tags object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

// Role Assignment for FSLogix
// Purpose: assigns the Storage Account Contributor role to the managed identity on the
// management virtual machine  storage resource group to domain join storage account(s) & set NTFS permissions on the file share(s)
module roleAssignment_Storage '../common/roleAssignments/resourceGroup.bicep' = {
  name: 'assign-role-storage-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
}

// Required role assignment for the funciton to manage the quota on Azure Files Premium
module roleAssignments_resourceGroup '../common/roleAssignments/resourceGroup.bicep' = if (fslogixStorageService == 'AzureFiles Premium') {
  name: 'set-role-assignment-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  }
}

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (storageService == 'AzureNetAppFiles') {
  name: 'deploy-anf-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    delegatedSubnetResourceId: filter(subnets, subnet => contains(subnet.name, 'AzureNetAppFiles'))[0].id
    dnsServers: dnsServers
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    fileShares: fileShares
    hostPoolResourceId: hostPoolResourceId
    location: location
    mlzTags: mlzTags
    netAppAccountName: namingConvention.netAppAccount
    netAppCapacityPoolName: namingConvention.netAppAccountCapacityPool
    organizationalUnitPath: organizationalUnitPath
    smbServerName: namingConvention.netAppAccountSmbServer
    storageSku: storageSku
    tags: tags
  }
}

// Azure Files for FSLogix
module azureFiles 'azureFiles/azureFiles.bicep' = if (storageService == 'AzureFiles') {
  name: 'deploy-azure-files-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    azureFilesPrivateDnsZoneResourceId: azureFilesPrivateDnsZoneResourceId
    deploymentNameSuffix: deploymentNameSuffix
    enableRecoveryServices: recoveryServices
    encryptionUserAssignedIdentityResourceId: encryptionUserAssignedIdentityResourceId
    fileShares: fileShares
    fslogixShareSizeInGB: fslogixShareSizeInGB
    hostPoolResourceId: hostPoolResourceId
    keyVaultUri: keyVaultUri
    location: location
    namingConvention: namingConvention
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalObjectIds: securityPrincipalObjectIds
    serviceToken: serviceToken
    storageCount: storageCount
    storageEncryptionKeyName: storageEncryptionKeyName
    storageIndex: storageIndex
    storageSku: storageSku
    subnetResourceId: subnetResourceId
    tags: tags
    mlzTags: mlzTags
  }
}

module ntfsPermissions 'ntfsPermissions.bicep' = {
  scope: resourceGroup
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    location: location
    parameters: storageService == 'AzureNetAppFiles' ? [
      {
        name: 'FileShares'
        value: string(fileShares)
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'SecurityPrincipalNames'
        value: string(securityPrincipalNames)
      }
      {
        name: 'SmbServerNamePrefix'
        value: azureNetAppFiles.outputs.smbServerNamePrefix
      }
      {
        name: 'StorageService'
        value: storageService
      }
    ] : [
      {
        name: 'ActiveDirectorySolution'
        value: activeDirectorySolution
      }
      {
        name: 'FslogixContainerType'
        value: fslogixContainerType
      }
      {
        name: 'Netbios'
        value: netbios
      }
      {
        name: 'OrganizationalUnitPath'
        value: organizationalUnitPath
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'SecurityPrincipalNames'
        value: string(securityPrincipalNames)
      }
      {
        name: 'StorageAccountPrefix'
        value: azureFiles.outputs.storageAccountNamePrefix
      }
      {
        name: 'StorageAccountResourceGroupName'
        value: resourceGroupName
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
        value: environment().suffixes.storage
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: deploymentUserAssignedIdentityClientId
      }
    ]
    resourceGroupName: resourceGroupManagement
    tags: tags
    virtualMachineName: managementVirtualMachineName
  }
}

output netAppShares array = storageService == 'AzureNetAppFiles' ? azureNetAppFiles.outputs.fileShares : [
  'None'
]
output storageAccountNamePrefix string = storageService == 'AzureFiles' ? azureFiles.outputs.storageAccountNamePrefix : ''
