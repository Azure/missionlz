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

### Scaling Tool

This feature is deployed if selected to help save on cost.  Based on the desired configuration, session hosts will scale up during peak hours and shutdown after peak hours.  It is recommended to use policies to manage idle and disconnected over using the built-in capability in this tool. In this solution, a managed identity is deployed on the Automation Account to reduce the privileges needed for tool.

**Reference:** [Scaling Tool - Microsoft Docs](https://docs.microsoft.com/en-us/azure/virtual-desktop/scaling-automation-logic-apps)

**Deployed Resources:**

- Automation Account
  - Diagnostic Setting (optional)
  - Job Schedules
  - Runbook
  - Schedules
  - System Assigned Identity
- Role Assignment
