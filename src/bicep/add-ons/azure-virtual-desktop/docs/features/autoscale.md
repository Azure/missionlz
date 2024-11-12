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

### Autoscale

This feature is deployed to help reduce the cost of your pooled or personal host pools by turning off session hosts during your off peak hours.  It is recommended to use policies to manage idle and disconnected sessions, over using the built-in capability in this tool. Many of the settings have been preconfigured. Adjust the scaling plan resource post deployment to fine the settings.

**Reference:** [Autoscale - Microsoft Docs](https://learn.microsoft.com/azure/virtual-desktop/autoscale-scenarios)

**Deployed Resources:**

- Scaling Plan
- Role Assignment
