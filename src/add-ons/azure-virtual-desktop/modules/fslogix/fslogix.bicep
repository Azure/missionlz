targetScope = 'subscription'

param activeDirectorySolution string
param availability string
param azureFilesPrivateDnsZoneResourceId string
param delimiter string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param deploymentUserAssignedIdentityPrincipalId string
@secure()
param domainAdminPassword string
@secure()
param domainAdminUserPrincipalName string
param domainName string
param encryptionUserAssignedIdentityResourceId string
param fileShareNames array
param fslogixShareSizeInGB int
param fslogixStorageService string
param functionAppPrincipalId string
param hostPoolResourceId string
param keyVaultName string
param keyVaultUri string
param location string
param managementVirtualMachineName string
param mlzTags object
param netbios string
param organizationalUnitPath string
// param recoveryServices bool
param resourceGroupManagement string
param securityPrincipalNames array
param securityPrincipalObjectIds array
param storageCount int
param storageIndex int
param storageSku string
param storageService string
param tags object
param tier object
param tokens object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: replace(tier.namingConvention.resourceGroup, tokens.purpose, 'fslogix')
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

// Role Assignment for FSLogix
// Purpose: assigns the Storage Account Contributor role to the managed identity on the
// management virtual machine  storage resource group to domain join storage account(s) & set NTFS permissions on the file share(s)
module roleAssignment_Storage '../common/role-assignments/resource-group.bicep' = {
  name: 'assign-role-storage-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
}

// Required role assignment for the funciton to manage the quota on Azure Files Premium
module roleAssignments_resourceGroup '../common/role-assignments/resource-group.bicep' = if (fslogixStorageService == 'AzureFiles Premium') {
  name: 'set-role-assignment-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  }
}

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azure-netapp-files.bicep' = if (storageService == 'AzureNetAppFiles') {
  name: 'deploy-anf-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    delegatedSubnetResourceId: filter(tier.subnets, subnet => contains(subnet.name, 'azure-netapp-files'))[0].id
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    dnsServers: join(tier.dnsServers, ',')
    domainAdminPassword: domainAdminPassword
    domainAdminUserPrincipalName: domainAdminUserPrincipalName
    domainName: domainName
    fileShareNames: fileShareNames
    hostPoolResourceId: hostPoolResourceId
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    mlzTags: mlzTags
    netAppAccountNamePrefix: replace(tier.namingConvention.netAppAccount, '${delimiter}${tokens.purpose}', '')
    netAppCapacityPoolNamePrefix: replace(tier.namingConvention.netAppAccountCapacityPool, '${delimiter}${tokens.purpose}', '')
    organizationalUnitPath: organizationalUnitPath
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalNames: securityPrincipalNames
    smbServerName: replace(tier.namingConvention.netAppAccountSmbServer, '${delimiter}${tokens.purpose}', '')
    storageSku: storageSku
    suffix: 'fslogix'
    tags: tags
  }
}

// Azure Files for FSLogix
module azureFiles 'azure-files/azure-files.bicep' = if (storageService == 'AzureFiles') {
  name: 'deploy-azure-files-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    azureFilesPrivateDnsZoneResourceId: azureFilesPrivateDnsZoneResourceId
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    domainAdminPassword: domainAdminPassword
    domainAdminUserPrincipalName: domainAdminUserPrincipalName
    encryptionUserAssignedIdentityResourceId: encryptionUserAssignedIdentityResourceId
    fileShareNames: fileShareNames
    fslogixShareSizeInGB: fslogixShareSizeInGB
    hostPoolResourceId: hostPoolResourceId
    keyVaultName: keyVaultName
    keyVaultUri: keyVaultUri
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    mlzTags: mlzTags
    names: tier.namingConvention
    netbios: netbios
    organizationalUnitPath: organizationalUnitPath
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalNames: securityPrincipalNames
    securityPrincipalObjectIds: securityPrincipalObjectIds
    storageCount: storageCount
    storageIndex: storageIndex
    storageSku: storageSku
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tokens: tokens
  }
}

output netAppFileServer string = storageService == 'AzureNetAppFiles' ? azureNetAppFiles!.outputs.netAppFileServer : ''
output storageAccountNamePrefix string = storageService == 'AzureFiles' ? azureFiles!.outputs.storageAccountNamePrefix : ''
