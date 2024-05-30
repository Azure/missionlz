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

### Start VM On Connect

This optional feature allows your end users to turn on a session host when all the session hosts have been stopped / deallocated. This is done automatically when the end user opens the AVD client and attempts to access a resource.  Start VM On Connect compliments scaling solutions by ensuring the session hosts can be turned off to reduce cost but made available when needed.

**Reference:** [Start VM On Connect - Microsoft Docs](https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect?tabs=azure-portal)

**Deployed Resources:**

- Role Assignment
- Host Pool
