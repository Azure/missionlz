# VPN Gateway MLZ Add-On

## Introduction

This document provides details on a Bicep script that deploys a VPN Gateway, Local Network Gateway, VPN connection, and related resources in Azure, integrating into an existing MLZ network deployment. It includes descriptions of all parameters, required parameters, instructions on building and deploying the ARM template, and steps to create a template specification from the Bicep script.

The deployment is intended to provide an on-prem VPN gateway to connect into the MLZ network through the Hub vNet and route to all spokes.   The route tables in all spoke Azure vNets are updated to route traffic to on-prem CIDR ranges to the internal interface of the Azure firewall in the Hub vNet.   This allows for the firewall to serve as a protection between the on-prem internal network and the Azure MLZ network.

Additionally, it covers the modules used within the script and their roles in the deployment process.

---

## Parameters

### 1. **vgwName** (string) - Required

- **Description:** The name of the VPN Gateway.

### 2. **vgwLocation** (string) - Optional (default: location of the resource group)

- **Description:** The Azure region for deploying the VPN Gateway. If not provided, it defaults to the location of the resource group.

### 3. **vgwPublicIpAddressNames** (array) - Required

- **Description:** The names of the public IP addresses associated with the VPN Gateway.  Requires two for redundancy.

### 4. **vgwSku** (string) - Optional (default: `'VpnGw2'`)

- **Description:** The SKU (size) of the VPN Gateway. Allowed values: `VpnGw2`, `VpnGw3`, `VpnGw4`, `VpnGw5`.

### 5. **localNetworkGatewayName** (string) - Required

- **Description:** The name of the Local Network Gateway.

### 6. **localGatewayIpAddress** (string) - Required

- **Description:** The IP address of the Local Network Gateway. This must be a public IP address or a reachable IP from the Azure environment.

### 7. **localAddressPrefixes** (array) - Required

- **Description:** A list of address prefixes of the local network routable through the VPN Gateway.

### 8. **useSharedKey** (bool) - Required

- **Description:** Indicates whether to use a shared key or a Key Vault certificate URI for the VPN connection.

### 9. **sharedKey** (string) - Required if `useSharedKey = true`

- **Description:** The shared key for the VPN connection. This parameter is secured.  A "true" value uses shared key which is provided in the portal or command prompt at deployment.  A "false" value requires that a keyVaultCertificateUri is provided. 

### 10. **keyVaultCertificateUri** (string) - Optional (default: `''`)

- **Description:** The URI of the Key Vault certificate for the VPN connection. Only used if `useSharedKey = false`. Must be a valid URI starting with `https://` and containing `/secrets/`.

### 11. **deploymentNameSuffix** (string) - Optional (default: current UTC time)

- **Description:** A unique suffix for naming the deployment.

### 12. **hubVirtualNetworkResourceId** (string) - Required

- **Description:** The resource ID of the hub virtual network.

### 13. **vnetResourceIdList** (array) - Required

- **Description:** A list of peered virtual networks that will use the VPN Gateway.  The peerings will be updated to allow gateway transit and use.

### 14. **routeTableIds** (array) - Required

- **Description:** A list of route tables used by the spoke virtual networks that will use the VPN Gateway.  The route tables are updated with routes to the local gateway address prefixes.

---

## Modules Used in the Script

This Bicep script calls several external modules to deploy resources efficiently and modularly. Here's an overview of each module and what it does:

### 1. **VPN Gateway Module**

- **File:** `modules/vpn-gateway.bicep`
- **Description:** This module deploys the Virtual Network Gateway (VPN Gateway) in a specified resource group. The VPN Gateway enables secure cross-premises connectivity and remote user VPNs.
- **Parameters:**
  - `vgwname`: The name of the VPN Gateway.
  - `vgwlocation`: The location where the VPN Gateway will be deployed.
  - `publicIpAddressNames`: The names of the public IP addresses associated with the VPN Gateway.
  - `vgwsku`: The SKU of the VPN Gateway.
  - `vnetName`: The name of the hub Virtual Network to which the VPN Gateway will be connected.

### 2. **Local Network Gateway Module**

- **File:** `modules/local-network-gateway.bicep`
- **Description:** This module deploys the Local Network Gateway, which defines the on-premises network's configuration and connectivity to Azure. It includes the on-premises gateway's public IP address and the network address ranges to route through the VPN connection.
- **Parameters:**
  - `vgwlocation`: The location of the Local Network Gateway.
  - `localNetworkGatewayName`: The name of the Local Network Gateway.
  - `gatewayIpAddress`: The public IP address of the Local Network Gateway.
  - `addressPrefixes`: The local address prefixes (network ranges) of the on-premises network.

### 3. **VPN Connection Module**

The VPN connection module contains these most commonly used IPSEC configuration settings:
```
    saLifeTimeSeconds: 3600
    saDataSizeKilobytes: 102400000
    ipsecEncryption: 'AES256'
    ipsecIntegrity: 'SHA256'
    ikeEncryption: 'AES256'
    ikeIntegrity: 'SHA256'
    dhGroup: 'DHGroup2'
    pfsGroup: 'PFS2'
```

- **File:** `modules/vpn-connection.bicep`
- **Description:** This module creates the VPN connection between the VPN Gateway in Azure and the Local Network Gateway (on-premises network). It can use either a shared key or a Key Vault certificate for secure authentication.
- **Parameters:**
  - `vpnConnectionName`: The name of the VPN connection.
  - `vgwlocation`: The location of the VPN Gateway.
  - `vpnGatewayName`: The name of the VPN Gateway.
  - `vpnGatewayResourceGroupName`: The resource group where the VPN Gateway is deployed.
  - `sharedKey`: The shared key for the VPN connection (if using shared key authentication).
  - `keyVaultCertificateUri`: The URI of the Key Vault certificate (if using certificate-based authentication).
  - `localNetworkGatewayName`: The name of the Local Network Gateway.


### 4. **Retrieve VNet Peerings Module**

- **File:** `modules/retrieve-vnet-peerings.bicep`
- **Description:** This module retrieves the list of virtual network peerings associated with a virtual network. The peerings allow networks to communicate securely with each other within the same Azure region or across regions.
- **Parameters:**
  - `vnetResourceId`: The resource ID of the virtual network for which peerings are being retrieved.

### 5. **Update VNet Peerings Module**

- **File:** `modules/update-vnet-peerings.bicep`
- **Description:** After retrieving the peerings for a virtual network, this module updates the peerings to reflect the new VPN Gateway configuration. This allows peered networks to utilize the VPN Gateway for cross-premises connectivity.
- **Parameters:**
  - `vnetResourceId`: The resource ID of the virtual network.
  - `peeringsList`: The list of virtual network peerings to be updated.

### 6. **Update Spoke Route Tables Module**

- **File:** `modules/update-spokert.bicep`
- **Description:** This module updates the route tables for spoke virtual networks, ensuring that traffic is routed correctly through the VPN Gateway to the local network (on-premises). It modifies route table entries to include the address prefixes of the local network.
- **Parameters:**
  - `routeTableId`: The resource ID of the route table being updated.
  - `localAddressPrefixList`: The list of address prefixes from the local (on-premises) network.

## Removal of VPN Gateway

1. Delete the VPN Connection in the MLZ Hub resource group.
2. Delete the Local Network Gateway in the MLZ Hub resource group.
3. Delete the VPN Gateway in the MLZ Hub resource group.
4. Navigate to the Hub vNet, and go to Peerings:
  a. Open each peering in the list.
  b. Uncheck "Allow gateway or route server in '' to forward traffic to ''.
  c. Click "save".
5. Navigate to each spoke vNet represented in the peerings list.
  a. Open the peering to the Hub network.
  b. Uncheck "Enable '' to use '' remote gateway.
  c. Click "save".
6. Navigate to each spoke network resource group.
  a. Open the Route table in the group.
  b. Choose "Routes".
  c. Delete the VPN routes in the list.
