/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@allowed([
  'NISTRev4'
  'NISTRev5'
  'IL5' // AzureUsGoverment only, trying to deploy IL5 in AzureCloud will switch to NISTRev4
  'CMMC'
])
@description('[NISTRev4/NISTRev5/IL5/CMMC] Built-in policy assignments to assign, default is NISTRev4. IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.')
param builtInAssignment string = 'NISTRev4'
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceGroupName string
param operationsSubscriptionId string

@description('Starts a policy remediation for the VM Agent policies in hub RG. Set to false by default since this is time consuming in deployment.')
param deployRemediation bool = false

@description('The location of this resource')
param location string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(operationsSubscriptionId, logAnalyticsWorkspaceResourceGroupName)
}

var policyDefinitionID = {
  NISTRev4: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f'
    parameters: json(replace(loadTextContent('policies/NISTRev4-policyAssignmentParameters.json'), '<LAWORKSPACE>', logAnalyticsWorkspace.id))
  }
  NISTRev5: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f'
    parameters: json(loadTextContent('policies/NISTRev5-policyAssignmentParameters.json'))
  }
  IL5: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197'
    parameters: json(replace(loadTextContent('policies/IL5-policyAssignmentParameters.json'), '<LAWORKSPACE>', logAnalyticsWorkspace.id))
  }
  CMMC: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/b5629c75-5c77-4422-87b9-2509e680f8de'
    parameters: json(replace(loadTextContent('policies/CMMC-policyAssignmentParameters.json'), '<LAWORKSPACE>', logAnalyticsWorkspace.properties.customerId))
  }
}

var modifiedAssignment = (environment().name =~ 'AzureCloud' && builtInAssignment =~ 'IL5' ? 'NISTRev4' : builtInAssignment)
var assignmentName = '${modifiedAssignment} ${resourceGroup().name}'
var agentVmssAssignmentName = 'Deploy VMSS Agents ${resourceGroup().name}'
var agentVmAssignmentName = 'Deploy VM Agents ${resourceGroup().name}'
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var lawsReaderRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')

// assign policy to resource group
resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: assignmentName
  location: location
  properties: {
    policyDefinitionId: policyDefinitionID[modifiedAssignment].id
    parameters: policyDefinitionID[modifiedAssignment].parameters
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource vmssAgentAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: agentVmssAssignmentName
  location: location
  properties: {
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policySetDefinitions', '75714362-cae7-409e-9b99-a8e5075b7fad')
    parameters: {
      logAnalytics_1: {
        value: logAnalyticsWorkspace.id
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource vmAgentAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: agentVmAssignmentName
  location: location
  properties: {
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policySetDefinitions', '55f3eceb-5573-4f18-9695-226972c6d74a')
    parameters: {
      logAnalytics_1: {
        value: logAnalyticsWorkspace.id
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// assign the policies assigned idenitity as contributor to each resource group for deploy if not exist and modify policiy remediation
resource policyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(contributorRoleDefinitionId, assignmentName)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: (empty(modifiedAssignment) ? '' : assignment.identity.principalId)
    principalType: 'ServicePrincipal'
  }
}

resource vmmsPolicyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(contributorRoleDefinitionId, agentVmssAssignmentName)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: vmssAgentAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource vmPolicyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(contributorRoleDefinitionId, agentVmAssignmentName)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: vmAgentAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module roleAssignment '../modules/role-assignment.bicep' = {
  name: 'Assign-Laws-Role-Policy-${resourceGroup().name}'
  scope: resourceGroup(operationsSubscriptionId, logAnalyticsWorkspaceResourceGroupName)
  params: {
    targetResourceId: logAnalyticsWorkspace.id
    roleDefinitionId: lawsReaderRoleDefinitionId
    principalId: vmAgentAssignment.identity.principalId
  }
}

resource vmPolicyRemediation 'Microsoft.PolicyInsights/remediations@2019-07-01' = if (deployRemediation) {
  name: 'VM-Agent-Policy-Remediation'
  properties: {
    policyAssignmentId: vmAgentAssignment.id
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
}
