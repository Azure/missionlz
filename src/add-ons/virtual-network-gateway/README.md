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

## Architecture & Routing Rationale

Without explicit static routes, Azure system routing could prefer the virtual network gateway directly for on-prem prefixes from hub workloads. By inserting on-prem CIDR routes in the hub route table pointing to the Firewall (next hop = virtual appliance / firewall private IP), we enforce packet inspection and consistent egress policy before packets reach the VPN tunnel.

Key points:
 
* Spoke prefixes added to the dedicated VPN Gateway route table ensure that traffic entering the gateway path is forced through the firewall.
* Hub prefixes are also added to the VPN Gateway route table to maintain symmetrical forced tunneling.
* Local (on-prem) prefixes added to the hub route table guarantee hub workloads egress to on-prem only after firewall policy evaluation.
* BGP is deliberately disabled – all routing is static to eliminate route ambiguity and prevent unintentional bypass around the firewall.

## Parameters (solution.bicep)

| Parameter | Description | Notes |
|-----------|-------------|-------|
| `hubVirtualNetworkResourceId` | Resource ID of the hub VNet. | Must exist prior to add-on deployment. |
| `operationsLogAnalyticsWorkspaceResourceId` | Log Analytics workspace for diagnostics. | Ensure workspace is accessible in same tenant. |
| `virtualNetworkResourceIdList` | Array of spoke VNet resource IDs to enable gateway transit. | Exclude the hub VNet itself. |
| `localAddressPrefixes` | On-prem CIDR prefixes reachable over the S2S tunnel. | Used for Local Network Gateway and hub override routes. |
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

## Operational Tasks

| Task | Approach |
|------|---------|
| Rotate PSK | Redeploy with new `sharedKey`; update on-prem device first or schedule simultaneous change window. |
| Add on-prem prefix | Append CIDR to `localAddressPrefixes`; redeploy (idempotent update) and then add matching selector on on-prem device. |
| Expand spokes | Add spoke VNet ID to `virtualNetworkResourceIdList`; redeploy; routes & peerings update automatically. |
| Reset gateway | Use `az network vnet-gateway reset` (transient downtime). |
| Remove add-on | Delete connection, local network gateway, gateway subnet route associations, and (optionally) public IPs; remove firewall rule group if no longer needed. |

## Limitations

* No dynamic route propagation (BGP disabled) – manual updates required for new on-prem prefixes.
* Active-active gateway deployed but template does not orchestrate ECMP verification; monitor both tunnels for SLA.
* Route aggregation not automatic – if many spoke VNets are added, consider summarizing CIDRs manually where possible.
* No NAT rules included – if overlapping address spaces are required, additional modules must be added.
* Assumes Azure Firewall already exists in hub and has a private IP configuration accessible in the template.

## Troubleshooting Tips

| Symptom | Possible Cause | Action |
|---------|----------------|--------|
| Connection status = Unknown | PSK mismatch or inverted Local Network Gateway prefixes | Verify PSK, ensure LNG lists on-prem (not Azure) prefixes. |
| No bytes transferred | No interesting traffic / selectors mismatch | Generate traffic (ICMP), check on-prem phase 2 selectors. |
| Firewall denies on-prem ↔ spoke | Missing custom rule collection overrides | Supply `customFirewallRuleCollectionGroups` or adjust default group. |
| Route not enforced | Route table association missing | Confirm GatewaySubnet has dedicated route table; check effective routes. |

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
Revision note: Documentation expanded to clarify forced tunneling rationale, mandatory hub route overrides, parameters, security, operations, limitations, and troubleshooting.

