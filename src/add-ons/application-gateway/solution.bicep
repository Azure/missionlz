// solution.bicep - Orchestrates Scenario A Application Gateway WAF_v2 before Firewall
// NOTE: Initial scaffold; resources not fully implemented yet.

@description('Azure region for deployment')
param location string
@description('Deployment name for resource tagging')
param deploymentName string
@description('Hub VNet resource ID where AppGateway subnet will reside')
param hubVnetResourceId string
@description('Address prefix to allocate for the Application Gateway subnet (must be within hub VNet address space and unused). Must be /24-/16 for v2 SKU.')
param appGatewaySubnetAddressPrefix string = '10.0.129.0/24'
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
@description('Firewall private IP for default route next hop (required for route table).')
param firewallPrivateIp string = ''
@description('Whether to create and associate an NSG to the App Gateway subnet.')
param createSubnetNsg bool = true

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
    firewallPrivateIp: firewallPrivateIp
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

// Network Security Group (optional) for App Gateway subnet - allow outbound to backend, inbound from Internet only via Gateway, deny unexpected
resource appgwSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = if (createSubnetNsg) {
  name: '${deploymentName}-appgw-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Placeholder baseline rules; to refine in later hardening pass
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowInternetOutbound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowVNetOutbound'
        properties: {
          priority: 210
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// Associate NSG & Route Table to subnet (must re-declare existing subnet resource with updated properties)
resource appGatewaySubnetAssoc 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (createSubnetNsg || true) {
  name: appGatewaySubnetName
  parent: hubVnetExisting
  properties: {
    addressPrefix: appGatewaySubnetAddressPrefix
    networkSecurityGroup: createSubnetNsg ? {
      id: appgwSubnetNsg.id
    } : null
    routeTable: {
      id: appgwRouteTable.outputs.routeTableId
    }
  }
  dependsOn: [
    appgwSubnet
  ]
}

// Existing hub VNet reference for association
var hubVnetName = last(split(hubVnetResourceId, '/'))
resource hubVnetExisting 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: hubVnetName
}

output appGatewayResourceId string = appgwCore.outputs.appGatewayResourceId
output appGatewayPublicIp string = appgwCore.outputs.publicIpAddress
output wafPolicyResourceId string = effectiveWafPolicyId
output listenerNames array = appgwCore.outputs.listenerNames
output backendPoolNames array = appgwCore.outputs.backendPoolNames
