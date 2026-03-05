@secure()
param domainAdminPassword string
@secure()
param domainAdminUserPrincipalName string
param location string
param name string
param parameters array = []
param script string
param tags object
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: virtualMachineName
}

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  parent: virtualMachine
  name: name
  location: location
  tags: tags 
  properties: {
    asyncExecution: false
    parameters: parameters
    protectedParameters: [
      {
        name: 'DomainAdminPassword'
        value: domainAdminPassword
      }
      {
        name: 'DomainAdminUserPrincipalName'
        value: domainAdminUserPrincipalName
      }
    ]
    source: {
      script: script
    }
    treatFailureAsDeploymentFailure: true
  }
}
