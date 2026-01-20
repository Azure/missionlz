# Virtual Network Gateway Add-On

## Purpose

This add-on enables a Site-to-Site (S2S) VPN capability for a Mission Landing Zone (MLZ) hub with enforced inspection and egress control through Azure Firewall (forced tunneling). It is designed to be:

* Idempotent – safe to re-run for drift correction.
* Minimal – only required components (GatewaySubnet, VPN Gateway, Local Network Gateway, Connection, static route tables, firewall rules, diagnostics).
* Opinionated – static, firewall-centric routing (no BGP) for deterministic traffic flows.

## End State Summary

* Hub `GatewaySubnet` created or validated (CIDR auto-discovered or default fallback).
* Hub Virtual Network Gateway (active-active capable) deployed with chosen SKU (default `VpnGw2`).
* Two public IPs allocated for active-active configurations (module handles naming).
* Local Network Gateway representing on-premises endpoint (public IP + one or more on-prem CIDRs).
* Site-to-Site VPN Connection with a supplied or generated shared key (PSK).
* Dedicated route table for the VPN Gateway subnet (forced tunneling via Firewall private IP for hub + spoke prefixes).
* Hub route table receives explicit on-prem override routes to ensure traffic to on-prem is inspected (see Rationale below).
* VNet peerings (hub ↔ spokes) updated to allow gateway transit.
* Default Firewall Policy rule collection group `VGW-OnPrem` deployed unless custom groups are supplied.
* Diagnostics (AllLogs, AllMetrics) sent to the specified Log Analytics workspace.
* Spoke VNet address prefixes (from `virtualNetworkResourceIdList`) are added as static routes to the dedicated VPN Gateway route table (next hop = Firewall private IP) by default.
* On-prem address prefixes (from `localAddressPrefixes`) are added as static override routes to the hub route table (next hop = Firewall) enforcing inspection.
* Default firewall rules (in `VGW-OnPrem`) allow spoke ↔ on-prem traffic for those prefixes unless overridden by `customFirewallRuleCollectionGroups`.
* Default firewall rules also allow on-prem ↔ Azure hub/spoke traffic for configured on-prem prefixes unless overridden.

## Architecture & Routing Rationale

Without explicit static routes, Azure system routing could prefer the virtual network gateway directly for on-prem prefixes from hub workloads. By inserting on-prem CIDR routes in the hub route table pointing to the Firewall (next hop = virtual appliance / firewall private IP), we enforce packet inspection and consistent egress policy before packets reach the VPN tunnel.

Key points:

* Spoke prefixes added to the dedicated VPN Gateway route table ensure that traffic entering the gateway path is forced through the firewall.
* Hub prefixes are also added to the VPN Gateway route table to maintain symmetrical forced tunneling.
* Local (on-prem) prefixes added to the hub route table guarantee hub workloads egress to on-prem only after firewall policy evaluation.
* Adding a spoke VNet automatically establishes static routes for its CIDRs and default firewall permissions to on-prem; minimal friction for initial connectivity tests.
* Adding an on-prem prefix updates: (1) Local Network Gateway; (2) hub override routes; (3) default firewall allow rules for bidirectional traffic.
* BGP is deliberately disabled – all routing is static to eliminate route ambiguity and prevent unintentional bypass around the firewall.

## Parameters (solution.bicep)

| Parameter | Description | Notes |
|-----------|-------------|-------|
| `hubVirtualNetworkResourceId` | Resource ID of the hub VNet. | Must exist prior to add-on deployment. |
| `operationsLogAnalyticsWorkspaceResourceId` | Log Analytics workspace for diagnostics. | Ensure workspace is accessible in same tenant. |
| `virtualNetworkResourceIdList` | Array of spoke VNet resource IDs to enable gateway transit. | Exclude the hub VNet itself. |
| (Behavior: Spokes) | Each spoke's CIDRs automatically gain static routes & default allow firewall rules to on-prem. | Provide custom rule groups to restrict. |
| `localAddressPrefixes` | On-prem CIDR prefixes reachable over the S2S tunnel. | Used for Local Network Gateway and hub override routes. |
| (Behavior: On-Prem) | Each on-prem prefix added to hub override routes & default firewall allow rules to hub + spokes. | Override to narrow/deny access. |
| `localGatewayIpAddress` | Public IP of the on-prem VPN device. | Must be reachable from Azure; typically static. |
| `sharedKey` | PSK for the VPN connection (secure param). | If omitted template generates a GUID – recommend replacing with a high-entropy secret. |
| `virtualNetworkGatewaySku` | Gateway SKU (`VpnGw2`..`VpnGw5`). | Choose based on throughput & tunnels required. |
| `customFirewallRuleCollectionGroups` | Optional override of default firewall rule collection group. | Empty array uses opinionated default rules. |

### Recommended Shared Key Practice

Use a 256-bit random value (Base64 or hex) rather than a GUID. Rotate periodically. Store only in secure locations (Key Vault, pipeline variable groups). Do not commit PSKs to source control.

## Security Considerations

* All traffic between spokes/on-prem is inspected through Azure Firewall due to static routes enforcing the firewall next hop.
* No credentials (other than the PSK) are required; PSK handled as a secure parameter.
* No BGP – reduces attack surface and prevents accidental route injection.
* Firewall Policy provides central logging, threat intelligence, and rule governance.
* Diagnostics to Log Analytics enable auditing of gateway operations (track negotiation events, bandwidth usage).
* Default permit model: unless custom rule groups are supplied, hub + spoke ↔ on-prem traffic matching provided prefixes is allowed (and inspected). Supply `customFirewallRuleCollectionGroups` to tighten scope.

## Operational Tasks

| Task | Approach |
|------|---------|
| Rotate PSK | Redeploy with new `sharedKey`; update on-prem device first or schedule simultaneous change window. |
| Add on-prem prefix | Append CIDR to `localAddressPrefixes`; redeploy (idempotent update) and then add matching selector on on-prem device. |
| Expand spokes | Add spoke VNet ID to `virtualNetworkResourceIdList`; redeploy; routes & peerings update automatically. |
| Restrict a spoke's on-prem access | Provide a custom rule collection group omitting that spoke's CIDRs or adding deny rules; redeploy. |
| Restrict on-prem ↔ hub/spoke flows | Supply custom firewall rule collection groups without broad allow rules; redeploy. |
| Reset gateway | Use `az network vnet-gateway reset` (transient downtime). |
| Remove add-on | Delete connection, local network gateway, gateway subnet route associations, and (optionally) public IPs; remove firewall rule group if no longer needed. |

## Limitations

* No dynamic route propagation (BGP disabled) – manual updates required for new on-prem prefixes.
* Active-active gateway deployed but template does not orchestrate ECMP verification; monitor both tunnels for SLA.
* Route aggregation not automatic – if many spoke VNets are added, consider summarizing CIDRs manually where possible.
* No NAT rules included – if overlapping address spaces are required, additional modules must be added.
* Assumes Azure Firewall already exists in hub and has a private IP configuration accessible in the template.
* Default on-prem ↔ Azure allow rules mean segmentation requires explicit override; absence of custom groups yields broad connectivity limited only by specified prefixes.

## Troubleshooting Tips

| Symptom | Possible Cause | Action |
|---------|----------------|--------|
| Connection status = Unknown | PSK mismatch or inverted Local Network Gateway prefixes | Verify PSK, ensure LNG lists on-prem (not Azure) prefixes. |
| No bytes transferred | No interesting traffic / selectors mismatch | Generate traffic (ICMP), check on-prem phase 2 selectors. |
| Firewall denies on-prem ↔ spoke | Missing custom rule collection overrides | Supply `customFirewallRuleCollectionGroups` or adjust default group. |
| Route not enforced | Route table association missing | Confirm GatewaySubnet has dedicated route table; check effective routes. |
| Spoke unexpectedly reaches on-prem | Default permit behavior active | Replace default rule collection with restrictive custom rules. |
| On-prem unexpectedly reaches hub subnet | Default permit still active | Introduce custom rule collection groups with explicit allow/deny entries. |

## Deployment Options

* [Azure Portal](docs/portal.md)
* [Command Line Tools - Azure CLI or PowerShell](docs/command-line-tools.md)

## References

* [VPN gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
* [Local network gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)
* [Azure Firewall Policy](https://learn.microsoft.com/azure/firewall/policy-overview)
* [Diagnostic settings](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings)
* [VNet peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)

---
Revision note: Documentation expanded to clarify forced tunneling rationale, mandatory hub route overrides, parameters, security, operations, limitations, troubleshooting, and default behaviors for routes & firewall rules.

## Custom Firewall Rule Example (Override Default Permits)

If you want to restrict traffic so that only HTTPS (TCP/443) from on-prem to a specific spoke address prefix is allowed (and remove the broad default Any/Any permits), supply a `customFirewallRuleCollectionGroups` array with one or more objects. Each object must contain a `name` and `properties` matching the firewall policy schema for rule collection groups.

Example parameter value (conceptual) for `customFirewallRuleCollectionGroups` in a parameters file:

```json
"customFirewallRuleCollectionGroups": [
  {
    "name": "VGW-Custom-443",
    "properties": {
      "priority": 245,
      "ruleCollections": [
        {
          "name": "AllowOnPremToSpoke443",
          "priority": 130,
          "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
          "action": { "type": "Allow" },
          "rules": [
            {
              "name": "AllowOnPremToSpoke-HTTPS",
              "ruleType": "NetworkRule",
              "ipProtocols": ["Tcp"],
              "sourceAddresses": ["198.51.100.10", "198.51.100.11"],
              "destinationAddresses": ["10.2.0.0/16"],
              "destinationPorts": ["443"],
              "sourceIpGroups": [],
              "destinationIpGroups": [],
              "destinationFqdns": []
            }
          ]
        }
      ]
    }
  }
]
```

Notes:

* Replace `198.51.100.10` / `198.51.100.11` with your real on-prem source IPs or CIDR ranges.
* Replace `10.2.0.0/16` with the target spoke VNet prefix you want to allow.
* Omitting reverse (spoke→on-prem) rules means return traffic may be denied; typically add a complementary rule collection for egress if bidirectional flow is required.
* By supplying this custom group, the template will NOT deploy the default `VGW-OnPrem` broad allow group.
* You can add a second rule collection with `action: { "type": "Deny" }` and higher priority number (lower numeric value) to block other ports explicitly before an allow collection if needed.

Minimal bi-directional HTTPS example (two collections) conceptually:

```json
"ruleCollections": [
  {
    "name": "AllowOnPremToSpoke443",
    "priority": 130,
    "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
    "action": { "type": "Allow" },
    "rules": [
      {
        "name": "OnPremToSpoke443",
        "ruleType": "NetworkRule",
        "ipProtocols": ["Tcp"],
        "sourceAddresses": ["198.51.100.0/24"],
        "destinationAddresses": ["10.2.0.0/16"],
        "destinationPorts": ["443"],
        "sourceIpGroups": [],
        "destinationIpGroups": [],
        "destinationFqdns": []
      }
    ]
  },
  {
    "name": "AllowSpokeToOnPrem443",
    "priority": 131,
    "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
    "action": { "type": "Allow" },
    "rules": [
      {
        "name": "SpokeToOnPrem443",
        "ruleType": "NetworkRule",
        "ipProtocols": ["Tcp"],
        "sourceAddresses": ["10.2.0.0/16"],
        "destinationAddresses": ["198.51.100.0/24"],
        "destinationPorts": ["443"],
        "sourceIpGroups": [],
        "destinationIpGroups": [],
        "destinationFqdns": []
      }
    ]
  }
]
```

Priority Guidance:

* Lower numeric `priority` inside a rule collection group executes first (Azure Firewall evaluates collection priority before rule order inside that collection).
* Keep bi-directional pairs adjacent and separated from broader rules.
* If adding Deny rules, assign them a lower numeric priority than related Allow rules.

This sample shows explicit IP/CIDR values instead of template parameters – appropriate when a customer has fixed, known ranges and prefers not to expose them via parameters.

### Minimal Sample Parameters File Snippet

Below is a minimal `solution.bicepparam` snippet demonstrating how to pass custom firewall rule collection groups along with required core parameters:

```bicep-params
using './solution.bicep'

param hubVirtualNetworkResourceId = '/subscriptions/<subId>/resourceGroups/<hub-rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>'
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/<subId-ops>/resourceGroups/<ops-rg>/providers/Microsoft.OperationalInsights/workspaces/<ops-law>'
param virtualNetworkResourceIdList = [
  '/subscriptions/<subId-spoke1>/resourceGroups/<rg-spoke1>/providers/Microsoft.Network/virtualNetworks/<spoke1-vnet>'
]
param localAddressPrefixes = [ '10.50.0.0/16' ]
param localGatewayIpAddress = '203.0.113.10'

// Custom firewall rule collection group overriding defaults (HTTPS only on-prem -> spoke)
param customFirewallRuleCollectionGroups = [
  {
    name: 'VGW-Custom-443'
    properties: {
      priority: 245
      ruleCollections: [
        {
          name: 'OnPremToSpoke443'
          priority: 130
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: { type: 'Allow' }
          rules: [
            {
              name: 'OnPremToSpoke-HTTPS'
              ruleType: 'NetworkRule'
              ipProtocols: [ 'Tcp' ]
              sourceAddresses: [ '203.0.113.0/24' ]
              destinationAddresses: [ '10.2.0.0/16' ]
              destinationPorts: [ '443' ]
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: []
            }
          ]
        }
      ]
    }
  }
]
```

### Deny-Before-Allow Example

To explicitly block all on-prem to spoke traffic except HTTPS, add a Deny rule collection with lower numeric priority (executes first). Example fragment for the `ruleCollections` array inside a group:

```jsonc
[
  {
    "name": "DenyOnPremToSpokeAllBut443",
    "priority": 129,
    "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
    "action": { "type": "Deny" },
    "rules": [
      {
        "name": "DenyOnPremToSpoke-NonHTTPS",
        "ruleType": "NetworkRule",
        "ipProtocols": ["Any"],
        "sourceAddresses": ["203.0.113.0/24"],
        "destinationAddresses": ["10.2.0.0/16"],
        "destinationPorts": ["*"],
        "sourceIpGroups": [],
        "destinationIpGroups": [],
        "destinationFqdns": []
      }
    ]
  },
  {
    "name": "AllowOnPremToSpoke443",
    "priority": 130,
    "ruleCollectionType": "FirewallPolicyFilterRuleCollection",
    "action": { "type": "Allow" },
    "rules": [
      {
        "name": "OnPremToSpoke443",
        "ruleType": "NetworkRule",
        "ipProtocols": ["Tcp"],
        "sourceAddresses": ["203.0.113.0/24"],
        "destinationAddresses": ["10.2.0.0/16"],
        "destinationPorts": ["443"],
        "sourceIpGroups": [],
        "destinationIpGroups": [],
        "destinationFqdns": []
      }
    ]
  }
]
```

Implementation notes:

* Priority 129 (Deny) executes before 130 (Allow) ensuring only HTTPS is permitted.
* Avoid overlapping broad Allow collections after a targeted Deny unless intentionally layered.
* Use jsonc (comment-able JSON) form during design; remove comments for production parameter files.
