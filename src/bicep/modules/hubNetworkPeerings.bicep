targetScope = 'subscription'

param hubResourceGroupName string
param hubVirtualNetworkName string
param identityVirtualNetworkName string
param identityVirtualNetworkResourceId string
param operationsVirtualNetworkName string
param operationsVirtualNetworkResourceId string
param sharedServicesVirtualNetworkName string
param sharedServicesVirtualNetworkResourceId string

module hubToIdentityVirtualNetworkPeering './virtualNetworkPeering.bicep' = {
  scope: resourceGroup(hubResourceGroupName)
  name: 'hubToIdentityVirtualNetworkPeering'
  params: {
    name: '${hubVirtualNetworkName}/to-${identityVirtualNetworkName}'
    remoteVirtualNetworkResourceId: identityVirtualNetworkResourceId
  }
}

module hubToOperationsVirtualNetworkPeering './virtualNetworkPeering.bicep' = {
  scope: resourceGroup(hubResourceGroupName)
  name: 'hubToOperationsVirtualNetworkPeering'
  params: {
    name: '${hubVirtualNetworkName}/to-${operationsVirtualNetworkName}'
    remoteVirtualNetworkResourceId: operationsVirtualNetworkResourceId
  }
}

module hubToSharedServicesVirtualNetworkPeering './virtualNetworkPeering.bicep' = {
  scope: resourceGroup(hubResourceGroupName)
  name: 'hubToSharedServicesVirtualNetworkPeering'
  params: {
    name: '${hubVirtualNetworkName}/to-${sharedServicesVirtualNetworkName}'
    remoteVirtualNetworkResourceId: sharedServicesVirtualNetworkResourceId
  }
}
