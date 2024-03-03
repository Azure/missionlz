param deploymentNameSuffix string
param location string
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceGroupName string
param networks array
param policy string

var operations = first(filter(networks, network => network.name == 'operations'))

module policyAssignments 'policy-assignment.bicep' = [for network in networks: {
  name: 'assign-policy-${network.name}-${deploymentNameSuffix}'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspaceResourceGroupName
    operationsSubscriptionId: operations.subscriptionId
    location: location
  }
}]
