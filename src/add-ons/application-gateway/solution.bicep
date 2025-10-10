// solution.bicep - Orchestrates Scenario A Application Gateway WAF_v2 before Firewall
// NOTE: Initial scaffold; resources not fully implemented yet.

@description('Azure region for deployment')
param location string
@description('Deployment name for resource tagging')
param deploymentName string
@description('Hub VNet resource ID where AppGateway subnet will reside')
param hubVnetResourceId string
@description('Azure Firewall resource ID used as next hop for UDR')
param firewallResourceId string
@description('Common default settings object applied to each app unless overridden')
param commonDefaults object
@description('Array of application definitions (listeners, backend targets, optional overrides)')
param apps array
@description('Tags to apply to all created resources')
param tags object = {}
@description('Existing WAF policy resource ID (if provided, skip creating new policy)')
param existingWafPolicyId string = ''

// TODO: derive firewall private IP via reuse of existing module (firewall-info.bicep) once referenced as a module.
// module firewallInfo 'firewall-info.bicep' = {
//   name: 'firewallInfo'
//   params: {
//     firewallResourceId: firewallResourceId
//   }
// }

// Ensure subnet
module appgwSubnet 'appgateway-subnet.bicep' = {
  name: 'appgwSubnet'
  params: {
    hubVnetResourceId: hubVnetResourceId
  }
}

// Route table (minimal)
module appgwRouteTable 'appgateway-route-table.bicep' = {
  name: 'appgwRouteTable'
  params: {
    location: location
    deploymentName: deploymentName
    tags: tags
  }
}

// WAF Policy (create only if not provided)
module wafPolicy 'appgateway-waf-policy.bicep' = if (existingWafPolicyId == '') {
  name: 'wafPolicy'
  params: {
    location: location
    commonDefaults: commonDefaults
    apps: apps
    tags: tags
  }
}

// Core App Gateway
module appgwCore 'appgateway-core.bicep' = {
  name: 'appgwCore'
  params: {
    location: location
    deploymentName: deploymentName
    subnetId: appgwSubnet.outputs.subnetId
    wafPolicyId: existingWafPolicyId != '' ? existingWafPolicyId : wafPolicy.outputs.wafPolicyId
    commonDefaults: commonDefaults
    apps: apps
    tags: tags
  }
}

output appGatewayResourceId string = appgwCore.outputs.appGatewayResourceId
output appGatewayPublicIp string = appgwCore.outputs.publicIpAddress
output wafPolicyResourceId string = existingWafPolicyId != '' ? existingWafPolicyId : wafPolicy.outputs.wafPolicyId
output listenerNames array = appgwCore.outputs.listenerNames
output backendPoolNames array = appgwCore.outputs.backendPoolNames
