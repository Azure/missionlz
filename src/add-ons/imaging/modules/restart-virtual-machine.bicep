/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param imageVirtualMachineName string
param resourceGroupName string
param location string
param mlzTags object
param tags object
param userAssignedIdentityClientId string
param virtualMachineName string

resource imageVirtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: imageVirtualMachineName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource restartVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'restartVirtualMachine'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'VmResourceId'
        value: imageVirtualMachine.id
      }
    ]
    source: {
      script: loadTextContent('../scripts/Restart-AzureVirtualMachine.ps1')
    }
  }
}
