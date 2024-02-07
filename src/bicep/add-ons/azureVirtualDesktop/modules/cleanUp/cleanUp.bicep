targetScope = 'subscription' 

param fslogixStorageService string
param location string
param resourceGroupManagement string
param scalingTool bool
param timestamp string
param userAssignedIdentityClientId string
param virtualMachineName string

module removeManagementVirtualMachine 'removeVirtualMachine.bicep' = if (!scalingTool && !(fslogixStorageService == 'AzureFiles Premium')) {
  scope: resourceGroup(resourceGroupManagement)
  name: 'RemoveManagementVirtualMachine_${timestamp}'
  params: {
    Location: location
    UserAssignedIdentityClientId: userAssignedIdentityClientId
    VirtualMachineName: virtualMachineName
  }
}
