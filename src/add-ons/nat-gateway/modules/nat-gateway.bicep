@description('Resource ID of the hub firewall. Used to derive the resource group and VNet for deployment.')
param hubFirewallResourceId string

@description('Azure region for deployment.')
param location string

@description('Zone for deployment. Use "" for no zone, or "1", "2", "3" for specific zones.')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param zone string = ''

@description('Name for the NAT Gateway. Should be generated using the existing naming convention module.')
param natGatewayName string

@description('TCP idle timeout in minutes.')
@minValue(4)
@maxValue(120)
param tcpIdleTimeout int = 4

@description('The length of the public IP prefix to allocate for outbound connections. Must be /30 for two usable IPs.')
param publicIpPrefixLength int = 30

@description('The name for the public IP prefix resource.')
param publicIpPrefixName string = '${natGatewayName}-prefix'

// Derive the resource group name from the firewall resource ID
var resourceGroupName = split(hubFirewallResourceId, '/')[4]

// Zone array for resources (empty array if no zone specified)
var zoneArray = zone == '' ? [] : [zone]

// Create the public IP prefix in the same zone
resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2023-04-01' = {
  name: publicIpPrefixName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: zoneArray
  properties: {
    prefixLength: publicIpPrefixLength
    publicIPAddressVersion: 'IPv4'
  }
}

// Deploy the NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: zoneArray
  properties: {
    publicIpPrefixes: [
      {
        id: publicIpPrefix.id
      }
    ]
    idleTimeoutInMinutes: tcpIdleTimeout
  }
}

// Output only what you know here; do not try to get addressPrefix
output natGatewayId string = natGateway.id
output publicIpPrefixId string = publicIpPrefix.id
output resourceGroupName string = resourceGroupName
