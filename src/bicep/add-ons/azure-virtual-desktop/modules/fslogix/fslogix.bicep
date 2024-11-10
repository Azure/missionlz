targetScope = 'subscription'

param existingSharedActiveDirectoryConnection bool
param activeDirectorySolution string
param availability string
param azureFilesPrivateDnsZoneResourceId string
param subnets array
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param dnsServers string
@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param domainName string
param encryptionUserAssignedIdentityResourceId string
param fileShares array
param fslogixShareSizeInGB int
param fslogixContainerType string
param fslogixStorageService string
param functionAppName string
param keyVaultUri string
param location string
param managementVirtualMachineName string
param mlzTags object
param namingConvention object
param netbios string
param organizationalUnitPath string
param recoveryServices bool
param resourceGroupControlPlane string
param resourceGroupManagement string
param resourceGroupStorage string
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

var hostPoolName = namingConvention.hostPool

var tagsNetAppAccount = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.NetApp/netAppAccounts') ? tags['Microsoft.NetApp/netAppAccounts'] : {}, mlzTags)
var tagsVirtualMachines = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}, mlzTags)

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (storageService == 'AzureNetAppFiles') {
  name: 'deploy-anf-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupStorage)
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
  scope: resourceGroup(resourceGroupStorage)
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
    functionAppName: functionAppName
    keyVaultUri: keyVaultUri
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    namingConvention: namingConvention
    netbios: netbios
    organizationalUnitPath: organizationalUnitPath
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    resourceGroupManagement: resourceGroupManagement
    resourceGroupStorage: resourceGroupStorage
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
    hostPoolName: hostPoolName
    mlzTags: mlzTags
    resourceGroupControlPlane: resourceGroupControlPlane
  }
}

output netAppShares array = storageService == 'AzureNetAppFiles' ? azureNetAppFiles.outputs.fileShares : [
  'None'
]
output storageAccountNamePrefix string = storageService == 'AzureFiles' ? azureFiles.outputs.storageAccountNamePrefix : ''
