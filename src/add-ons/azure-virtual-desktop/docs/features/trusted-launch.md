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

### Trusted Launch

This feature is enabled automatically with the safe boot and vTPM settings when the following conditions are met:

- a generation 2, "g2", image SKU is selected
- the VM size supports the feature

It is a security best practice to enable this feature to protect your virtual machines from:

- boot kits
- rootkits
- kernel-level malware

**Reference:** [Trusted Launch - Microsoft Docs](https://learn.microsoft.com/azure/virtual-machines/trusted-launch)

**Deployed Resources:**

- Virtual Machines
  - Guest Attestation extension
