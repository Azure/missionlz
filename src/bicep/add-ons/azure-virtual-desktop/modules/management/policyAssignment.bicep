param diskAccessResourceId string
param location string
param policyDefinitionId string
param policyDisplayName string
param policyName string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyName
  scope: resourceGroup()
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: policyDisplayName
    policyDefinitionId: policyDefinitionId
    parameters: !empty(diskAccessResourceId) ? {
      diskAccessId: {
        value: diskAccessResourceId
      }       
    } : {}
  }
}
