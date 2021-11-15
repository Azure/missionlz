param svcPlanName string
param location string
param capacity int = 2
param kind string
param sku string

var reserved = kind == 'linux' ? true : false

@description('The instance size of the app.')
param svcPlanSize string = 'P2v2'

resource svcPlanName_resource 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: svcPlanName
  location: location
  kind: kind
  sku: {
    name: svcPlanSize
    tier: sku
    capacity: capacity
  }
  properties: {
    reserved: reserved
  }
}

output svcPlanName string = svcPlanName_resource.name
output svcPlanID string = svcPlanName_resource.id
