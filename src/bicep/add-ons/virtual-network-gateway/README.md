# VPN Gateway MLZ Add-On  

## Introduction  

This document provides details on a Bicep script that deploys a VPN Gateway, Local Network Gateway, VPN connection, and related resources in Azure, integrating into an existing MLZ network deployment. It includes descriptions of all parameters, required parameters, instructions on building and deploying the ARM template, and steps to create a template specification from the Bicep script.  

The deployment is intended to provide an on-prem VPN gateway to connect into the MLZ network through the Hub vNet and route to all spokes. A route table is created for the vpn gateway and attached to the GatewaySubnet in the Hub network, and firewall rules added to allow connectivity.  

This allows for the firewall to serve as a protection between the on-prem internal network and the Azure spoke networks.  

Additionally, it covers the modules used within the script and their roles in the deployment process.  

---

## Parameters  

### 1. **vgwName** (string) - Required  

- **Description:** The name of the VPN Gateway. Provided as an input parameter to the solution when deployed.  

### 2. **vgwLocation** (string) - Optional (default: location of the resource group)  

- **Description:** The Azure region for deploying the VPN Gateway. If not provided, it defaults to the location of the resource group. Provided as an input parameter to the solution when deployed.  

### 3. **vgwPublicIpAddressNames** (array) - Required  

- **Description:** The names of the public IP addresses associated with the VPN Gateway.  Requires two for redundancy. Provided as an input parameter to the solution when deployed.  

### 4. **vgwSku** (string) - Optional (default: `'VpnGw2'`)  

- **Description:** The SKU (size) of the VPN Gateway. Allowed values: `VpnGw2`, `VpnGw3`, `VpnGw4`, `VpnGw5`.  The default can be changed in the "solution.bicep" file.  

### 5. **localNetworkGatewayName** (string) - Required  

- **Description:** The name of the Local Network Gateway.  Provided as an input parameter to the solution when deployed.

### 6. **localGatewayIpAddress** (string) - Required  

- **Description:** The IP address of the Local Network Gateway. This must be a public IP address or a reachable IP from the Azure environment. Provided as an input parameter to the solution when deployed.

### 7. **allowedAzureAddressPrefixes** (array) - Required  

- **Description:** A list of address prefixes of the peered spoke networks that will be allowed to access the networks through the VPN gateway.   This is used in an Azure firewall rule. Provided as an input parameter to the solution when deployed.  

### 8. **localAddressPrefixes** (array) - Required  

- **Description:** A list of address prefixes of the local network routable through the VPN Gateway.  This controls what networks can be accessed from Azure through the VPN Gateway.  This is also used in an Azure firewall rule. Provided as an input parameter to the solution when deployed.  

### 9. **useSharedKey** (bool) - Required  

- **Description:** Indicates whether to use a shared key or a Key Vault certificate URI for the VPN connection.  If false, a URL to a pre-existing keyvault stored certificate must be used instead. Provided as an input parameter to the solution when deployed.  

### 10. **sharedKey** (string) - Required if `useSharedKey = true`  

- **Description:** The shared key for the VPN connection. This parameter is secured.  A "true" value uses shared key which is provided in the portal or command prompt at deployment.  A "false" value requires that a keyVaultCertificateUri is provided. Remove this from the parameters file before deployment to ensure the deployment will prompt for the value to avoid storing the secret in the file.  

### 11. **keyVaultCertificateUri** (string) - Optional (default: `''`)  

- **Description:** The URI of the Key Vault certificate for the VPN connection. Only used if `useSharedKey = false`. Must be a valid URI starting with `https://` and containing `/secrets/`. Provided as an input parameter to the solution when deployed.  

### 12. **hubVirtualNetworkResourceId** (string) - Required  

- **Description:** The resource ID of the hub virtual network.  Can be found on the "Properties" blade on the vNet in the Azure portal. Provided as an input parameter to the solution when deployed.  

### 13. **vnetResourceIdList** (array) - Required  

- **Description:** A list of peered virtual networks that will use the VPN Gateway.  The peerings will be updated to allow gateway transit and use.  Can be found on the "Properties" blade on the vNet in the Azure portal. Provided as an input parameter to the solution when deployed.

### 14. **azureFirewallName** (string) - Required  

- **Description:** The name of the Azure firewall in the hub network used to control all traffic through the VPN gateway and all spoke networks.  Provided as an input parameter to the solution when deployed.

### 14. **routeTableName** (string) - Required  

- **Description:** The name of the VPN Gateway route table that is used to control the gateway subnet routing overrides necessary to push all traffic through the Azure firewall.  Provided as an input parameter to the solution when deployed.

---

## Modules Used in the Script  

This Bicep script calls several external modules to deploy resources efficiently and modularly. Here's an overview of each module and what it does:  

### 1. **VPN Gateway Module**  

- **File:** `modules/vpn-gateway.bicep`  
- **Description:** This module deploys the Virtual Network Gateway (VPN Gateway) in a specified resource group. The VPN Gateway enables secure cross-premises connectivity.  
- **Parameters:**  
  - `vgwName`: The name of the VPN Gateway. Provided as an input parameter to the solution when deployed.  
  - `vgwLocation`: The location where the VPN Gateway will be deployed. Provided as an input parameter to the solution when deployed.  
  - `publicIpAddressNames`: The names of the public IP addresses associated with the VPN Gateway. Provided as an input parameter to the solution when deployed.  
  - `vgwsku`: The SKU of the VPN to be deployed. Provided as an input parameter to the solution when deployed.  
  - `vnetName`: The name of the hub virtual network to which the VPN Gateway will be connected.  Derived from the hub virtual network resource id provided as an input parameter when deployed.  

### 2. **Local Network Gateway Module**  

- **File:** `modules/local-network-gateway.bicep`
- **Description:** This module deploys the Local Network Gateway, which defines the on-premises network's configuration and connectivity to Azure. It includes the on-premises gateway's public IP address and the network address ranges to route through the VPN connection.  
- **Parameters:**  
  - `vgwlocation`: The location of the Local Network Gateway. Provided as an input parameter to the solution when deployed.  
  - `localNetworkGatewayName`: The name of the Local Network Gateway. Provided as an input parameter to the solution when deployed.  
  - `gatewayIpAddress`: The public IP address of the Local Network Gateway. Provided as an input parameter to the solution when deployed.  
  - `addressPrefixes`: The local address prefixes (network ranges) of the on-premises network. Provided as an input parameter to the solution when deployed.  

### 3. **VPN Connection Module**  

The VPN connection module contains these most commonly used IPSEC configuration settings:
``
    saLifeTimeSeconds: 3600  
    saDataSizeKilobytes: 102400000  
    ipsecEncryption: 'AES256'  
    ipsecIntegrity: 'SHA256'  
    ikeEncryption: 'AES256'  
    ikeIntegrity: 'SHA256'  
    dhGroup: 'DHGroup2'  
    pfsGroup: 'PFS2'  
``
Change these in the module file directly to modify connection settings for deployment.  

- **File:** `modules/vpn-connection.bicep`  
- **Description:** This module creates the VPN connection between the VPN Gateway in Azure and the Local Network Gateway (on-premises network). It can use either a shared key or a Key Vault certificate for secure authentication.  
- **Parameters:**  
  - `vpnConnectionName`: The name of the VPN connection. Provided as an input parameter to the solution when deployed.  
  - `vgwlocation`: The location of the VPN Gateway. Provided as an input parameter to the solution when deployed.  
  - `vpnGatewayName`: The name of the VPN Gateway. Provided as an input parameter to the solution when deployed.  
  - `vpnGatewayResourceGroupName`: The resource group where the VPN Gateway is deployed. Gateway is placed in the hub virtual network resource group, the name is extracted from the hub virtual network resource group id provided in the parameters when deployed.  
  - `sharedKey`: The shared key for the VPN connection (if using shared key authentication). Provided as an input parameter to the solution when deployed. Ensure the shared key and value are not provided in the parameters file before deployment to ensure prompting for the value at deployment time.  
  - `keyVaultCertificateUri`: The URI of the Key Vault certificate (if using certificate-based authentication). Provided as an input parameter to the solution when deployed, if shared key is not used.  
  - `localNetworkGatewayName`: The name of the Local Network Gateway. Provided as an input parameter to the solution when deployed.  

### 4. **Retrieve Existing Module**  

- **File:** `modules/retrieve-existing.bicep`  
- **Description:** This module retrieves the list of virtual network peerings associated with a virtual network. The peerings allow networks to communicate securely with each other within the same Azure region or across regions.   This module is also used to retrieve information from other existing resources depending on the parameters used.  
- **Parameters:**  
  - `vnetResourceId`: The resource ID of the virtual network for which peerings are being retrieved.  Provided as an input parameter to the solution when deployed.  

### 5. **VNet Peerings Module**  

- **File:** `modules/vnet-peerings.bicep`
- **Description:** After retrieving the peerings for a virtual network, this module updates the peerings to reflect the new VPN Gateway configuration. This allows peered networks to utilize the VPN Gateway for cross-premises connectivity.
- **Parameters:**
  - `vnetResourceId`: The resource ID of the virtual network. Provided as an input parameter to the solution when deployed.  
  - `peeringsList`: The list of virtual network peerings to be updated. Returned values from the retrieve-existing.bicep module.  

### 6. **Route Table Module**

- **File:** `modules/route-table.bicep`
- **Description:** This module creates the route table for the VPN gateway.
- **Parameters:**
  - `routeTableName`: The route table name. Provided as an input parameter to the solution when deployed.  

### 7. **Route Definition**  

- **File:** `modules/route-definition.bicep`  
- **Description:** This module builds the route construct to be used when adding the route, as multiple routes need to be added.  Virtual appliance is hard coded as the next hop type.  
- **Parameters:**  
  - `firewallIpAddress`: The IP address of the firewall, used as the next hop IP address.  Returned value from the retrieve-existing.bicep module.  
  - `addressPrefixes`: The address prefixes used in the route being built. Provided as an input parameter to the solution when deployed.  

### 8. **Routes Module**  

- **File:** `modules/routes.bicep`  
- **Description:** This module creates the routes in a route table.  
- **Parameters:**  
  - `routeTableName`: The route table name. Provided as an input parameter to the solution when deployed.  
  - `routeName`: The name of the route. Value defaulted in the solution.bicep file, the value is: "route-#" with an increment number depending on the number of routes being added.  
  - `addressSpace`: The CIDR address prefix being routed. Provided as an input parameter to the solution when deployed.  
  - `nextHopType`: The type of next hop, defaulted to appliance in the solution.bicep file.  
  - `nextHopIpAddress`: The IP address of the next hop.  In this implementation, the firewall IP address. Provided as an input parameter to the solution when deployed.  

### 8. **Firewall Rules Module**  

- **File:** `modules/firewall-rules.bicep  `
- **Description:** This module creates the firewall rules to allow spoke and vpn address prefixes access to eachother.  
- **Parameters:**  
  - `allowVnetAddressSpaces`: The CIDR address prefixes of peered Azure spoke vnets.  Provided as an input parameter to the solution when deployed.  
  - `onPremAddressSpaces`: The CIDR address prefixes of the onprem networks to be allowed.  Provided as an input parameter to the solution when deployed.  
  - `firewallPolicyId`: The firewall policy attached to the hub firewall.  The solution will dynamically retrieve this value.  
  - `priorityValue`: The priority value for the firewall rule.  The solution defines this at a value of 300 in the main bicep named solution.bicep.  

  The rule is hardcoded to allow any protocol to any address in the rule.  Customize firewall-rules.bicep to change behavior.

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
