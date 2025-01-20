targetScope = 'managementGroup'

@description('Policy set ID')
param policySetId string

@description('Policy set name')
param policySetName string

@description('Policy location')
param policyLocation string

@description('Policy assignment display name')
param policyAssignmentDisplayName string

@description('User assigned identity for the policy assignment')
param mlzPolicyUserAssignedIdentityId string

@description('Region for the virtual network')
param vnetRegion string

@description('Array of required routes')
param requiredRoutes array

@description('Disable BGP Propagation')
param disableBgpPropagation bool

@description('Next Hop IP Address')
param nextHopIpAddress string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policySetName
  location: policyLocation
  properties: {
    displayName: policyAssignmentDisplayName
    policyDefinitionId: policySetId
    metadata: {
      policyTargetScope: 'managementGroup'
    }
    enforcementMode: 'Default'
    parameters: {
      vnetRegion: {
        value: policyLocation
      }
      requiredRoutes: {
        value: requiredRoutes
      }
      disableBgpPropagation: {
        value: disableBgpPropagation
      }
      nextHopIpAddress: {
        value: nextHopIpAddress
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mlzPolicyUserAssignedIdentityId}': {}
    }
  }
}
