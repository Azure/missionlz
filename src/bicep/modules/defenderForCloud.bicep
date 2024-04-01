/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('Defender Paid protection Plans. Even if a customer selects the free sku, at least 1 paid protection plan must be specified.')
param defenderPlans array = ['VirtualMachines']

@description('Turn automatic deployment by Defender of the MMA (OMS VM extension) on or off')
param enableAutoProvisioning bool = true
var autoProvisioning = enableAutoProvisioning ? 'On' : 'Off'

@description('Specify the ID of your custom Log Analytics workspace to collect Defender data.')
param logAnalyticsWorkspaceId string

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string

@description('Policy Initiative description field')
param policySetDescription string = 'The Microsoft Cloud Security Benchmark initiative represents the policies and controls implementing security recommendations defined in Microsoft Cloud Security Benchmark v2, see https://aka.ms/azsecbm. This also serves as the Microsoft Defender for Cloud default policy initiative. You can directly assign this initiative, or manage its policies and compliance results within Microsoft Defender.'

@description('[Standard/Free] The SKU for Defender. It defaults to "Free".')
param defenderSkuTier string = 'Free'

// Variables for Defender for Cloud Paid Plan Handling for AzureCloud only

var defenderPaidPlansSpecialHandlingAzurePublicList = ['Api']

var defenderPaidPlanConfig = {
  AzureCloud: {
    Api: {
      subPlan: 'P1'
    }
  }
}

// Defender for Cloud - Free SKU turn on for all clouds
@batchSize(1)
resource defenderFreeAllClouds 'Microsoft.Security/pricings@2023-01-01' = [for name in defenderPlans: if (!empty(defenderPlans) && defenderSkuTier == 'Free') {
  name: name
  properties: {
    pricingTier: defenderSkuTier
  }
}]


// defender for cloud Standard SKU - No subplan, no extensions

@batchSize(1)
resource defenderStandardNoSubplanNoExtensions 'Microsoft.Security/pricings@2023-01-01' = [for name in defenderPlans: if (!empty(defenderPlans) && defenderSkuTier == 'Standard' && !contains(defenderPaidPlansSpecialHandlingAzurePublicList, name)) {
  name: name
  properties: {
    pricingTier: defenderSkuTier
  }
}]


// defender for cloud Standard SKU - AzureCloud only - Handing instances with subplans must be defined
@batchSize(1)
resource defenderStandardSubplanExtensionsAzureCloud 'Microsoft.Security/pricings@2023-01-01' = [for name in defenderPlans: if (!empty(defenderPlans) && defenderSkuTier == 'Standard' && contains(defenderPaidPlansSpecialHandlingAzurePublicList, name) && environment().name == 'AzureCloud'){
  name: name
  properties: !contains(defenderPaidPlanConfig[environment().name][name], 'subPlan') ? {
    pricingTier: defenderSkuTier
  }:{
    pricingTier: defenderSkuTier
    subPlan: defenderPaidPlanConfig[environment().name][name].subPlan
  }
}
]

// auto provisioing
#disable-next-line BCP081
resource autoProvision 'Microsoft.Security/autoProvisioningSettings@2019-01-01' = {
  name: 'default'
  properties: {
    autoProvision: autoProvisioning
  }
}

#disable-next-line BCP081
resource securityWorkspaceSettings 'Microsoft.Security/workspaceSettings@2019-01-01' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}

resource securityNotifications 'Microsoft.Security/securityContacts@2020-01-01-preview' = if (!empty(emailSecurityContact)) {
  name: 'default'
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
