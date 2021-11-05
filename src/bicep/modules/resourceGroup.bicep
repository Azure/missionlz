targetScope = 'subscription'

param name string
param location string
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: name
  location: location
  tags: tags
}

output id string = resourceGroup.id
output name string = resourceGroup.name
output location string = resourceGroup.location
