targetScope = 'subscription'

param location string
param resourceGroupName string
param tags object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: resourceGroupName
  location: location
  tags: contains(tags, 'Microsoft.Resources/resourceGroups') ? tags['Microsoft.Resources/resourceGroups'] : {}
}
