param availabilitySetNamePrefix string
param availabilitySetsCount int
param availabilitySetsIndex int
param location string
param tagsAvailabilitySets object

resource availabilitySets 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, availabilitySetsCount): {
  name: '${availabilitySetNamePrefix}-${padLeft((i + availabilitySetsIndex), 2, '0')}'
  location: location
  tags: tagsAvailabilitySets
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}]
