// appgateway-waf-policy.bicep - Base WAF policy + custom rules aggregation
@description('Deployment location')
param location string
@description('Common defaults object used for WAF settings')
param commonDefaults object
@description('Apps array for aggregating custom rules')
param apps array
@description('Tags object')
param tags object = {}

// Placeholder output
output wafPolicyId string = 'PLACEHOLDER_WAF_POLICY_ID'
