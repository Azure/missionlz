# Mission Landing Zone Add-Ons

[**Home**](../../../README.md) | [**Design**](../../../docs/design.md) | [**Add-Ons**](./README.md) | [**Resources**](../../../docs/resources.md)

This directory contains add-ons to extend the functionality of Mission Landing Zone. These add-ons are reference implementations aligned with industry proven practices, and automation packaged to deploy workload platforms on Azure at scale. Each add-on creates a tier3 spoke virtual network that is peered to the hub virtual network. These add-ons were developed to adhere to the SCCA and zero-trust guidelines.

## Add-Ons

Name   | Description
------ | -----------
[Azure Virtual Desktop](./azure-virtual-desktop/README.md) | Allows for the deployment of Zero Trust, SCCA compliant stamps of Azure Virtual Desktop.
[ESRI Accelerator](../../../docs/esri.md) | Allows for the deployment of both ArcGIS Pro on Azure Virtual Desktop & ESRI Enterprise.
[Tier3](./tier3/README.md) | Deploys a spoke network peered to the hub in preparation for the manual deployment of a workload.
[Zero Trust Imaging](./imaging/README.md) | Enables users to create customizable, zero trust images.

<!--[AKS](./aks) | Deploys an AKS cluster.
[App Service Plan](./app-service-plan) | Deploys an App Service Plan (AKA: Web Server Cluster) to support simple web accessible linux docker containers with optional dynamic auto scaling.
[Automation Account](./automation-account) | Deploys an Azure Automation account that can be used to execute runbooks.
[Container Registry](./container-registry/) | Deploys an Azure Container Registry for holding and deploying docker containers.
[Inherit Tags](./inherit-tags) | Adds or replaces a specified tag and value from the parent resource group when any resource is created or updated.
[KeyVault](./key-vault/) | Deploys a premium Azure Key Vault with RBAC enabled to support secret, key, and certificate management.
[Zero Trust (TIC3.0) Workbook](./zero-trust-workbook) | Deploys an Azure Sentinel Zero Trust (TIC3.0) Workbook
[IaaS DNS Forwarders](./iaas-dns-forwarders) | Deploys DNS Forwarder Virtual Machines in the HUB, for proper resolution of Private Endpoint and internal domains accross all Virtual Networks-->
