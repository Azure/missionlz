@minLength(5)
@maxLength(50)
param registryName string
param location string = resourceGroup().location
param registrySku string = 'premium'
param publicNetworkAccess string = 'enabled'

resource registryName_resource 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: registrySku
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    adminUserEnabled: true
    policies: {
      trustPolicy: {
        type: 'Notary'
        status: 'enabled'
      }
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
  }
}
