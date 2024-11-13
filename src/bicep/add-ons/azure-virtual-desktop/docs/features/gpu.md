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

### GPU Drivers & Settings

When an appropriate VM size (Nv, Nvv3, Nvv4, or NCasT4_v3 series) is selected, this solution will automatically deploy the appropriate virtual machine extension to install the graphics driver and configure the recommended registry settings.

**Reference:** [Configure GPU Acceleration - Microsoft Docs](https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu)

**Deployed Resources:**

- Virtual Machines Extensions
  - AmdGpuDriverWindows
  - NvidiaGpuDriverWindows
- Run Command
