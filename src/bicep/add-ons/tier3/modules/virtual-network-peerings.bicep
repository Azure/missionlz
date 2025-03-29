targetScope = 'subscription'

param virtualNetworkPeerings array

var resourceIds = [for virtualNetworkPeering in virtualNetworkPeerings: virtualNetworkPeering.properties.remoteVirtualNetwork.id]
var subscriptionIds = [for resourceId in resourceIds: split(resourceId, '/')[2]]

output subscriptionIds array = subscriptionIds
