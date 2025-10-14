// appgateway-nsg.bicep
// Creates a baseline NSG for the Application Gateway subnet

targetScope = 'resourceGroup'

@description('Azure region')
param location string
@description('NSG name')
param nsgName string
@description('Tags to apply')
param tags object = {}

@description('Additional outbound Azure service tags to allow (e.g. AzureKeyVault, AzureMonitor). Minimal required infrastructure service tags already included.')
param additionalAllowedOutboundServiceTags array = []

// Build outbound service tag allow rules list (dedupe)
var baseOutboundServiceTags = ['AzureKeyVault','AzureActiveDirectory','AzureMonitor']
var mergedOutboundServiceTags = [for (t,i) in concat(baseOutboundServiceTags, additionalAllowedOutboundServiceTags): indexOf(concat(baseOutboundServiceTags, additionalAllowedOutboundServiceTags), t) == i ? t : '']
var effectiveOutboundServiceTags = [for t in mergedOutboundServiceTags: !empty(t) ? t : '']

var outboundServiceTagRules = [for (t,i) in effectiveOutboundServiceTags: {
  name: 'AllowOutbound-${toLower(replace(t,'Azure',''))}'
  properties: {
    priority: 210 + i
    direction: 'Outbound'
    access: 'Allow'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: t
    destinationPortRange: '*'
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: concat([
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
        name: 'AllowGatewayManagerInfra'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [ '65200-65535' ]
        }
      }
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowVNetOutbound'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
        }
      }
    ], outboundServiceTagRules, [
      {
        name: 'DenyAllOutbound'
        properties: {
          priority: 4096
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ])
  }
}

output nsgId string = nsg.id
