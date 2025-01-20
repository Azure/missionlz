targetScope = 'managementGroup'

@description('Policy set name')
param policySetName string

@description('Policy set display name')
param policySetDisplayName string

@description('Policy set description')
param policySetDescription string

@description('Policy set category')
param policySetCategory string

@description('Policy definition IDs')
param policyDefinitionIds array

resource policySet 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: policySetName
  properties: {
    displayName: policySetDisplayName
    description: policySetDescription
    metadata: {
      category: policySetCategory
    }
    policyDefinitions: [
      for id in policyDefinitionIds: {
        policyDefinitionId: id
      }
    ]
    policyType: 'Custom'
  }
}

output policySetId string = policySet.id


