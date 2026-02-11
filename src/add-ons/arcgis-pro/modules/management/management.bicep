targetScope = 'subscription'

param avdObjectId string
param delimiter string
param deploymentNameSuffix string
param enableAvdInsights bool
param environmentAbbreviation string
param location string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param mlzTags object
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param resourceAbbreviations object
param resourceGroupName string
param subscriptionId string
param tags object
param tier object
param tokens object

var hostPoolResourceId = resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.DesktopVirtualization/hostpools', replace(tier.namingConvention.hostPool, '${delimiter}${tokens.purpose}', ''))

module deploymentUserAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    name: replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, 'deployment')
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
  }
}

// Role Assignment for Autoscale
// Purpose: assigns the Desktop Virtualization Power On Off Contributor role to the 
// Azure Virtual Desktop service to scale the host pool
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdObjectId, '40c5ff49-9181-41f8-ae61-143b0e78555e', subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '40c5ff49-9181-41f8-ae61-143b0e78555e')
    principalId: avdObjectId
  }
}

module diskAccess 'disk-access.bicep' = {
  name: 'deploy-disk-access-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    delimiter: delimiter
    hostPoolResourceId: hostPoolResourceId
    location: location
    mlzTags: mlzTags
    names: tier.namingConvention
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tokens: tokens
  }
}

// Sets an Azure policy to disable public network access to managed disks
// module policy 'policy.bicep' = {
//   name: 'deploy-policy-disks-${deploymentNameSuffix}'
//   params: {
//     diskAccessResourceId: diskAccess.outputs.resourceId
//   }
// }

var parameters = !empty(diskAccess.outputs.resourceId) ? {
  diskAccessId: {
    type: 'String'
    metadata: {
      displayName: 'Disk Access Resource Id'
      description: 'The resource Id of the Disk Access to associate to the managed disks.'
    }
  }
} : {}

var operations = !empty(diskAccess.outputs.resourceId)
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

// Sets an Azure policy to disable public network access to managed disks
module policyAssignment 'policy-assignment.bicep' = {
  name: 'assign-policy-diskAccess-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
    location: location
    policyDefinitionId: policyDefinition.id
    policyDisplayName: policyDefinition.properties.displayName
    policyName: policyDefinition.properties.displayName
  }
}

module customerManagedKeys '../../../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'vaultcore'))[0]}'
    location: location
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: tier.subnets[0].id
    // TO DO: try to merge MLZ tags into the existing tags so the host pool resource ID isn't required in other deployments
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
    tier: tier
    tokens: tokens
    type: 'virtualMachine'
  }
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    location: location
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    names: tier.namingConvention
    privateLinkScopeResourceId: privateLinkScopeResourceId
    tags: tags
    tokens: tokens
  }
}

output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring!.outputs.dataCollectionRuleResourceId : ''
output diskAccessPolicyDefinitionId string = policyDefinition.id
output diskAccessPolicyDisplayName string = policyDefinition.properties.displayName
output diskAccessResourceId string = diskAccess.outputs.resourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output logAnalyticsWorkspaceResourceId string = enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
