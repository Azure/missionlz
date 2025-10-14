// wafpolicy-resolver.bicep
// Always invoked module that either creates a new WAF policy (if existing not supplied)
// or simply returns the existing policy's resource ID. This removes conditional module
// output access warnings in the parent template.

targetScope = 'resourceGroup'

@description('Existing WAF policy resource ID. If provided, no new policy is created.')
param existingWafPolicyId string
@description('Name to use when creating a new WAF policy (from naming module).')
param policyName string = 'appgw-waf-policy'
@description('Azure region (required only when creating a new policy).')
param location string
@description('Tags to apply when creating a new policy.')
param tags object = {}
@description('WAF mode when creating new policy.')
param mode string = 'Prevention'
@description('Managed rule set version (e.g. 3.2)')
param managedRuleSetVersion string = '3.2'
@description('Enable request body inspection.')
param requestBodyCheck bool = true
@description('Max request body size KB.')
param maxRequestBodySizeInKb int = 128
@description('File upload limit MB.')
param fileUploadLimitInMb int = 100

// Create only when not provided
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = if (empty(existingWafPolicyId)) {
  name: policyName
  location: location
  tags: tags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: mode
      requestBodyCheck: requestBodyCheck
      maxRequestBodySizeInKb: maxRequestBodySizeInKb
      fileUploadLimitInMb: fileUploadLimitInMb
    }
    customRules: []
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: managedRuleSetVersion
        }
      ]
      exclusions: []
      // disabledRuleGroups not supported in this API schema; future enhancement placeholder
    }
  }
}

var resolvedWafPolicyId = empty(existingWafPolicyId) ? wafPolicy.id : existingWafPolicyId

output wafPolicyId string = resolvedWafPolicyId
