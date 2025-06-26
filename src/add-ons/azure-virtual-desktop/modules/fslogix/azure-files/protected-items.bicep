param fileShares array
param location string
param policyId string
param protectionContainerName string
param sourceResourceId string
param tags object

// Only configures backups for profile containers
// Office containers contain M365 cached data that does not need to be backed up
resource protectedItems_FileShare 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2022-03-01' = [for fileShare in fileShares: if (contains(fileShare, 'profile')) {
  name: '${protectionContainerName}/AzureFileShare;${fileShare}'
  location: location
  tags: tags
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    policyId: policyId
    sourceResourceId: sourceResourceId
  }
}]
