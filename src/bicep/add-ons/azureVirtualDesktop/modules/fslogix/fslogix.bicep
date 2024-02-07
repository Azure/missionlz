targetScope = 'subscription'

param artifactsUri string
param activeDirectoryConnection string
param activeDirectorySolution string
param automationAccountName string
param availability string
param azureFilesPrivateDnsZoneResourceId string
param delegatedSubnetId string
param deploymentUserAssignedIdentityClientId string
param dnsServers string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param encryptionUserAssignedIdentityResourceId string
param fileShares array
param fslogixShareSizeInGB int
param fslogixContainerType string
param fslogixStorageService string
param hostPoolName string
param hostPoolType string
param keyVaultUri string
param location string
param managementVirtualMachineName string
param netAppAccountName string
param netAppCapacityPoolName string
param netbios string
param organizationalUnitPath string
param recoveryServices bool
param recoveryServicesVaultName string
param resourceGroupControlPlane string
param resourceGroupManagement string
param resourceGroupStorage string
param securityPrincipalObjectIds array
param securityPrincipalNames array
param smbServerLocation string
param storageAccountNamePrefix string
param storageCount int
param storageEncryptionKeyName string
param storageIndex int
param storageSku string
param storageService string
param subnet string
param tags object
param timestamp string
param timeZone string
param virtualNetwork string
param virtualNetworkResourceGroup string

var tagsAutomationAccounts = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {})
var tagsNetAppAccount = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.NetApp/netAppAccounts') ? tags['Microsoft.NetApp/netAppAccounts'] : {})
var tagsPrivateEndpoints = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {})
var tagsStorageAccounts = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {})
var tagsRecoveryServicesVault = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.recoveryServices/vaults') ? tags['Microsoft.recoveryServices/vaults'] : {})
var tagsVirtualMachines = union({'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'}, contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {})

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if (storageService == 'AzureNetAppFiles' && contains(activeDirectorySolution, 'DomainServices')) {
  name: 'AzureNetAppFiles_${timestamp}'
  scope: resourceGroup(resourceGroupStorage)
  params: {
    artifactsUri: artifactsUri
    activeDirectoryConnection: activeDirectoryConnection
    delegatedSubnetId: delegatedSubnetId
    dnsServers: dnsServers
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    fileShares: fileShares
    fslogixContainerType: fslogixContainerType
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    netAppAccountName: netAppAccountName
    netAppCapacityPoolName: netAppCapacityPoolName
    organizationalUnitPath: organizationalUnitPath
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalNames: securityPrincipalNames
    smbServerLocation: smbServerLocation
    storageSku: storageSku
    storageService: storageService
    tagsNetAppAccount: tagsNetAppAccount
    tagsVirtualMachines: tagsVirtualMachines
    timestamp: timestamp
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
  }
}

// Azure Files for FSLogix
module azureFiles 'azureFiles/azureFiles.bicep' = if (storageService == 'AzureFiles' && contains(activeDirectorySolution, 'DomainServices')) {
  name: 'AzureFiles_${timestamp}'
  scope: resourceGroup(resourceGroupStorage)
  params: {
    activeDirectorySolution: activeDirectorySolution
    artifactsUri: artifactsUri
    automationAccountName: automationAccountName
    availability: availability
    azureFilesPrivateDnsZoneResourceId: azureFilesPrivateDnsZoneResourceId
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentityClientId
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    enableRecoveryServices: recoveryServices
    encryptionUserAssignedIdentityResourceId: encryptionUserAssignedIdentityResourceId
    fileShares: fileShares
    fslogixContainerType: fslogixContainerType
    fslogixShareSizeInGB: fslogixShareSizeInGB
    fslogixStorageService: fslogixStorageService
    hostPoolType: hostPoolType
    keyVaultUri: keyVaultUri
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    netbios: netbios
    organizationalUnitPath: organizationalUnitPath
    recoveryServicesVaultName: recoveryServicesVaultName
    resourceGroupManagement: resourceGroupManagement
    resourceGroupStorage: resourceGroupStorage
    securityPrincipalNames: securityPrincipalNames
    securityPrincipalObjectIds: securityPrincipalObjectIds
    storageAccountNamePrefix: storageAccountNamePrefix
    storageCount: storageCount
    storageEncryptionKeyName: storageEncryptionKeyName
    storageIndex: storageIndex
    storageService: storageService
    storageSku: storageSku
    subnet: subnet
    tagsAutomationAccounts: tagsAutomationAccounts
    tagsPrivateEndpoints: tagsPrivateEndpoints
    tagsRecoveryServicesVault: tagsRecoveryServicesVault
    tagsStorageAccounts: tagsStorageAccounts
    tagsVirtualMachines: tagsVirtualMachines
    timestamp: timestamp
    timeZone: timeZone 
    virtualNetwork: virtualNetwork
    virtualNetworkResourceGroup: virtualNetworkResourceGroup
  }
}

output netAppShares array = storageService == 'AzureNetAppFiles' ? azureNetAppFiles.outputs.fileShares : [
  'None'
]
