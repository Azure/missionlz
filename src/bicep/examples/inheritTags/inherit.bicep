param tagNameInherit string

param nowUtc string = utcNow()

resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: 'deploy-inheritTagPolicy-${nowUtc}'
  location: resourceGroup().location
  properties: {
      policyDefinitionId:'/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
      parameters: {
        tagName: {
          value: tagNameInherit
      }
  }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

