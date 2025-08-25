# Virtual Network Gateway Add-On

The Virtual Network Gateway add-on provides a minimal, idempotent way to enable a Site‑to‑Site VPN for a Mission Landing Zone hub. Traffic is steered through the Azure Firewall. Peerings are updated to enable gateway connectivity from the spokes. The following list provides the end state for the deployment:

- GatewaySubnet is created or updated in the Hub virtual network
- Dedicated route table created and associated to GatewaySubnet
  - Spoke CIDRs route to the Azure Firewall private IP
  - Optional: Hub CIDRs and On‑Prem CIDRs route to the Azure Firewall
- Peerings are updated to use the Hub VPN gateway
- Resources are created or updated:
  - Virtual Network Gateway (VpnGw SKU)
  - Local Network Gateway
  - VPN Connection (shared key)
  - Firewall Policy default rule collection group “VGW‑OnPrem” allowing On‑Prem ↔ Spokes; optional Hub ↔ On‑Prem allow rules
  - Virtual Network Gateway diagnostic settings send AllLogs and AllMetrics to the Operations Log Analytics workspace
  - Shared key defaults to a generated GUID if not provided

## Deployment Options

- [Azure Portal](docs/portal.md)
- [Command Line Tools - Azure CLI or PowerShell](docs/command-line-tools.md)

## References

- [VPN gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
- [Local network gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)
- [Azure Firewall Policy](https://learn.microsoft.com/azure/firewall/policy-overview)
- [Diagnostic settings](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings)
- [VNet peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
