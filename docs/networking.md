# Mission Landing Zone - Networking Defaults

[**Home**](../README.md) | [**Design**](./design.md) | [**Add-Ons**](../src/add-ons/README.md) | [**Resources**](./resources.md)

This repository has carefully planned default address prefixes configured throughout the virtual networks in Mission Landing Zone and the add-ons to prevent deployment conflicts. We exepect most customers to define custom address prefixes. However, if you deploy everything "as-is", there are no overlapping address spaces and the networks will deploy without an error. Here are the default address prefixes:

## Super Network

10.0.128.0/18

## Virtual Networks

| Solution | Network                              | Address Prefix |
| :------- | :----------------------------------- | :------------- |
| MLZ      | Hub                                  | 10.0.128.0/23  |
| MLZ      | Identity                             | 10.0.130.0/24  |
| MLZ      | Operations                           | 10.0.131.0/24  |
| MLZ      | Shared Services                      | 10.0.132.0/24  |
| Add-On   | Tier 3                               | 10.0.133.0/24  |
| Add-On   | Imaging                              | 10.0.134.0/24  |
| Add-On   | ESRI Enterprise                      | 10.0.136.0/23  |
| Add-On   | Azure Virtual Desktop, Shared        | 10.0.139.0/24  |
| Add-On   | Azure Virtual Desktop, Stamp Index 0 | 10.0.140.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 1 | 10.0.142.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 2 | 10.0.144.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 3 | 10.0.146.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 4 | 10.0.148.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 5 | 10.0.150.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 6 | 10.0.152.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 7 | 10.0.154.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 8 | 10.0.156.0/23  |
| Add-On   | Azure Virtual Desktop, Stamp Index 9 | 10.0.158.0/23  |
| Add-On   | Azure NetApp Files                   | 10.0.160.0/23  |

## Azure Firewall Public IP Addresses

The MLZ deployment supports multiple static public IP addresses (PIPs) for Azure Firewall. Use the `additionalFwPipCount` parameter to specify the number of additional static PIPs to create for NAT rules. All PIPs are static and follow the same naming and diagnostic logging conventions.

### Parameter Reference

- `additionalFwPipCount` (int, default: 0): Number of additional static public IP addresses to create for the Azure Firewall. Set to 0 for default behavior (single PIP), or increase as needed for your NAT scenarios.

### Example Usage

```bicep
param additionalFwPipCount int = 2
```

This will provision two additional static PIPs for the Azure Firewall, in addition to the default one.

### Notes
- Deleting and recreating a static PIP will not retain the same IP address (Azure behavior).
- All custom and original firewall PIPs are static, use the same naming logic, and receive identical diagnostic logging.
