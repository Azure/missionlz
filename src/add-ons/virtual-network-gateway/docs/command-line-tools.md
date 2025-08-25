# Virtual Network Gateway Add-On

## Deployment Guide - Command Line Tools

### Required parameters

- **hubVirtualNetworkResourceId** (string) The resource ID for the Hub virtual network. The virtual network must already contain an AzureFirewallSubnet with an Azure Firewall.
- **operationsLogAnalyticsWorkspaceResourceId** (string) The resource ID of the Operations Log Analytics Workspace for the diagnostics data for the Virtual Network Gateway.
- **virtualNetworkResourceIdList** (array) The resource IDs of the Spoke virtual networks that should use the Hub VPN gateway.
- **localAddressPrefixes** (array) The On‑prem CIDR prefixes routable via S2S (e.g., ["10.1.0.0/16", "10.2.0.0/16"]).
- **localGatewayIpAddress** (string) The public IP address of the on‑premises VPN device.
- **sharedKey** (secureString) The pre‑shared key used for the VPN connection. If omitted, a random GUID is generated.

> [!IMPORTANT]
> Best practice is to provide the `sharedKey` securely at deployment time or set it immediately after deployment. The generated default GUID will not match your on‑prem device, so you must align the key on both sides. Refer to the [Shared Key Handling](#shared-key-handling) section for examples.

### Optional parameters

- **virtualNetworkGatewaySku** (string) The SKU for the virtual network gateway. The default value is "VpnGw2". The allowed values are "VpnGw2", "VpnGw3", "VpnGw4", and "VpnGw5".
- **customFirewallRuleCollectionGroups** (array) When non‑empty, overrides the default VGW‑OnPrem rule group entirely. The default value is an empty array.
- **includeHubOnPrem** (bool) When true, adds Hub ↔ On‑Prem allow rules and corresponding hub/on‑prem override routes via the firewall. The default value is false.
- **deploymentNameSuffix** (string) The suffix used for deployment names. The default value uses the "utcNow" function.

### Shared Key Handling

Here are examples to provide the shared key securely at deployment time:

#### Azure CLI - Key Vault (recommended)

```bash
$secret = az keyvault secret show --vault-name <kv-name> --name <secret-name> --query value -o tsv
az deployment sub create --name <name> --location <region> `
  --template-file src/add-ons/virtual-network-gateway/solution.bicep `
  --parameters src/add-ons/virtual-network-gateway/solution.bicepparam `
  --parameters sharedKey=$secret
```

#### Azure CLI - In-Session Prompt

This option avoids saving the secret value in code.

```bash
$in = Read-Host -Prompt 'Enter shared key' -AsSecureString
$b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($in)
$plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)
az deployment sub create --name <name> --location <region> `
  --template-file src/add-ons/virtual-network-gateway/solution.bicep `
  --parameters src/add-ons/virtual-network-gateway/solution.bicepparam `
  --parameters sharedKey=$plain
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)
```

#### Azure CLI: update the connection shared key

This option sets the shared key value after deployment to align the on-premises VPN device and Azure.

```bash
az network vpn-connection shared-key update `
  --resource-group <hub-rg> `
  --name <vpn-connection-name> `
  --value <your-shared-key>
```

- Portal: Hub RG > VPN connection > Shared key > Update

> [!NOTE]
> Avoid storing the shared key in version control or plain-text files. The preffered options are Key Vault or deployment-time prompts. Changing the shared key requires updating the on‑prem device to the same value.

### Complex parameter example: custom firewall rules override

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

> [!NOTE]
> Ensure rule collection priorities don’t collide with existing Firewall Policy collections.
> If you need Hub ↔ On‑Prem rules with the default group, set includeHubOnPrem to true instead of supplying a full override.

## Cleanup

### Azure CLI

1. Set variables

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

1. Disassociate GatewaySubnet and delete VGW route table

```bash
az network vnet subnet update --name GatewaySubnet --resource-group $rg --vnet-name $hubVnet --route-table ""
az network route-table delete --name $vgwRt --resource-group $rg --yes
```

1. Remove on‑prem override routes (only if includeHubOnPrem = true)

```bash
foreach ($r in $routesToRemove) {
  az network route-table route delete --route-table-name $hubRt --resource-group $rg --name $r
}
```

1. Update peerings

```bash
az network vnet peering update --name $hubPeering --resource-group $rg --vnet-name $hubPeeringVnet --allow-gateway-transit false
az network vnet peering update --name $spokePeering --resource-group $spokeRg --vnet-name $spokeVnet --use-remote-gateways false
```

1. Delete VPN resources

Option A: you know the VGW Public IP names

```bash
az network vpn-connection delete --name $vpnConn --resource-group $rg --yes
az network local-gateway delete --name $lngw --resource-group $rg --yes
az network vnet-gateway delete --name $vgw --resource-group $rg --yes
az network public-ip delete --name $pip1 --resource-group $rg --yes
az network public-ip delete --name $pip2 --resource-group $rg --yes
```

Option B: capture VGW Public IP IDs first (when names are unknown)

```bash
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

### PowerShell

1. Set variables

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

1. Disassociate GatewaySubnet and delete VGW route table

```powershell
$vnet = Get-AzVirtualNetwork -Name $hubVnet -ResourceGroupName $rg
$gwSubnet = $vnet.Subnets | Where-Object { $_.Name -eq 'GatewaySubnet' }
$gwSubnet.RouteTable = $null
Set-AzVirtualNetwork -VirtualNetwork $vnet
Remove-AzRouteTable -Name $vgwRt -ResourceGroupName $rg -Force
```

1. Remove on‑prem override routes (only if includeHubOnPrem = true)

```powershell
$rt = Get-AzRouteTable -Name $hubRt -ResourceGroupName $rg
foreach ($r in $routesToRemove) {
  Remove-AzRouteConfig -Name $r -RouteTable $rt | Out-Null
}
Set-AzRouteTable -RouteTable $rt
```

1. Update peerings

```powershell
Set-AzVirtualNetworkPeering -Name $hubPeering -VirtualNetwork $vnet -AllowGatewayTransit:$false
$spokeVnetObj = Get-AzVirtualNetwork -Name $spokeVnet -ResourceGroupName $spokeRg
Set-AzVirtualNetworkPeering -Name $spokePeering -VirtualNetwork $spokeVnetObj -UseRemoteGateways:$false
```

1. Delete VPN resources

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
