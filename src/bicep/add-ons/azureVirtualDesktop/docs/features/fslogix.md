# Azure Virtual Desktop Solution

[**Home**](../../README.md) | [**Features**](../features.md) | [**Design**](../design.md) | [**Prerequisites**](../prerequisites.md) | [**Troubleshooting**](../troubleshooting.md)

## Features

- [**Auto Increase Premium File Share Quota**](./autoIncreasePremiumFileShareQuota.md#auto-increase-premium-file-share-quota)
- [**Backups**](./backups.md#backups)
- [**Drain Mode**](./drainMode.md#drain-mode)
- [**FSLogix**](./fslogix.md#fslogix)
- [**GPU Drivers & Settings**](./gpu.md#gpu-drivers--settings)
- [**High Availability**](./highAvailability.md#high-availability)
- [**Monitoring**](./monitoring.md#monitoring)
- [**Scaling Tool**](./scalingTool.md#scaling-tool)
- [**Server-Side Encryption with Customer Managed Keys**](./serverSideEncryption.md#server-side-encryption)
- [**SMB Multichannel**](./smbMultiChannel.md#smb-multichannel)
- [**Start VM On Connect**](./startVmOnConnect.md#start-vm-on-connect)
- [**Trusted Launch**](./trustedLaunch.md#trusted-launch)
- [**Validation**](./validation.md#validation)

### FSLogix

If selected, this solution will deploy the required resources and configurations so that FSLogix is fully configured and ready for immediate use post deployment. Only Azure AD DS and AD DS are supported in this solution. Azure AD support is in "Public Preview" and will added after it is "Generally Available". Azure Files and Azure NetApp Files are the only two SMB storage services available in this solution.  A management VM is deployed to facilitate the domain join of Azure Files (AD DS only) and configures the NTFS permissions on the share(s). Azure Files can be deployed with either a public endpoint, [service endpoint](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-overview#public-endpoint-firewall-settings), or [private endpoint](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-overview#private-endpoints). With this solution, FSLogix containers can be configured in multiple ways:

- Cloud Cache Profile Container
- Cloud Cache Profile & Office Container
- Profile Container (Recommended)
- Profile & Office Container

**Reference:** [FSLogix - Microsoft Docs](https://docs.microsoft.com/en-us/fslogix/overview)

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
