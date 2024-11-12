# Azure Virtual Desktop Solution

[**Home**](../../README.md) | [**Features**](../features.md) | [**Design**](../design.md) | [**Prerequisites**](../prerequisites.md) | [**Troubleshooting**](../troubleshooting.md)

## Features

- [**Auto Increase Premium File Share Quota**](./autoIncreasePremiumFileShareQuota.md#auto-increase-premium-file-share-quota)
- [**Autoscale**](./autoscale.md#autoscale)
- [**Backups**](./backups.md#backups)
- [**Drain Mode**](./drainMode.md#drain-mode)
- [**FSLogix**](./fslogix.md#fslogix)
- [**GPU Drivers & Settings**](./gpu.md#gpu-drivers--settings)
- [**High Availability**](./highAvailability.md#high-availability)
- [**Monitoring**](./monitoring.md#monitoring)
- [**Server-Side Encryption with Customer Managed Keys**](./serverSideEncryption.md#server-side-encryption)
- [**SMB Multichannel**](./smbMultiChannel.md#smb-multichannel)
- [**Start VM On Connect**](./startVmOnConnect.md#start-vm-on-connect)
- [**Trusted Launch**](./trustedLaunch.md#trusted-launch)
- [**Validation**](./validation.md#validation)

### Server-Side Encryption with Customer Managed Keys

This optional feature deploys the required resources & configuration to enable server-side encryption encryption on the session hosts using a customer managed key. The configuration also enables double encryption which uses a platform managed key in combination with the customer managed key. Also, the temp and cache disks are encrypted using the "encryption at host" feature.

> **NOTE**
> If deploying a "pooled" host pool with FSLogix, the data in the profile and office containers are encrypted using encryption on the storage service, not the virtual machine.

**Reference:** [Azure Server-Side Encryption - Microsoft Docs](https://learn.microsoft.com/azure/virtual-machines/disk-encryption)

**Deployed Resources:**

- Key Vault
  - Key Encryption Key
- Disk Encryption Set
