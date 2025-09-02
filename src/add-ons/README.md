# Mission Landing Zone Add-Ons

[**Home**](../../../README.md) | [**Design**](../../../docs/design.md) | [**Add-Ons**](./README.md) | [**Resources**](../../../docs/resources.md)

This directory contains add-ons to extend the functionality of Mission Landing Zone. These add-ons are reference implementations aligned with industry proven practices, and automation packaged to deploy workload platforms on Azure at scale. Each add-on creates a tier3 spoke virtual network that is peered to the hub virtual network. These add-ons were developed to adhere to the SCCA and zero-trust guidelines.

## Add-Ons

Name   | Description
------ | -----------
[ArcGIS Pro](./arcgis-pro/README.md) | Deploys Mission Landing Zone, the Azure Virtual Desktop, and ArcGIS Enterprise in a single click deployment.
[Azure NetApp Files](./azure-netapp-files/README.md) | Allows for the deployment of Azure NetApp Files with an SMB file share.
[Azure Virtual Desktop](./azure-virtual-desktop/README.md) | Deploys Azure Virtual Desktop stamps in either generic or ArcGIS Pro configurations with FSLogix, AutoScale, AVD Insights, and more.
[NAT Gateway](./nat-gateway/README.md) | Deploys a NAT Gateway and attaches it to AzureFirewallSubnet for hub egress
[Policy Guardrails Tool](./policy-guardrails-tool/readMe.md) | Deploys Azure Policy guardrails at the subscription scope.
[Tier3](./tier3/README.md) | Deploys a spoke network peered to the hub in preparation for the manual deployment of a workload.
[VPN Gateway](./virtual-network-gateway/README.md) | Deploys a VPN Gateway for site-to-site connectivity and hub routing.
[Zero Trust Imaging](./imaging/README.md) | Deploys images in an Azure Compute Gallery using a zero trust configuration with several configuration options.
[Zero Trust (TIC3.0) Workbook](./zero-trust-workbook) | Deploys an Azure Sentinel Zero Trust (TIC3.0) Workbook

<!--[ArcGIS Enterprise](./arcgis-enterprise) | Deploys ESRI's ArcGIS Enterprise solution, based off their cloud builder product.-->
<!--[IaaS DNS Forwarders](./iaas-dns-forwarders) | Deploys DNS Forwarder Virtual Machines in the HUB, for proper resolution of Private Endpoint and internal domains accross all Virtual Networks-->
