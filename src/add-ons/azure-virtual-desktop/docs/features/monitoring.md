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

### Monitoring

This feature deploys the required resources to enable the Insights workbook in the Azure Virtual Desktop blade in the Azure Portal.

**Reference:** [Azure Monitor for AVD - Microsoft Docs](https://learn.microsoft.com/azure/virtual-desktop/azure-monitor)

**Deployed Resources:**

- Log Analytics Workspace
- Data Collection Rule
- Azure Monitor Windows Agent
- Diagnostic Settings
  - Host Pool
  - Workspace
