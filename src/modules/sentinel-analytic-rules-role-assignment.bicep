param logAnalyticsWorkspaceResourceId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string

// Reference existing workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: split(logAnalyticsWorkspaceResourceId, '/')[8]
}

// Role assignment: Microsoft Sentinel Contributor on workspace
resource analyticRulesSentinelRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspaceResourceId, userAssignedIdentityResourceId, 'ab8e14d6-4a74-4a29-9ba8-549422addade')
  scope: workspace
  properties: {
    principalId: userAssignedIdentityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ab8e14d6-4a74-4a29-9ba8-549422addade') // Microsoft Sentinel Contributor
    principalType: 'ServicePrincipal'
  }
}
