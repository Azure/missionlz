# Mission Landing Zone - Costs Estimate

[**Home**](../README.md) | [**Design**](./design.md) | [**Add-Ons**](../src/add-ons/README.md) | [**Resources**](./resources.md) | [**Costs**](./costs.md)

## Costs

This document is for ***reference purposes only***.  The costs for an MLZ deployment will vary based on deployment size, usage, and number of additional add-ons utilized.  See table below for variables that will impact MLZ costs.

### Note

> Contact your Account team representative for official pricing and details.

## Variables

- Contract vehicle
- Cloud environment; Commercial or Government or Secure cloud
- Data ingress and egress
- Storage usage
- Any add-ons

## Estimated Costs for a standard MLZ Core deployment with a Windows Jumpbox utilizing Bastion per month

| Resource                             | Cost        |
| :----------------------------------- | :-----------|
| Azure Firewall (Standard)            | $912.00      |
| Bastion                              | $138.70      |
| Virtual Machine                      | $152.57      |
| Disk                                 | $9.80        |
| Storage Account x 3                  | $204.15      |
| Virtual Network x 3                  | $42.00       |
| Total                                | $1459.72     |

## Azure Pricing Calculator

[Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/?ef_id=_k_1f5e4fd4918b12e18793265fe6c847f6_k_&OCID=AIDcmm5edswduu_SEM__k_1f5e4fd4918b12e18793265fe6c847f6_k_&msclkid=1f5e4fd4918b12e18793265fe6c847f6)

## MLZ Core Deployment Inventory Example

For reference purposes only, a standard MLZ Core deployment with a Windows Jumbox utilizing Bastion will deploy the following Azure resources:

| Resource                             | Number |
| :----------------------------------- | :------|
| Resource Group                       | 4      |
| Disk                                 | 1      |
| Disk Encryption Set                  | 1      |
| Key Vault                            | 2      |
| Managed Identity                     | 2      |
| Network Interface                    | 16     |
| Private Endpoint                     | 15     |
| Virtual Machine                      | 1      |
| Bastion                              | 1      |
| Firewall                             | 1      |
| Firewall Policy                      | 1      |
| Network Security Group               | 4      |
| Private DNS Zone                     | 15     |
| Public IP Address                    | 3      |
| Route Table                          | 3      |
| Storage Account                      | 3      |
| Virtual Network                      | 3      |
| Azure Monitor Private Link Scope     | 1      |
| Log Analytics Workspace              | 1      |
| Solution                             | 6      |

## See Also

- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/?ef_id=_k_1f5e4fd4918b12e18793265fe6c847f6_k_&OCID=AIDcmm5edswduu_SEM__k_1f5e4fd4918b12e18793265fe6c847f6_k_&msclkid=1f5e4fd4918b12e18793265fe6c847f6)  

## Contributing

This project welcomes contributions and suggestions. See our [Contributing Guide](CONTRIBUTING.md) for details.

## Feedback, Support, and How to Contact Us

Please see the [Support and Feedback Guide](../SUPPORT.md). To report a security issue please see our [security guidance](../SECURITY.md)
