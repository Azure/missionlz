param fileShares array
param fslogixShareSizeInGB int
param storageAccountName string
param storageSku string

resource shares 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = [for i in range(0, length(fileShares)): {
  name: '${storageAccountName}/default/${fileShares[i]}'
  properties: {
    accessTier: storageSku == 'Premium' ? 'Premium' : 'TransactionOptimized'
    shareQuota: fslogixShareSizeInGB
    enabledProtocols: 'SMB'
  }
}]
