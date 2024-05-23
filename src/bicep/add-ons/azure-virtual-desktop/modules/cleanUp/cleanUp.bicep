targetScope = 'subscription' 

param deploymentNameSuffix string
param fslogixStorageService string
param location string
param resourceGroupManagement string
param scalingTool bool
param userAssignedIdentityClientId string
param virtualMachineName string

module removeManagementVirtualMachine 'removeVirtualMachine.bicep' = if (!scalingTool && !(fslogixStorageService == 'AzureFiles Premium')) {
  scope: resourceGroup(resourceGroupManagement)
  name: 'remove-mgmt-vm-${deploymentNameSuffix}'
  params: {
    Location: location
    UserAssignedIdentityClientId: userAssignedIdentityClientId
    VirtualMachineName: virtualMachineName
  }
}
