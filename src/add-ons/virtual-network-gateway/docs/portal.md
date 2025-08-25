# Virtual Network Gateway Add-On

## Deployment Guide - Azure Portal

| Cloud  | Deployment Button |
| :----- | :----- |
| Azure Commercial | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fmlz.uiDefinition.json) |
| Azure Government |  [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fmlz.uiDefinition.json) |

## Cleanup

> [!IMPORTANT]
> Expect a brief connectivity interruption during teardown. Plan a maintenance window.
> Some steps depend on others (e.g., disassociate a route table before deleting it).

1) Firewall Policy rules

- If you used the default rules (no customFirewallRuleCollectionGroups):
  - Navigate to Firewall Policy > Rule collection groups
  - Delete the group named “VGW‑OnPrem”
- If you supplied customFirewallRuleCollectionGroups:
  - Remove the custom group(s) you created for VGW/on‑prem connectivity

2) Route tables and routes

Hub GatewaySubnet association (must be first in this section)

- Hub VNet > Subnets > GatewaySubnet > Route table: Disassociate

VGW route table (created by this add‑on)

- In Route tables, locate the table previously associated to GatewaySubnet
- Open Routes and note/remove routes pointing to the Azure Firewall private IP (next hop = Virtual appliance)
- Delete the route table after disassociation

Existing hub/workload route tables (only if includeHubOnPrem = true)

- For each hub route table you manage (e.g., workload subnets):
  - Remove on‑prem override routes the add‑on created (destination in localAddressPrefixes; next hop = Firewall private IP)

Spoke route tables

- This add‑on does not modify spoke UDRs by default. If you added any spoke UDRs to support testing, remove as needed.

3) VNet peering updates

- Hub VNet > Peerings > For each peering to a Spoke: uncheck “Allow gateway transit”
- Spoke VNet > Peerings > Peering to Hub: uncheck “Use remote gateway” (and “Allow forwarded traffic” if you enabled it for testing)
- Save each peering update

4) VPN resources

- In the Hub resource group:
  - Delete the VPN Connection
  - Delete the Local Network Gateway
  - Delete the Virtual Network Gateway (confirm it is no longer associated to any connections)
  - Delete the public IP resources created for the VGW if dedicated to this gateway

5) Optional subnet cleanup

- If “GatewaySubnet” was created only for this add‑on and is no longer needed, delete it after the VGW is removed

6) Validate

- Confirm hub/spoke traffic flows still meet your baseline (e.g., through Azure Firewall for east‑west)
- Verify no orphaned UDRs/peerings remain
