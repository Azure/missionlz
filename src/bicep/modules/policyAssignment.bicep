param builtInAssignment string = ''
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceGroupName string
param operationsSubscriptionId string

// Creating a symbolic name for an existing resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(operationsSubscriptionId, logAnalyticsWorkspaceResourceGroupName)
}

var policyDefinitionID = {
  NIST: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f'
    parameters: json(replace(loadTextContent('policies/NIST-policyAssignmentParameters.json'),'<LAWORKSPACE>', logAnalyticsWorkspace.id))
  }  
  IL5: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197'
    parameters: json(replace(loadTextContent('policies/IL5-policyAssignmentParameters.json'),'<LAWORKSPACE>', logAnalyticsWorkspace.id))
  }
  CMMC: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/b5629c75-5c77-4422-87b9-2509e680f8de'
    parameters: json(replace(loadTextContent('policies/CMMC-policyAssignmentParameters.json'),'<LAWORKSPACE>', logAnalyticsWorkspace.properties.customerId))
  }  
}

var modifiedAssignment = ( environment().name =~ 'AzureCloud' && builtInAssignment =~ 'IL5' ? 'NIST' : builtInAssignment )
var assignmentName = '${modifiedAssignment} ${resourceGroup().name}'

resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = if (!empty(modifiedAssignment)){
  name: assignmentName
  location: resourceGroup().location
  properties: {
      policyDefinitionId: policyDefinitionID[modifiedAssignment].id
      parameters: policyDefinitionID[modifiedAssignment].parameters
  }
  identity: {
    type: 'SystemAssigned'
  }
}
