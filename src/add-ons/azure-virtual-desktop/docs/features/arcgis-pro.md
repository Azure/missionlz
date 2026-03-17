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

### ArcGIS Pro

The MLZ development team collaborated with ESRI to create a "profile" option in the AVD add-on deployment. This option enables ESRI's best practices in deploying ArcGIS Pro on Azure. The OS image is hardcoded to use ESRI's marketplace image containing Windows 11 Enterprise Multi-session with ArcGIS Pro. Microsoft's best practices in deploying GPU VMs on AVD are also included in the feature.

**Deployed Resources:**

- Virtual Machine(s)
  - GPU VM size validated by ESRI
  - ESRI's marketplace image containing ArcGIS Pro
  - Recommended graphics acceleration settings
  - VM extension with GPU (GRID) driver
