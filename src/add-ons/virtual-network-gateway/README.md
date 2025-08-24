# Virtual Network Gateway add-on (Mission Landing Zone)

## Purpose

Provides a minimal, idempotent way to enable Site‑to‑Site VPN for a Mission LZ hub, steering traffic through Azure Firewall and updating hub/spoke peerings and routes with as few inputs as possible.

## Default end state

- GatewaySubnet ensured in the Hub VNet (creates/updates if missing)
- Dedicated route table created and associated to GatewaySubnet (VGW route table)
- Routes in the VGW route table send all Spoke CIDRs to the Azure Firewall private IP
- Optional (toggle): add Hub CIDRs and On‑Prem CIDRs to VGW RT to force firewall path
- Hub and Spoke peerings updated so Spokes use the Hub VPN gateway
- Resources created/updated: Virtual Network Gateway (VpnGw SKU), Local Network Gateway, VPN Connection (shared key)
- Firewall Policy default rule collection group “VGW‑OnPrem” allowing On‑Prem ↔ Spokes; optional Hub ↔ On‑Prem allow rules

## Required parameters

- hubVirtualNetworkResourceId (string)
  - Hub VNet resource ID. Must already contain an AzureFirewallSubnet with an Azure Firewall.
- virtualNetworkResourceIdList (array)
  - Resource IDs of Spoke VNets that should use the Hub VPN gateway.
- localAddressPrefixes (array)
  - On‑prem CIDR prefixes routable via S2S (e.g., ["10.1.0.0/16", "10.2.0.0/16"]).
- localGatewayIpAddress (string)
  - Public IP of the on‑prem VPN device.
- sharedKey (secureString)
  - Pre‑shared key used for the VPN connection.

## Optional parameters

- virtualNetworkGatewaySku (string, default VpnGw2)
  - Allowed: VpnGw2, VpnGw3, VpnGw4, VpnGw5.
- customFirewallRuleCollectionGroups (array, default [])
  - When non‑empty, overrides the default VGW‑OnPrem rule group entirely.
- includeHubOnPrem (bool, default false)
  - When true, adds Hub ↔ On‑Prem allow rules and corresponding hub/on‑prem override routes via the firewall.
- deploymentNameSuffix (string, default utcNow())
  - Suffix used for module/deployment names.

## Complex parameter example: custom firewall rules override

Provide your own Firewall Policy rule collection groups to fully control rules. When supplied, the default VGW‑OnPrem group is not created.

```bicep
param customFirewallRuleCollectionGroups array = [
  {
    name: 'VGW-Custom'
    properties: {
      priority: 245
      ruleCollections: [
        {
          name: 'Allow-OnPrem-To-Spokes'
          priority: 130
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: { type: 'Allow' }
          rules: [
            {
              name: 'onprem-to-hub-and-spokes'
              ruleType: 'NetworkRule'
              ipProtocols: ['Any']
              sourceAddresses: ['10.1.0.0/16', '10.2.0.0/16']
              destinationAddresses: [
                // Hub + Spoke CIDRs you intend to allow
                '10.10.0.0/16', '10.20.0.0/16'
              ]
              destinationPorts: ['*']
            }
          ]
        }
      ]
    }
  }
]
```

Notes

- Ensure rule collection priorities don’t collide with existing Firewall Policy collections.
- If you need Hub ↔ On‑Prem rules with the default group, set includeHubOnPrem to true instead of supplying a full override.

## Build and use

- Build Bicep to JSON
  - az bicep build --file src/add-ons/virtual-network-gateway/solution.bicep --outfile src/add-ons/virtual-network-gateway/solution.json
- Deploy via Template Spec/Portal
  - Use uiDefinition.json to pick Hub/Spokes via dropdowns and enter on‑prem details. The UI is compatible with Azure Government (no external schema references).

## References

- [VPN gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
- [Local network gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)
- [Azure Firewall Policy](https://learn.microsoft.com/azure/firewall/policy-overview)
- [Route tables (UDR)](https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
- [VNet peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
