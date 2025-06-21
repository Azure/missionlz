param availabilitySetName string
param location string

resource availablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: availabilitySetName
  location: location
  tags: {}
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

output name string = availablitySet.name
