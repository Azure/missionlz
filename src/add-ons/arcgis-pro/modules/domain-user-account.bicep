targetScope = 'subscription'

param deploymentNameSuffix string
@secure()
param domainUserPassword string
param domainUserUsername string
param location string
param mlzTags object
param tags object
param virtualMachineResourceIds array

var resourceGroupName = split(virtualMachineResourceIds[0], '/')[4]
var subscriptionId = split(virtualMachineResourceIds[0], '/')[2]

module newDomainUserAccount '../../../modules/run-command.bicep' = {
  name: 'new-domain-user-account-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    name: 'New-DomainUserAccount'
    parameters: [
      {
        name: 'DomainUserUsername'
        value: domainUserUsername
      }
    ]
    protectedParameters: '[{\'name\':\'DomainUserPassword\',\'value\':\'${domainUserPassword}\'}]'
    script: loadTextContent('../artifacts/New-DomainUserAccount.ps1')
    tags: tags
    virtualMachineName: split(virtualMachineResourceIds[0], '/')[8]
  }
}
