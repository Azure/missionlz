/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@secure()
param accessToken string
@secure()
param adminPassword string
param adminUsername string
param deploymentNameSuffix string
param domainName string
param location string
param mlzTags object
param tags object
param userAssignedManagedIdentityClientId string
param virtualMachineResourceIds array

var resourceGroupName = split(virtualMachineResourceIds[0], '/')[4]
var subscriptionId = split(virtualMachineResourceIds[0], '/')[2]

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSyncAgents '../../../modules/run-command.bicep' = {
  name: 'install-entra-cloud-sync-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    name: 'Install-EntraCloudSyncAgent'
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
        value: adminUsername
      }
      {
        name: 'DomainName'
        value: domainName
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
      {
        name: 'TenantId'
        value: subscription().tenantId
      }
      {
        name: 'UserPrincipalName'
        value: deployer().userPrincipalName
      }
    ]
    protectedParameters: '[{\'name\':\'AccessToken\',\'value\':\'${accessToken}\'},{\'name\':\'DomainAdministratorPassword\',\'value\':\'${adminPassword}\'}]'
    script: loadTextContent('../artifacts/Install-EntraCloudSyncAgent.ps1')
    tags: tags
    virtualMachineName: split(virtualMachineResourceIds[0], '/')[8]
  }
}

// Run command to provision the Entra Cloud Sync configuration in Entra ID
module provisionEntraCloudSyncConfiguration '../../../modules/run-command.bicep' = {
  name: 'provision-entra-cloud-sync-config-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    name: 'New-EntraCloudSyncConfiguration'
    parameters: [
      {
        name: 'CloudSuffix'
        value: last(split(split(environment().resourceManager, '/')[2], '.'))
      }
      {
        name: 'DomainName'
        value: domainName
      }
      {
        name: 'TenantId'
        value: subscription().tenantId
      }
      {
        name: 'UserAssignedManagedIdentityClientId'
        value: userAssignedManagedIdentityClientId
      }
    ]
    script: loadTextContent('../artifacts/New-EntraCloudSyncConfiguration.ps1')
    tags: tags
    virtualMachineName: split(virtualMachineResourceIds[0], '/')[8]
  }
  dependsOn: [
    installEntraCloudSyncAgents
  ]
}
