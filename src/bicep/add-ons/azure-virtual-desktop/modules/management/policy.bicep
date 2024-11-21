targetScope = 'subscription'

param diskAccessResourceId string = ''
param location string
param resourceGroupName string

var parameters = !empty(diskAccessResourceId) ? {
  diskAccessId: {
    type: 'String'
    metadata: {
      displayName: 'Disk Access Resource Id'
      description: 'The resource Id of the Disk Access to associate to the managed disks.'
    }
  }
} : {}

var operations = !empty(diskAccessResourceId)
  ? [
      {
        operation: 'addOrReplace'
        field: 'Microsoft.Compute/disks/networkAccessPolicy'
        value: 'AllowPrivate'
      }
      {
        operation: 'addOrReplace'
        field: 'Microsoft.Compute/disks/publicNetworkAccess'
        value: 'Disabled'
      }
      {
        operation: 'addOrReplace'
        field: 'Microsoft.Compute/disks/diskAccessId'
        value: '[parameters(\'diskAccessId\')]'
      }
    ]
  : [
      {
        operation: 'addOrReplace'
        field: 'Microsoft.Compute/disks/networkAccessPolicy'
        value: 'DenyAll'
      }
      {
        operation: 'addOrReplace'
        field: 'Microsoft.Compute/disks/publicNetworkAccess'
        value: 'Disabled'
      }
    ]


resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'DiskNetworkAccess'
  properties: {
    description: 'Disable network access to managed disks.'
    displayName: 'Disable Disk Access'
    mode: 'All'
    parameters: parameters
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Compute/disks'
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/60fc6e62-5479-42d4-8bf4-67625fcc2840'
          ]
          operations: operations
        }
      }
    }
    policyType: 'Custom'
  }
}

module policyAssignment 'policyAssignment.bicep' = {
  name: 'assign-policy-disk-network-access'
  scope: resourceGroup(resourceGroupName)
  params: {
    diskAccessResourceId: diskAccessResourceId
    location: location
    policyDefinitionId: policyDefinition.id
    policyDisplayName: policyDefinition.properties.displayName
    policyName: policyDefinition.properties.displayName
  }
}

output policyDefinitionId string = policyDefinition.id
output policyDisplayName string = policyDefinition.properties.displayName
