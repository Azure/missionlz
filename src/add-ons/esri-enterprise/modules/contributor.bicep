targetScope = 'subscription'

param userAssignedIdentityId string
param subscriptionId string
param deploymentNameSuffix string

module roleAssignmentVirtualMachineContributor './roleAssignmentContributor.bicep' = {
  name: 'assign-role-vm-02-${deploymentNameSuffix}'
  scope: subscription(subscriptionId)
  params: {
    principalId: userAssignedIdentityId
    subscriptionid: subscriptionId
  }
  dependsOn: [
  ]
}

