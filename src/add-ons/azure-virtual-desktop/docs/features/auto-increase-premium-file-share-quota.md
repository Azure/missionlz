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
