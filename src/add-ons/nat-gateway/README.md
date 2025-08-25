# NAT Gateway add-on (Mission Landing Zone)

## Purpose

Deploy an Azure NAT Gateway and attach it only to the Hub virtual network's AzureFirewallSubnet. Minimal inputs, idempotent behavior, and naming aligned with Mission LZ.

Creates:

- Standard Public IP Prefix (size you choose)
- Standard NAT Gateway (optional zone)
- Subnet update to associate NAT GW to AzureFirewallSubnet while preserving NSG, UDR, delegations, endpoints, and policies

Naming is provided by the shared naming-convention module.

## When to use

- Deterministic outbound SNAT for traffic egressing via the hub/firewall
- Bounded egress IP range (Public IP Prefix) for allowlisting
- Simple, repeatable deployment that only touches AzureFirewallSubnet

Notes

- Subscription-scope deployment; Azure Government friendly
- Location and names derive from the Hub VNet

## Parameters (solution.bicep)

- hubVirtualNetworkResourceId (string, required)
  - Resource ID of the Hub VNet that contains AzureFirewallSubnet
  - Example: `/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>`
- zone (string, optional; default: '')
  - NAT Gateway zone. Allowed: '', '1', '2', '3' ('' = regional)
- tcpIdleTimeout (int, optional; default: 4; min 4, max 120)
  - TCP idle timeout (minutes) on the NAT Gateway
- publicIpPrefixLength (int, optional; default: 30)
  - Public IP Prefix size. Azure NAT Gateway supports /28 to /31
- deploymentNameSuffix (string, optional; default: utcNow())
  - Suffix used for unique deployment/module names

## What it changes

- Creates a Standard Public IP Prefix and Standard NAT Gateway in the Hub RG
- Associates NAT Gateway with Hub's AzureFirewallSubnet only
- Preserves existing subnet configuration (NSG, UDR, delegations, endpoints, policies)
  - privateEndpointNetworkPolicies is disabled if currently enabled (typical hub pattern)

## Prerequisites

- Hub VNet with a subnet named AzureFirewallSubnet
- Quota for Public IP Prefix in the chosen region/subscription
- Permissions to deploy at subscription scope and to the Hub RG

## How to deploy

Example parameter file (`src/add-ons/nat-gateway/solution.bicepparam`):

```bicep-params
using './solution.bicep'

param hubVirtualNetworkResourceId = '/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>'
param zone = '1'
param tcpIdleTimeout = 4
param publicIpPrefixLength = 30
```

Deploy (subscription scope):

```powershell
# Optional: what-if
az deployment sub what-if `
  --name natgw-whatif `
  --location usgovvirginia `
  --template-file src/add-ons/nat-gateway/solution.bicep `
  --parameters src/add-ons/nat-gateway/solution.bicepparam

# Create
az deployment sub create `
  --name natgw-deploy `
  --location usgovvirginia `
  --template-file src/add-ons/nat-gateway/solution.bicep `
  --parameters src/add-ons/nat-gateway/solution.bicepparam
```

Adjust the region to your cloud (e.g., usgovvirginia, usgovarizona).

## Validation

You should see in the Hub RG:

- NAT Gateway (name from naming-convention)
- Public IP Prefix
- AzureFirewallSubnet with `natGateway.id` set to the deployed NAT Gateway

Optional CLI check:

```powershell
az network vnet subnet show `
  --resource-group <hub-rg> `
  --vnet-name <hub-vnet> `
  --name AzureFirewallSubnet `
  --query "natGateway.id" -o tsv
```

## Cleanup

```powershell
# Delete NAT Gateway (detaches from subnet)
az network nat gateway delete --name <natgw-name> --resource-group <hub-rg> --yes

# Delete Public IP Prefix
az network public-ip prefix delete --name <pip-prefix-name> --resource-group <hub-rg> --yes
```

To detach without deleting NAT Gateway, update the subnet to remove its natGateway reference via portal or a small template.

## Files

- `solution.bicep` — Entry point; derives Hub VNet/Firewall subnet, creates NAT GW + PIP Prefix, and attaches to AzureFirewallSubnet
- `modules/nat-gateway.bicep` — Creates Public IP Prefix and NAT Gateway
- `modules/get-subnetinfo.bicep` — Reads current properties of AzureFirewallSubnet for safe updates
- `modules/attach-natgw-to-subnet.bicep` — Updates the subnet to attach the NAT Gateway while preserving settings
