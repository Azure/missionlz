/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param storageAccountName string
param location string
param skuName string
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}
output id string = storageAccount.id
