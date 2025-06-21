param deploymentNameSuffix string
param fileShares array
param location string
param recoveryServicesVaultName string
param resourceGroupStorage string
param storageAccountNamePrefix string
param storageCount int
param storageIndex int
param tagsRecoveryServicesVault object

resource vault 'Microsoft.RecoveryServices/vaults@2022-03-01' existing =  {
  name: recoveryServicesVaultName
}

resource protectionContainers 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2022-03-01' = [for i in range(0, storageCount): {
  #disable-next-line use-parent-property
  name: '${vault.name}/Azure/storagecontainer;Storage;${resourceGroupStorage};${storageAccountNamePrefix}${padLeft(i + storageIndex, 2, '0')}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: resourceId(resourceGroupStorage, 'Microsoft.Storage/storageAccounts', '${storageAccountNamePrefix}${padLeft(i + storageIndex, 2, '0')}')
  }
}]

resource backupPolicy_Storage 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' existing = {
  parent: vault
  name: 'AvdPolicyStorage'
}

module protectedItems_fileShares 'protected-items.bicep' = [for i in range(0, storageCount): {
  name: 'backup-file-shares-${i + storageIndex}-${deploymentNameSuffix}'
  params: {
    fileShares: fileShares
    location: location
    protectionContainerName: protectionContainers[i].name
    policyId: backupPolicy_Storage.id
    sourceResourceId: resourceId(resourceGroupStorage, 'Microsoft.Storage/storageAccounts', '${storageAccountNamePrefix}${padLeft(i + storageIndex, 2, '0')}')
    tags: tagsRecoveryServicesVault
  }
}]
