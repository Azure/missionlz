targetScope = 'subscription'

param name string
param location string
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: tags
}

output id string = resourceGroup.id
output name string = resourceGroup.name
