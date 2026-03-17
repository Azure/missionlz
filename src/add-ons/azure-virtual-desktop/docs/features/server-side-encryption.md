# Azure Virtual Desktop Add-on

[**Home**](../../README.md) | [**Features**](../features.md) | [**Design**](../design.md) | [**Prerequisites**](../prerequisites.md) | [**Troubleshooting**](../troubleshooting.md)

## Features

- [**ArcGIS Pro**](./arcgis-pro.md#arcgis-pro)
- [**Auto Increase Premium File Share Quota**](./auto-increase-premium-file-share-quota.md#auto-increase-premium-file-share-quota)
- [**Autoscale**](./autoscale.md#autoscale)
- [**Drain Mode**](./drain-mode.md#drain-mode)
- [**FSLogix**](./fslogix.md#fslogix)
- [**GPU Drivers & Settings**](./gpu.md#gpu-drivers--settings)
- [**High Availability**](./high-availability.md#high-availability)
- [**Monitoring**](./monitoring.md#monitoring)
- [**Server-Side Encryption with Customer Managed Keys**](./server-side-encryption.md#server-side-encryption-with-customer-managed-keys)
- [**SMB Multichannel**](./smb-multi-channel.md#smb-multichannel)
- [**Start VM On Connect**](./start-vm-on-connect.md#start-vm-on-connect)
- [**Trusted Launch**](./trusted-launch.md#trusted-launch)

### Server-Side Encryption with Customer Managed Keys

This optional feature deploys the required resources & configuration to enable server-side encryption encryption on the session hosts using a customer managed key. The configuration also enables double encryption which uses a platform managed key in combination with the customer managed key. Also, the temp and cache disks are encrypted using the "encryption at host" feature.

> **NOTE**
> If deploying a "pooled" host pool with FSLogix, the data in the profile and office containers are encrypted using encryption on the storage service, not the virtual machine.

**Reference:** [Azure Server-Side Encryption - Microsoft Docs](https://learn.microsoft.com/azure/virtual-machines/disk-encryption)

**Deployed Resources:**

- Key Vault
  - Key Encryption Key
- Disk Encryption Set
