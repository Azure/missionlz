/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('Defender Paid protection Plans. Even if a customer selects the free sku, at least 1 paid protection plan must be specified.')
param defenderPlans array = ['VirtualMachines']

@description('Turn automatic deployment by Defender of the MMA (OMS VM extension) on or off')
param enableAutoProvisioning bool = false
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

var defenderPaidPlanConfig = {
  AzureCloud: {
    Api: {
      subPlan: 'P1'
    }
    appServices: {
      // Only requires sku defined, add future subplans and extensions here
    }
    KeyVaults: {
      subPlan: 'PerKeyVault'
    }
    Arm: {
      subPlan: 'PerSubscription'
    }
    CloudPosture: {
      extensions: [
        {
          name: 'SensitiveDataDiscovery'
          isEnabled: 'True'
        }
        {
          name: 'ContainerRegistriesVulnerabilityAssessments'
          isEnabled: 'True'
        }
        {
          name: 'AgentlessDiscoveryForKubernetes'
          isEnabled: 'True'
        }
        {
          name: 'AgentlessVmScanning'
          isEnabled: 'True'
        }
        {
          name: 'EntraPermissionsManagement'
          isEnabled: 'True'
        }   
      ]
    }
    Containers: {
      extensions: [
        {
          name: 'ContainerRegistriesVulnerabilityAssessments'
          isEnabled: 'True'
        }
        {
          name: 'AgentlessDiscoveryForKubernetes'
          isEnabled: 'True'
        }
      ]
    }
    CosmosDbs: {
      // Only requires sku defined, add future subplans and extensions here
    }
    StorageAccounts: {
      subPlan: 'DefenderForStorageV2'
      extensions: [
        {
          name: 'OnUploadMalwareScanning'
          isEnabled: 'True'
          additionalExtensionProperties: {
              CapGBPerMonthPerStorageAccount: '5000'
          }
        }
        {
          name: 'SensitiveDataDiscovery'
          isEnabled: 'True'
        }
      ]
    }
    VirtualMachines: {
      subPlan: 'P1'
    }
    SqlServerVirtualMachines: {
      // Only requires sku defined, add future subplans and extensions here
    }
    SqlServers: {
      // Only requires sku defined, add future subplans and extensions here
    }
    OpenSourceRelationalDatabases: {
      // Only requires sku defined, add future subplans and extensions here
    }  
  }
}

// Defender for Cloud - Free SKU turn on for all clouds
@batchSize(1)
resource defenderFreeAllClouds 'Microsoft.Security/pricings@2023-01-01' = [for name in defenderPlans: if (defenderSkuTier == 'Free') {
  name: name
  properties: {
    pricingTier: defenderSkuTier
  }
}]


// defender for cloud Standard SKU - No subplan, no extensions

@batchSize(1)
resource defenderStandardNoSubplanNoExtensions 'Microsoft.Security/pricings@2023-01-01' = [for name in defenderPlans: if (defenderSkuTier == 'Standard' && !(environment().name == 'AzureCloud')) {
  name: name
  properties: {
    pricingTier: defenderSkuTier
  }
}]

// defender for cloud Standard SKU - AzureCloud only - Handing all combinations  This is the new example
@batchSize(1)
resource defenderStandardSubplanExtensionsAzureCloud 'Microsoft.Security/pricings@2023-01-01' = [for name in defenderPlans: if (defenderSkuTier == 'Standard' && environment().name == 'AzureCloud'){
  name: name
  properties: {
    pricingTier: defenderSkuTier
    subPlan: contains(defenderPaidPlanConfig[environment().name][name],'subPlan') ? defenderPaidPlanConfig[environment().name][name].subPlan : json('null')
    extensions: contains(defenderPaidPlanConfig[environment().name][name],'extensions') ? defenderPaidPlanConfig[environment().name][name].extensions : json('null')
  }
}
]



// auto provisioing - check environment type

resource autoProvision 'Microsoft.Security/autoProvisioningSettings@2019-01-01' = if (!(environment().name == 'AzureCloud' || environment().name == 'AzureUSGovernment') ) {
  name: 'default'
  properties: {
    autoProvision: autoProvisioning
  }
}

resource securityWorkspaceSettings 'Microsoft.Security/workspaceSettings@2019-01-01' = if (!(environment().name == 'AzureCloud' || environment().name == 'AzureUSGovernment') ) {
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
