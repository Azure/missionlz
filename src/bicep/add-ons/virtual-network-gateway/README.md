# VPN Gateway Deployment using Bicep

This Bicep template deploys a VPN Gateway, a Local Network Gateway, and a VPN Connection in Azure. The deployment is scoped at the subscription level and uses three separate modules for the VPN Gateway, Local Network Gateway, and VPN Connection.

## Parameters

- **vgwName**: The name of the VPN Gateway.
- **vgwLocation**: The Azure region location of the VPN Gateway.
- **vgwPublicIpAddressNames**: The names of the public IP addresses to use for the VPN Gateway.
- **vgwSku**: The SKU of the VPN Gateway.
- **localNetworkGatewayName**: The name of the Local Network Gateway.
- **localGatewayIpAddress**: The IP address of the Local Network Gateway. Must be a public IP address or be able to be connected to from the MLZ network.
- **localAddressPrefixes**: The address prefixes of the Local Network which will be routable through the VPN Gateway.
- **sharedKey**: The shared key to use for the VPN connection. If provided, the keyVaulCertificateUri parameter is ignored.
- **keyVaultCertificateUri**: The URI of the Key Vault certificate to use for the VPN connection. If provided, the sharedKey parameter is ignored.
- **deploymentNameSuffix**: A suffix to use for naming deployments uniquely. Defaults to the Bicep resolution of the `utcNow()` function.
- **hubVirtualNetworkResourceId**: The resource ID of the hub virtual network.

## Modules

### VPN Gateway Module

The VPN Gateway module is defined in `modules/vpn-gateway.bicep` and is called with the following parameters:

- **vgwname**: The name of the VPN Gateway.
- **vgwlocation**: The Azure region location of the VPN Gateway.
- **publicIpAddressNames**: The names of the public IP addresses to use for the VPN Gateway.
- **vgwsku**: The SKU of the VPN Gateway.
- **vnetName**: The name of the hub virtual network.

### Local Network Gateway Module

The Local Network Gateway module is defined in `modules/local-network-gateway.bicep` and is called with the following parameters:

- **vgwlocation**: The Azure region location of the VPN Gateway.
- **localNetworkGatewayName**: The name of the Local Network Gateway.
- **gatewayIpAddress**: The IP address of the Local Network Gateway.
- **addressPrefixes**: The address prefixes of the Local Network.

### VPN Connection Module

The VPN Connection module is defined in `modules/vpn-connection.bicep` and is called with the following parameters:

- **vpnConnectionName**: The name of the VPN connection.
- **vgwlocation**: The Azure region location of the VPN Gateway.
- **vpnGatewayName**: The name of the VPN Gateway.
- **vpnGatewayResourceGroupName**: The resource group name of the VPN Gateway.
- **sharedKey**: The shared key to use for the VPN connection.
- **keyVaultCertificateUri**: The URI of the Key Vault certificate to use for the VPN connection.
- **localNetworkGatewayName**: The name of the Local Network Gateway.

## Deployment

To deploy this Bicep template, use the following Azure CLI command:

```sh
az deployment sub create \
  --template-file solution.bicep \
  --location <location> \
  --parameters \
    vgwName=<vpnGatewayName> \
    vgwLocation=<vpnGatewayLocation> \
    vgwPublicIpAddressNames=<publicIpAddressNames> \
    vgwSku=<vpnGatewaySku> \
    localNetworkGatewayName=<localNetworkGatewayName> \
    localGatewayIpAddress=<localGatewayIpAddress> \
    localAddressPrefixes=<localAddressPrefixes> \
    sharedKey=<sharedKey> \
    keyVaultCertificateUri=<keyVaultCertificateUri> \
    deploymentNameSuffix=<deploymentNameSuffix> \
    hubVirtualNetworkResourceId=<hubVirtualNetworkResourceId>
```

Replace the placeholders with the appropriate values for your deployment.