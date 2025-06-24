param asyncExecution bool = false
param location string
param mlzTags object
param name string
param parameters array = []
@secure()
param protectedParameters string = ''
param script string
param tags object
param treatFailureAsDeploymentFailure bool = true
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: virtualMachineName
}

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  parent: virtualMachine
  name: name
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    asyncExecution: asyncExecution
    parameters: parameters
    protectedParameters: json(protectedParameters)
    source: {
      script: script
    }
    treatFailureAsDeploymentFailure: treatFailureAsDeploymentFailure
  }
}
