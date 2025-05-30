# NAT Gateway Solution Documentation

## Overview

This solution automates the deployment of an Azure NAT Gateway and its integration with a hub virtual network, following Azure best practices for modular, parameterized, and reusable Bicep code. The deployment ensures consistent naming, zone assignment, and correct association with the AzureFirewallSubnet.

For more information, see the [Azure NAT Gateway documentation](https://learn.microsoft.com/azure/virtual-network/nat-gateway-resource).

---

## Solution Structure

- **solution.bicep**: Orchestrates the deployment, extracting required values from the hub firewall resource, generating names, and coordinating module calls.
- **modules/nat-gateway.bicep**: Deploys the NAT Gateway and its public IP prefix.
- **modules/get-networkinfo.bicep**: Extracts VNet and subnet information (including address prefix) from the firewall resource.
- **modules/get-subnetaddressprefix.bicep**: Retrieves the address prefix for a given subnet.
- **modules/attach-natgw-to-subnet.bicep**: Attaches the NAT Gateway to the AzureFirewallSubnet.
- **../../modules/naming-convention.bicep**: Centralizes naming logic for all resources, ensuring consistency.
- **../../data/resource-abbreviations.json**: Stores resource type abbreviations for naming.

---

## Key Features

- **Dynamic Parameter Extraction**:  
  - Environment abbreviation, network name, and identifier are parsed from the firewall resource name.
  - Location is dynamically retrieved from the firewall resource.

- **Centralized Naming**:  
  - All resource names (NAT Gateway, Public IP Prefix) are generated using a dedicated naming convention module, ensuring consistency across deployments.

- **Modular Design**:  
  - Each module has a single responsibility, making the solution easy to maintain and extend.

- **Zone Awareness**:  
  - Supports deployment in a specific zone configuration per Azure NAT Gateway documentation.  

- **Subnet Safety**:  
  - The address prefix is always retrieved before updating the subnet, preventing accidental misconfiguration.

---

## Deployment Flow

1. **Extract Resource Group and Firewall Info**  
   The solution parses the firewall resource ID to determine the resource group, environment, network, and identifier.

2. **Get Firewall Location**  
   The firewall resource is referenced to retrieve its Azure region.

3. **Generate Resource Names**  
   The naming convention module is called with extracted parameters to generate compliant names for the NAT Gateway and its public IP prefix.

4. **Get Network Info**  
   The get-networkinfo module retrieves the VNet name, subnet name, and address prefix for the AzureFirewallSubnet.

5. **Deploy NAT Gateway and Public IP Prefix**  
   The nat-gateway module creates the NAT Gateway and its public IP prefix using the generated names.

6. **Attach NAT Gateway to Subnet**  
   The attach-natgw-to-subnet module updates the AzureFirewallSubnet to associate it with the new NAT Gateway, using the correct address prefix.

---

Example Parameter File

```bicep-params
using './solution.bicep'

param hubFirewallResourceId = '/subscriptions/xxxx/resourceGroups/your-rg/providers/Microsoft.Network/azureFirewalls/your-fw'
param zone = ''
param tcpIdleTimeout = 4
param publicIpPrefixLength = 30  
```

## Public IP Prefix Lengths and Usable IP Addresses

When creating a Public IP Prefix for Azure NAT Gateway, the prefix length determines how many public IP addresses are included in the prefix. Below is a summary of common prefix lengths and the number of usable public IP addresses available:

| Prefix Length | Total IPs | Usable IPs | Notes                                   |
|:-------------:|:---------:|:----------:|:----------------------------------------|
| /31           | 2         | 2          | Smallest allowed for NAT Gateway        |
| /30           | 4         | 4          | Common for high availability scenarios  |
| /29           | 8         | 8          |                                         |
| /28           | 16        | 16         |                                         |
| /27           | 32        | 32         |                                         |
| /26           | 64        | 64         |                                         |

- **All IPs in the prefix are usable** for NAT Gateway (unlike some other Azure resources).
- **Azure NAT Gateway requires a minimum prefix length of /31** (2 IPs).
- Choose a prefix length based on your expected outbound SNAT concurrency and scaling needs.

For more details, see the [Azure NAT Gateway documentation](https://learn.microsoft.com/azure/virtual-network/nat-gateway-resource#public-ip-prefix).