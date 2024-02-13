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

### Auto Increase Premium File Share Quota

When Azure Files Premium is selected for FSLogix, this feature is deployed automatically. This tool helps reduce cost by scaling the file share quota. Azure Files Premium is billed by the size of the quota, not the amount of data on the file share.

To benefit from the cost savings, select 100GB for your initial file share size.  For the first 500GB, the share will scale up 100 GB when only 50GB of quota remains.  Once the share has reached 500GB, the tool will scale up 500GB if less than 500GB of the quota remains.

**Reference:** [Azure Samples - GitHub Repository](https://github.com/Azure-Samples/azure-files-samples/tree/master/autogrow-PFS-quota)

**Deployed Resources:**

- Automation Account
  - Diagnositics Setting (optional)
  - Job Schedules
  - Runbook
  - Schedules
  - System Assigned Identity
- Role Assignment
