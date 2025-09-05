/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
@secure()
param domainAdministratorPassword string
param domainAdministratorUsername string
@secure()
param hybridIdentityAdministratorPassword string
param hybridIdentityAdministratorUserPrincipalName string
param location string
param mlzTags object
param name string
param tags object
param virtualMachineNames array

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSync 'run-command.bicep' = [ for (virtualMachineName, i) in virtualMachineNames: {
  name: 'install-entra-cloud-sync-${i}-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: name
    parameters: [
      {
        name: 'AzureEnvironment'
        value: environment().name
      }
      {
        name: 'AzureResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'DomainAdministratorUsername'
        value: domainAdministratorUsername
      }
      {
        name: 'HybridIdentityAdministratorUserPrincipalName'
        value: hybridIdentityAdministratorUserPrincipalName
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
    ]
    protectedParameters: '[{\'name\':\'DomainAdministratorPassword\',\'value\':\'${domainAdministratorPassword}\'},{\'name\':\'HybridIdentityAdministratorPassword\',\'value\':\'${hybridIdentityAdministratorPassword}\'}]'
    script: loadTextContent('../artifacts/Install-EntraCloudSyncAgent.ps1')
    tags: tags
    virtualMachineName: virtualMachineName
  }
}]
