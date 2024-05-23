targetScope = 'subscription'

param artifactsUri string
param activeDirectoryConnection string
param activeDirectorySolution string
param availability string
param azureFilesPrivateDnsZoneResourceId string
param delegatedSubnetId string
param deploymentNameSuffix string
param deploymentUserAssignedIdentityClientId string
param dnsServers string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param encryptionUserAssignedIdentityResourceId string
param environmentAbbreviation string
param fileShares array
param fslogixShareSizeInGB int
param fslogixContainerType string
param fslogixStorageService string
param hostPoolType string
param identifier string
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
param timeZone string

var hostPoolName = namingConvention.hostPool

var tagsAutomationAccounts = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}, mlzTags)
var tagsNetAppAccount = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.NetApp/netAppAccounts') ? tags['Microsoft.NetApp/netAppAccounts'] : {}, mlzTags)
var tagsPrivateEndpoints = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}, mlzTags)
var tagsStorageAccounts = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}, mlzTags)
var tagsRecoveryServicesVault = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.recoveryServices/vaults') ? tags['Microsoft.recoveryServices/vaults'] : {}, mlzTags)
var tagsVirtualMachines = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}, mlzTags)

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (storageService == 'AzureNetAppFiles' && contains(activeDirectorySolution, 'DomainServices')) {
  name: 'deploy-anf-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupStorage)
  params: {
    activeDirectoryConnection: activeDirectoryConnection
    artifactsUri: artifactsUri
    delegatedSubnetId: delegatedSubnetId
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
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
module azureFiles 'azureFiles/azureFiles.bicep' = if (storageService == 'AzureFiles' && contains(activeDirectorySolution, 'DomainServices')) {
  name: 'deploy-azure-files-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupStorage)
  params: {
    activeDirectorySolution: activeDirectorySolution
    artifactsUri: artifactsUri
    automationAccountName: namingConvention.automationAccount
    availability: availability
    azureFilesPrivateDnsZoneResourceId: azureFilesPrivateDnsZoneResourceId
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    enableRecoveryServices: recoveryServices
    encryptionUserAssignedIdentityResourceId: encryptionUserAssignedIdentityResourceId
    environmentAbbreviation: environmentAbbreviation
    fileShares: fileShares
    fslogixContainerType: fslogixContainerType
    fslogixShareSizeInGB: fslogixShareSizeInGB
    fslogixStorageService: fslogixStorageService
    hostPoolType: hostPoolType
    identifier: identifier
    keyVaultUri: keyVaultUri
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    netbios: netbios
    organizationalUnitPath: organizationalUnitPath
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    resourceGroupManagement: resourceGroupManagement
    resourceGroupStorage: resourceGroupStorage
    securityPrincipalNames: securityPrincipalNames
    securityPrincipalObjectIds: securityPrincipalObjectIds
    serviceName: serviceToken
    storageAccountNamePrefix: namingConvention.storageAccount
    storageAccountNetworkInterfaceNamePrefix: namingConvention.storageAccountNetworkInterface
    storageAccountPrivateEndpointNamePrefix: namingConvention.storageAccountPrivateEndpoint
    storageCount: storageCount
    storageEncryptionKeyName: storageEncryptionKeyName
    storageIndex: storageIndex
    storageService: storageService
    storageSku: storageSku
    subnetResourceId: subnetResourceId
    tagsAutomationAccounts: tagsAutomationAccounts
    tagsPrivateEndpoints: tagsPrivateEndpoints
    tagsRecoveryServicesVault: tagsRecoveryServicesVault
    tagsStorageAccounts: tagsStorageAccounts
    tagsVirtualMachines: tagsVirtualMachines
    timeZone: timeZone 
  }
}

output netAppShares array = storageService == 'AzureNetAppFiles' ? azureNetAppFiles.outputs.fileShares : [
  'None'
]
