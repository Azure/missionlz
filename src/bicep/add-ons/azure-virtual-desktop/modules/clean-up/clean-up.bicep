targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param resourceGroupManagement string
param userAssignedIdentityClientId string
param virtualMachineResourceId string

module cleanUp '../common/run-command.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'clean-up-${deploymentNameSuffix}'
  params: {
    asyncExecution: true
    location: location
    name: 'Remove-VirtualMachine'
    parameters: [
      {
        name: 'ResourceGroupName'
        value: resourceGroupManagement
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'VirtualMachineResourceId'
        value: virtualMachineResourceId
      }
    ]
    script: loadTextContent('../../artifacts/Remove-VirtualMachine.ps1')
    tags: {}
    treatFailureAsDeploymentFailure: true
    virtualMachineName: split(virtualMachineResourceId, '/')[8]
  }
}
