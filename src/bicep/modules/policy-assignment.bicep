/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param builtInAssignment string
param deployRemediation bool
param location string
param logAnalyticsWorkspaceResourceId string
param networkWatcherResourceGroupName string
param windowsAdministratorsGroupMembership string

var policyDefinitionID = {
  NISTRev4: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f'
    parameters: union(json(replace(loadTextContent('policies/NISTRev4-policyAssignmentParameters.json'), 'NetworkWatcherRG', networkWatcherResourceGroupName)), {
      listOfMembersToIncludeInWindowsVMAdministratorsGroup: {
        value: windowsAdministratorsGroupMembership
      }
      logAnalyticsWorkspaceIdforVMReporting: {
        value:  logAnalyticsWorkspace.id
      }
      'resourceGroupName-b6e2945c-0b7b-40f5-9233-7a5323b5cdc6': {
        value: networkWatcherResourceGroupName
      }
    })
  }
  NISTRev5: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f'
    parameters: union(json(loadTextContent('policies/NISTRev5-policyAssignmentParameters.json')), {
      'resourceGroupName-b6e2945c-0b7b-40f5-9233-7a5323b5cdc6': {
        value: networkWatcherResourceGroupName
      }
    })
  }
  IL5: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197'
    parameters: union(json(loadTextContent('policies/IL5-policyAssignmentParameters.json')), {
      logAnalyticsWorkspaceIDForVMAgents: {
        value: logAnalyticsWorkspace.id
      }
      membersToIncludeInLocalAdministratorsGroup: {
        value: windowsAdministratorsGroupMembership
      }
      NetworkWatcherResourceGroupName: {
        value: networkWatcherResourceGroupName
      }
    })
  }
  CMMC: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/b5629c75-5c77-4422-87b9-2509e680f8de'
    parameters: union(json(loadTextContent('policies/CMMC-policyAssignmentParameters.json')),{
      'logAnalyticsWorkspaceId-f47b5582-33ec-4c5c-87c0-b010a6b2e917': {
        value: logAnalyticsWorkspace.properties.customerId
      }
      'resourceGroupName-b6e2945c-0b7b-40f5-9233-7a5323b5cdc6': {
        value: networkWatcherResourceGroupName
      }
    }, 'AzureCloud' == environment().name ? {
      'MembersToExclude-69bf4abd-ca1e-4cf6-8b5a-762d42e61d4f': {
        value: 'admin'
      }
      'MembersToInclude-30f71ea1-ac77-4f26-9fc5-2d926bbd4ba7': {
        value: windowsAdministratorsGroupMembership
      }
    } : {})
  }
}

var modifiedAssignment = (environment().name =~ 'AzureCloud' && builtInAssignment =~ 'IL5' ? 'NISTRev4' : builtInAssignment)
var assignmentName = '${modifiedAssignment} ${resourceGroup().name}'
var agentVmssAssignmentName = 'Deploy VMSS Agents ${resourceGroup().name}'
var agentVmAssignmentName = 'Deploy VM Agents ${resourceGroup().name}'
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var lawsReaderRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: split(logAnalyticsWorkspaceResourceId, '/')[8]
  scope: resourceGroup(split(logAnalyticsWorkspaceResourceId, '/')[2], split(logAnalyticsWorkspaceResourceId, '/')[4])
}

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
  scope: resourceGroup(split(logAnalyticsWorkspaceResourceId, '/')[2], split(logAnalyticsWorkspaceResourceId, '/')[4])
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
