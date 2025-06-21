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

### High Availability

This optional feature will deploy the selected availability option and only provides high availability for "pooled" host pools since it is a load balanced solution.  Virtual machines can be deployed in either Availability Zones or Availability Sets, to provide a higher SLA for your solution.  SLA: 99.99% for Availability Zones, 99.95% for Availability Sets.  

**Reference:** [Availability options for Azure Virtual Machines - Microsoft Docs](https://learn.microsoft.com/azure/virtual-machines/availability)

**Deployed Resources:**

- Availability Set(s) (Optional)
