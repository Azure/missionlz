/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bundle array = (environment().name == 'AzureCloud') ? [  
  'KeyVaults'
  'SqlServers'
  'VirtualMachines'
  'StorageAccounts'
  'ContainerRegistry'
  'KubernetesService'
  'SqlServerVirtualMachines'
  'AppServices'
  'Dns'
  'Arm'
  ] : (environment().name == 'AzureUSGovernment') ? [
    'SqlServers'
    'VirtualMachines'
    'StorageAccounts'
    'ContainerRegistry'
    'KubernetesService'
    'Dns'
    'Arm'
  ] : []

@description('Turn automatic deployment by Defender of the MMA (OMS VM extension) on or off')
param enableAutoProvisioning bool = true
var autoProvisioning = enableAutoProvisioning ? 'On' : 'Off'

@description('Specify the ID of your custom Log Analytics workspace to collect Defender data.')
param logAnalyticsWorkspaceId string

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string

@description('Policy Initiative description field')
param policySetDescription string = 'The Azure Security Benchmark initiative represents the policies and controls implementing security recommendations defined in Azure Security Benchmark v2, see https://aka.ms/azsecbm. This also serves as the Microsoft Defender for Cloud default policy initiative. You can directly assign this initiative, or manage its policies and compliance results within Microsoft Defender.'


// defender

resource defenderPricing 'Microsoft.Security/pricings@2018-06-01' = [for name in bundle: {
  name: name
  properties: {
    pricingTier: 'Standard'
  }
}]

// auto provisioing

resource autoProvision 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    autoProvision: autoProvisioning
  }
}

resource securityWorkspaceSettings  'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}

resource securityNotifications 'Microsoft.Security/securityContacts@2017-08-01-preview' = if (!empty(emailSecurityContact)) {
  name: 'securityNotifications'
  properties: {
    alertsToAdmins: 'On'
    alertNotifications: 'On'
    email: emailSecurityContact
  }
}

resource securityPoliciesDefault 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: 'Azure Security Benchmark'
  scope: subscription()
  properties: {
    displayName: 'Defender Default'
    description: policySetDescription
    enforcementMode: 'DoNotEnforce'
    parameters: {}
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
  }
}
