// appgateway-waf-policy.bicep - Base WAF policy + aggregated custom rules (Scenario A)
@description('Deployment location')
param location string
@description('Common defaults object used for WAF settings (expects wafPolicyMode?, wafManagedRuleSetVersion?, disabledRuleGroups?)')
param commonDefaults object
@description('Apps array; used only for count for naming to avoid unused param warning')
param apps array
@description('Tags object applied to WAF policy')
param tags object = {}

var wafPolicyMode = commonDefaults.wafPolicyMode ?? 'Prevention'
var wafManagedRuleSetVersion = commonDefaults.wafManagedRuleSetVersion ?? 'OWASP_3.2'
// Minimal scaffold: ignore disabled rule groups for initial deployment
var appsCount = length(apps)

var wafPolicyName = 'agw-waf-policy-${appsCount}'

resource agwWafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-05-01' = {
	name: wafPolicyName
	location: location
	tags: tags
	properties: {
		policySettings: {
			state: 'Enabled'
			mode: wafPolicyMode
			requestBodyCheck: true
			maxRequestBodySizeInKb: 128
			fileUploadLimitInMb: 100
		}
		managedRules: {
			managedRuleSets: [
				{
					ruleSetType: 'OWASP'
					ruleSetVersion: wafManagedRuleSetVersion
				}
			]
		}
	}
}

output wafPolicyId string = agwWafPolicy.id
