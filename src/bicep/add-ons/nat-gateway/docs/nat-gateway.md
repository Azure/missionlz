# NAT Gateway Solution Guidance

## Overview

This solution automates the deployment of Azure NAT Gateways and their integration with subnets across one or more virtual networks. It is designed for modular, parameterized, and reusable Bicep code, following Azure best practices for naming, zone assignment, and safe subnet updates.

---

## Solution Structure

- **solution.bicep**  
  Orchestrates the deployment, looping through an array of NAT Gateway deployment settings and invoking the main deployment module for each.
- **modules/main-deploy.bicep**  
  Handles the deployment of a NAT Gateway, its public IP prefix, and the attachment to the specified subnet.
- **modules/nat-gateway.bicep**  
  Deploys the NAT Gateway and its public IP prefix using centralized naming.
- **modules/get-subnetinfo.bicep**  
  Retrieves all necessary subnet properties to ensure safe, idempotent updates.
- **modules/attach-natgw-to-subnet.bicep**  
  Updates the subnet to attach the NAT Gateway, preserving all existing properties.
- **../../modules/naming-convention.bicep**  
  Centralizes naming logic for all resources, ensuring consistency.
- **../../data/resource-abbreviations.json**  
  Stores resource type abbreviations for naming.

---

## Key Features

- **Batch Deployments**  
  - Accepts an array of deployment settings, enabling multiple NAT Gateways to be deployed and attached in a single run.
- **Dynamic Parameter Extraction**  
  - Extracts VNet, subnet, and resource group information from the provided subnet resource ID.
- **Centralized Naming**  
  - Uses a dedicated naming convention module for all resource names, ensuring consistency.
- **Zone Awareness**  
  - Supports deployment in a specific zone or regionally, per Azure NAT Gateway documentation.
- **Subnet Safety**  
  - Retrieves all existing subnet properties before updating, preventing accidental loss of configuration (route tables, NSGs, delegations, etc.).
- **Modular Design**  
  - Each module has a single responsibility, making the solution easy to maintain and extend.

---

## Deployment Flow

1. **Parameter Input**  
   The user provides an array of deployment settings, each specifying the target subnet and NAT Gateway options.

2. **Loop and Deploy**  
   The solution loops through each settings object, deploying a NAT Gateway and attaching it to the specified subnet.

3. **Name Generation**  
   The naming convention module generates compliant names for the NAT Gateway and its public IP prefix.

4. **Subnet Info Retrieval**  
   The get-subnetinfo module retrieves all relevant properties from the target subnet.

5. **NAT Gateway and Public IP Prefix Deployment**  
   The nat-gateway module creates the NAT Gateway and its public IP prefix.

6. **Subnet Update**  
   The attach-natgw-to-subnet module updates the subnet, attaching the NAT Gateway and preserving all existing configuration.

---

## Example Parameter File

```bicep-params
using './solution.bicep'

param natGatewayDeployments = [
  {
    subnetResourceId: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet'
    zone: '1'
    tcpIdleTimeout: 10
    publicIpPrefixLength: 31
  }
  {
    subnetResourceId: '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/another-rg/providers/Microsoft.Network/virtualNetworks/another-vnet/subnets/another-subnet'
    zone: ''
    tcpIdleTimeout: 4
    publicIpPrefixLength: 31
  }
]

| Prefix Length | Total IPs | Usable IPs | Notes                                   |
|:-------------:|:---------:|:----------:|:----------------------------------------|
| /31           | 2         | 2          | Smallest allowed for NAT Gateway        |
| /30           | 4         | 4          | Common for high availability scenarios  |
| /29           | 8         | 8          |                                         |
| /28           | 16        | 16         |                                         |
| /27           | 32        | 32         |                                         |
| /26           | 64        | 64         |                                         |

- **All IPs in the prefix are usable** for NAT Gateway.
- **Azure NAT Gateway requires a minimum prefix length of /31** (2 IPs).
- Choose a prefix length based on your expected outbound SNAT concurrency and scaling needs.