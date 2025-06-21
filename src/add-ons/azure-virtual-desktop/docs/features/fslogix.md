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

### FSLogix

If selected, this solution will deploy the required resources and configurations so that FSLogix is fully configured and ready for immediate use post deployment. Only Entra Domain Services and AD DS are supported in this solution. Entra ID support is in the backlog and will be added in a future release.

Azure Files and Azure NetApp Files are the only two SMB storage services available in this solution.  A management VM is deployed to facilitate the domain join of Azure Files (AD DS only) and configures the NTFS permissions on the share(s). With this solution, FSLogix containers can be configured in multiple ways:

- Cloud Cache Profile Container
- Cloud Cache Profile & Office Container
- Profile Container (Recommended)
- Profile & Office Container

**Reference:** [FSLogix - Microsoft Docs](https://learn.microsoft.com/fslogix/overview)

**Deployed Resources:**

- Azure Storage Account (Optional)
  - File Services
  - Share(s)
- Azure NetApp Account (Optional)
  - Capacity Pool
  - Volume(s)
- Virtual Machine
- Network Interface
- Disk
- Private Endpoint (Optional)
- Private DNS Zone (Optional)
