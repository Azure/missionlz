targetScope = 'subscription'

param existingSharedActiveDirectoryConnection bool
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
param enableApplicationInsights bool
param encryptionUserAssignedIdentityResourceId string
param environmentAbbreviation string
param fileShares array
param fslogixShareSizeInGB int
param fslogixContainerType string
param fslogixStorageService string
param hostPoolResourceId string
param keyVaultUri string
param location string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param mlzTags object
param namingConvention object
param netbios string
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param recoveryServices bool
param resourceAbbreviations object
param resourceGroupManagement string
param resourceGroupName string
param securityPrincipalObjectIds array
param securityPrincipalNames array
param serviceToken string
param smbServerLocation string
param storageCount int
param storageEncryptionKeyName string
param storageIndex int
param storageSku string
param storageService string
param subnetResourceId string
param tags object

var tagsNetAppAccount = union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.NetApp/netAppAccounts'] ?? {}, mlzTags)
var tagsVirtualMachines = union({'cm-resource-parent': hostPoolResourceId}, tags['Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)

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

// Deploys the Auto Increase Premium File Share Quota solution on an Azure Function App
module functionApp '../management/functionApp.bicep' = if (fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-function-app-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    delegatedSubnetResourceId: filter(subnets, subnet => contains(subnet.name, 'FunctionAppOutbound'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolResourceId: hostPoolResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    namingConvention: namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceAbbreviations: resourceAbbreviations
    serviceToken: serviceToken
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (storageService == 'AzureNetAppFiles') {
  name: 'deploy-anf-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    existingSharedActiveDirectoryConnection: existingSharedActiveDirectoryConnection
    delegatedSubnetResourceId: filter(subnets, subnet => contains(subnet.name, 'AzureNetAppFiles'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    dnsServers: dnsServers
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    fileShares: fileShares
    fslogixContainerType: fslogixContainerType
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    netAppAccountName: namingConvention.netAppAccount
    netAppCapacityPoolName: namingConvention.netAppAccountCapacityPool
    organizationalUnitPath: organizationalUnitPath
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalNames: securityPrincipalNames
    smbServerLocation: smbServerLocation
    storageService: storageService
    storageSku: storageSku
    tagsNetAppAccount: tagsNetAppAccount
    tagsVirtualMachines: tagsVirtualMachines
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
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    enableRecoveryServices: recoveryServices
    encryptionUserAssignedIdentityResourceId: encryptionUserAssignedIdentityResourceId
    fileShares: fileShares
    fslogixContainerType: fslogixContainerType
    fslogixShareSizeInGB: fslogixShareSizeInGB
    fslogixStorageService: fslogixStorageService
    functionAppName: functionApp.outputs.functionAppName
    hostPoolResourceId: hostPoolResourceId
    keyVaultUri: keyVaultUri
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    namingConvention: namingConvention
    netbios: netbios
    organizationalUnitPath: organizationalUnitPath
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalNames: securityPrincipalNames
    securityPrincipalObjectIds: securityPrincipalObjectIds
    serviceToken: serviceToken
    storageCount: storageCount
    storageEncryptionKeyName: storageEncryptionKeyName
    storageIndex: storageIndex
    storageService: storageService
    storageSku: storageSku
    subnetResourceId: subnetResourceId
    tags: tags
    mlzTags: mlzTags
  }
}

output netAppShares array = storageService == 'AzureNetAppFiles' ? azureNetAppFiles.outputs.fileShares : [
  'None'
]
output storageAccountNamePrefix string = storageService == 'AzureFiles' ? azureFiles.outputs.storageAccountNamePrefix : ''
