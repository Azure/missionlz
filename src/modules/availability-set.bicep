param availabilitySetName string
param location string
param mlzTags object
param tags object

resource availabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = {
  name: availabilitySetName
  location: location
  tags: union(tags[?'Microsoft.Compute/availabilitySets'] ?? {}, mlzTags)
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}

output resourceId string = availabilitySet.id
