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
- Virtual Network Gateway diagnostic settings send AllLogs and AllMetrics to the Operations Log Analytics workspace
- Shared key defaults to a generated GUID if not provided

## Required parameters

- hubVirtualNetworkResourceId (string)
  - Hub VNet resource ID. Must already contain an AzureFirewallSubnet with an Azure Firewall.
- operationsLogAnalyticsWorkspaceResourceId (string)
  - Resource ID of the Operations Log Analytics Workspace where VGW diagnostics will be sent. Example: `/subscriptions/<subId>/resourceGroups/<ops-rg>/providers/Microsoft.OperationalInsights/workspaces/<ops-law>`
- virtualNetworkResourceIdList (array)
  - Resource IDs of Spoke VNets that should use the Hub VPN gateway.
- localAddressPrefixes (array)
  - On‑prem CIDR prefixes routable via S2S (e.g., ["10.1.0.0/16", "10.2.0.0/16"]).
- localGatewayIpAddress (string)
  - Public IP of the on‑prem VPN device.
- sharedKey (secureString)
  - Pre‑shared key used for the VPN connection. If omitted, a random GUID is generated.

## Optional parameters

- virtualNetworkGatewaySku (string, default VpnGw2)
  - Allowed: VpnGw2, VpnGw3, VpnGw4, VpnGw5.
- customFirewallRuleCollectionGroups (array, default [])
  - When non‑empty, overrides the default VGW‑OnPrem rule group entirely.
- includeHubOnPrem (bool, default false)
  - When true, adds Hub ↔ On‑Prem allow rules and corresponding hub/on‑prem override routes via the firewall.
- deploymentNameSuffix (string, default utcNow())
  - Suffix used for module/deployment names.

## Shared key handling

Important

- Best practice is to provide the `sharedKey` securely at deployment time or set it immediately after deployment. The generated default GUID will not match your on‑prem device, so you must align the key on both sides.

Provide securely at deployment time (examples)

- Azure CLI: from Key Vault (recommended)

```powershell
$secret = az keyvault secret show --vault-name <kv-name> --name <secret-name> --query value -o tsv
az deployment sub create --name <name> --location <region> `
  --template-file src/add-ons/virtual-network-gateway/solution.bicep `
  --parameters src/add-ons/virtual-network-gateway/solution.bicepparam `
  --parameters sharedKey=$secret
```

- Azure CLI: prompt in session (avoids saving to file)

```powershell
$in = Read-Host -Prompt 'Enter shared key' -AsSecureString
$b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($in)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)
az deployment sub create --name <name> --location <region> `
  --template-file src/add-ons/virtual-network-gateway/solution.bicep `
  --parameters src/add-ons/virtual-network-gateway/solution.bicepparam `
  --parameters sharedKey=$plain
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)
```

Set after deployment (align on‑prem and Azure)

- Azure CLI: update the connection shared key

```powershell
az network vpn-connection shared-key update `
  --resource-group <hub-rg> `
  --name <vpn-connection-name> `
  --value <your-shared-key>
```

- Portal: Hub RG > VPN connection > Shared key > Update

Notes

- Avoid storing the shared key in version control or plain-text files. Prefer Key Vault or deployment-time prompts.
- Changing the shared key requires updating the on‑prem device to the same value.

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

## Cleanup and removal (Portal)

Important

- Expect a brief connectivity interruption during teardown. Plan a maintenance window.
- Some steps depend on others (e.g., disassociate a route table before deleting it).

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

### Cleanup via Azure CLI (parameterized)

Set variables

```powershell
$rg = "<hub-rg>"
$hubVnet = "<hub-vnet-name>"
$vgwRt = "<vgw-route-table-name>"           # The route table associated to GatewaySubnet
$hubRt = "<hub-workload-rt-name>"           # Only if includeHubOnPrem = true
$routesToRemove = @('<route-name-1>', '<route-name-2>')  # In $hubRt to remove on‑prem overrides
$hubPeering = "<hub-peering-name>"          # Hub side peering to each spoke
$hubPeeringVnet = $hubVnet
$spokeRg = "<spoke-rg>"
$spokeVnet = "<spoke-vnet-name>"
$spokePeering = "<spoke-peering-name>"      # Spoke side peering to hub
$vpnConn = "<vpn-connection-name>"
$lngw = "<local-network-gateway-name>"
$vgw = "<virtual-network-gateway-name>"
$pip1 = "<vgw-pip-1>"
$pip2 = "<vgw-pip-2>"
```

Disassociate GatewaySubnet and delete VGW route table

```powershell
az network vnet subnet update --name GatewaySubnet --resource-group $rg --vnet-name $hubVnet --route-table ""
az network route-table delete --name $vgwRt --resource-group $rg --yes
```

Remove on‑prem override routes (only if includeHubOnPrem = true)

```powershell
foreach ($r in $routesToRemove) {
  az network route-table route delete --route-table-name $hubRt --resource-group $rg --name $r
}
```

Update peerings

```powershell
az network vnet peering update --name $hubPeering --resource-group $rg --vnet-name $hubPeeringVnet --allow-gateway-transit false
az network vnet peering update --name $spokePeering --resource-group $spokeRg --vnet-name $spokeVnet --use-remote-gateways false
```

Delete VPN resources

Option A: you know the VGW Public IP names

```powershell
az network vpn-connection delete --name $vpnConn --resource-group $rg --yes
az network local-gateway delete --name $lngw --resource-group $rg --yes
az network vnet-gateway delete --name $vgw --resource-group $rg --yes
az network public-ip delete --name $pip1 --resource-group $rg --yes
az network public-ip delete --name $pip2 --resource-group $rg --yes
```

Option B: capture VGW Public IP IDs first (when names are unknown)

```powershell
# Capture the VGW public IP resource IDs BEFORE deleting the gateway
$pipIds = az network vnet-gateway show --name $vgw --resource-group $rg `
  --query "ipConfigurations[].publicIpAddress.id" -o tsv

az network vpn-connection delete --name $vpnConn --resource-group $rg --yes
az network local-gateway delete --name $lngw --resource-group $rg --yes
az network vnet-gateway delete --name $vgw --resource-group $rg --yes

# Delete the public IPs by ID AFTER the gateway has been removed
foreach ($id in $pipIds) {
  az network public-ip delete --ids $id --yes
}
```

Optional: delete GatewaySubnet (only if unused)

```powershell
az network vnet subnet delete --name GatewaySubnet --resource-group $rg --vnet-name $hubVnet
```

### Cleanup via Azure PowerShell (Az module)

Set variables

```powershell
$rg = "<hub-rg>"
$hubVnet = "<hub-vnet-name>"
$vgwRt = "<vgw-route-table-name>"
$hubRt = "<hub-workload-rt-name>"           # Only if includeHubOnPrem = true
$routesToRemove = @('<route-name-1>', '<route-name-2>')
$hubPeering = "<hub-peering-name>"
$spokeRg = "<spoke-rg>"
$spokeVnet = "<spoke-vnet-name>"
$spokePeering = "<spoke-peering-name>"
$vpnConn = "<vpn-connection-name>"
$lngw = "<local-network-gateway-name>"
$vgw = "<virtual-network-gateway-name>"
$pip1 = "<vgw-pip-1>"
$pip2 = "<vgw-pip-2>"
```

Disassociate GatewaySubnet and delete VGW route table

```powershell
$vnet = Get-AzVirtualNetwork -Name $hubVnet -ResourceGroupName $rg
$gwSubnet = $vnet.Subnets | Where-Object { $_.Name -eq 'GatewaySubnet' }
$gwSubnet.RouteTable = $null
Set-AzVirtualNetwork -VirtualNetwork $vnet
Remove-AzRouteTable -Name $vgwRt -ResourceGroupName $rg -Force
```

Remove on‑prem override routes (only if includeHubOnPrem = true)

```powershell
$rt = Get-AzRouteTable -Name $hubRt -ResourceGroupName $rg
foreach ($r in $routesToRemove) {
  Remove-AzRouteConfig -Name $r -RouteTable $rt | Out-Null
}
Set-AzRouteTable -RouteTable $rt
```

Update peerings

```powershell
Set-AzVirtualNetworkPeering -Name $hubPeering -VirtualNetwork $vnet -AllowGatewayTransit:$false
$spokeVnetObj = Get-AzVirtualNetwork -Name $spokeVnet -ResourceGroupName $spokeRg
Set-AzVirtualNetworkPeering -Name $spokePeering -VirtualNetwork $spokeVnetObj -UseRemoteGateways:$false
```

Delete VPN resources

Option A: you know the VGW Public IP names

```powershell
Remove-AzVirtualNetworkGatewayConnection -Name $vpnConn -ResourceGroupName $rg -Force
Remove-AzLocalNetworkGateway -Name $lngw -ResourceGroupName $rg -Force
Remove-AzVirtualNetworkGateway -Name $vgw -ResourceGroupName $rg -Force
Remove-AzPublicIpAddress -Name $pip1 -ResourceGroupName $rg -Force
Remove-AzPublicIpAddress -Name $pip2 -ResourceGroupName $rg -Force
```

Option B: capture VGW Public IP IDs first (when names are unknown)

```powershell
# Capture the VGW public IP resource IDs BEFORE deleting the gateway
$vgwObj = Get-AzVirtualNetworkGateway -Name $vgw -ResourceGroupName $rg
$pipIds = @()
foreach ($ipconf in $vgwObj.IpConfigurations) {
  if ($ipconf.PublicIpAddress -and $ipconf.PublicIpAddress.Id) {
    $pipIds += $ipconf.PublicIpAddress.Id
  }
}

Remove-AzVirtualNetworkGatewayConnection -Name $vpnConn -ResourceGroupName $rg -Force
Remove-AzLocalNetworkGateway -Name $lngw -ResourceGroupName $rg -Force
Remove-AzVirtualNetworkGateway -Name $vgw -ResourceGroupName $rg -Force

# Delete the public IPs by ID AFTER the gateway has been removed
foreach ($pipId in $pipIds) {
  $parts = $pipId -split '/'
  $pipRg = $parts[4]
  $pipName = $parts[-1]
  Remove-AzPublicIpAddress -Name $pipName -ResourceGroupName $pipRg -Force
}
```

Optional: delete GatewaySubnet (only if unused)

```powershell
Remove-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
Set-AzVirtualNetwork -VirtualNetwork $vnet
```

## References

- [VPN gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
- [Local network gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)
- [Azure Firewall Policy](https://learn.microsoft.com/azure/firewall/policy-overview)
- [Diagnostic settings](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings)
- [VNet peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
