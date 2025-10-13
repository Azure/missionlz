// solution.bicep - Orchestrates Scenario A Application Gateway WAF_v2 before Firewall
// NOTE: Initial scaffold; resources not fully implemented yet.

@description('Azure region for deployment')
param location string
@description('Deployment name for resource tagging')
param deploymentName string
@description('Hub VNet resource ID where AppGateway subnet will reside')
param hubVnetResourceId string
@description('Address prefix to allocate for the Application Gateway subnet (must be within hub VNet address space and unused).')
param appGatewaySubnetAddressPrefix string = '10.0.129.0/25'
@description('Subnet name for the Application Gateway.')
param appGatewaySubnetName string = 'AppGateway'
@description('Common default settings object applied to each app unless overridden')
param commonDefaults object
@description('Array of application definitions (listeners, backend targets, optional overrides)')
param apps array
@description('Tags to apply to all created resources')
param tags object = {}
@description('Existing WAF policy resource ID (if provided, skip creating new policy)')
param existingWafPolicyId string = ''

// TODO (future): Add route table routes pointing 0.0.0.0/0 to Firewall private IP once module available.

// Ensure subnet
module appgwSubnet 'appgateway-subnet.bicep' = {
  name: 'appgwSubnet'
  params: {
    hubVnetResourceId: hubVnetResourceId
    subnetName: appGatewaySubnetName
    addressPrefix: appGatewaySubnetAddressPrefix
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

// Safely compose effective WAF policy id without direct module output access in param map
// Resolve WAF policy ID (warning for conditional module output access may appear)
var effectiveWafPolicyId = existingWafPolicyId != '' ? existingWafPolicyId : wafPolicy.outputs.wafPolicyId



// Core App Gateway
module appgwCore 'appgateway-core.bicep' = {
  name: 'appgwCore'
  params: {
    location: location
    deploymentName: deploymentName
    subnetId: appgwSubnet.outputs.subnetId
  wafPolicyId: effectiveWafPolicyId
    commonDefaults: commonDefaults
    apps: apps
    tags: tags
  }
}

output appGatewayResourceId string = appgwCore.outputs.appGatewayResourceId
output appGatewayPublicIp string = appgwCore.outputs.publicIpAddress
output wafPolicyResourceId string = effectiveWafPolicyId
output listenerNames array = appgwCore.outputs.listenerNames
output backendPoolNames array = appgwCore.outputs.backendPoolNames
