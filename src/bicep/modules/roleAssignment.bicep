param targetResourceId string
param roleDefinitionId string
param principalId string
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'Unknown'
  'DirectoryRoleTemplate'
  'ForeignGroup'
  'Application'
  'MSI'
  'DirectoryObjectOrGroup'
  'Everyone'
])
param principalType string = 'ServicePrincipal'
param description string = ''

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(targetResourceId,roleDefinitionId,principalId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: roleDefinitionId
    description: description
  }
}
