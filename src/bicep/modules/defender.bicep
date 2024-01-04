/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bundle array = (environment().name == 'AzureCloud') ? [
  'Api'
  'AppServices'
  'Arm'
  'CloudPosture'
  //'ContainerRegistry' (deprecated)
  'Containers'
  'CosmosDbs'
  //'Dns' (deprecated)
  'KeyVaults'
  //'KubernetesService' (deprecated)
  'OpenSourceRelationalDatabases'
  'SqlServers'
  'SqlServerVirtualMachines'
  'StorageAccounts'
  'VirtualMachines'
] : (environment().name == 'AzureUSGovernment') ? [
  'Arm'
  //'ContainerRegistry' (deprecated)
  'Containers'
  //'Dns' (deprecated)
  //'KubernetesService' (deprecated)
  'OpenSourceRelationalDatabases'
  'SqlServers'
  'SqlServerVirtualMachines'
  'StorageAccounts'
  'VirtualMachines'
] : []

@description('Turn automatic deployment by Defender of the MMA (OMS VM extension) on or off')
param enableAutoProvisioning bool = true
var autoProvisioning = enableAutoProvisioning ? 'On' : 'Off'

@description('Specify the ID of your custom Log Analytics workspace to collect Defender data.')
param logAnalyticsWorkspaceId string

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string

@description('Policy Initiative description field')
param policySetDescription string = 'The Microsoft Cloud Security Benchmark initiative represents the policies and controls implementing security recommendations defined in Microsoft Cloud Security Benchmark v2, see https://aka.ms/azsecbm. This also serves as the Microsoft Defender for Cloud default policy initiative. You can directly assign this initiative, or manage its policies and compliance results within Microsoft Defender.'

@description('[Standard/Free] The SKU for Defender. It defaults to "Standard".')
param defenderSkuTier string = 'Standard'

// defender
@batchSize(1)
resource defenderPricing 'Microsoft.Security/pricings@2023-01-01' = [for name in bundle: {
  name: name
  properties: {
    pricingTier: defenderSkuTier
  }
}]

// auto provisioing

resource autoProvision 'Microsoft.Security/autoProvisioningSettings@2019-01-01' = {
  name: 'default'
  properties: {
    autoProvision: autoProvisioning
  }
}

resource securityWorkspaceSettings 'Microsoft.Security/workspaceSettings@2019-01-01' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}

resource securityNotifications 'Microsoft.Security/securityContacts@2020-01-01-preview' = if (!empty(emailSecurityContact)) {
  name: 'securityNotifications'
  properties: {
    notificationsByRole: {
      roles: [
        'AccountAdmin'
        'Contributor'
        'Owner'
        'ServiceAdmin'
      ]
      state: 'On'
    }
    alertNotifications: {
      state: 'On'
    }
    emails: emailSecurityContact
  }
}

resource securityPoliciesDefault 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'Microsoft Cloud Security Benchmark'
  scope: subscription()
  properties: {
    displayName: 'Defender Default'
    description: policySetDescription
    enforcementMode: 'DoNotEnforce'
    parameters: {}
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policySetDefinitions', '1f3afdf9-d0c9-4c3d-847f-89da613e70a8')
  }
}
