# Welcome to the ArcGIS on Azure with Azure Virtual Desktop (AVD) Landing Zone Accelerator

> [!CAUTION]
> This repository is a WORK-IN-PROGRESS and is not yet fully complete.  

Azure Landing Zone Accelerators are architectural guidance, reference architecture, reference implementations, and automation packaged to deploy workload platforms on Azure at scale and aligned with industry proven practices. This accelerator represents the strategic design path and automated deployment options to deploy Esri’s ArcGIS Enterprise with ArcGIS Pro GPU enabled virtual desktops.

This solution provides an architectural approach and reference implementation to prepare Azure subscriptions for a scalable ArcGIS implementation on Azure, utilizing a combination of Azure cloud native services and traditional infrastructure virtual machines. Once the deployment is completed, users of this accelerator will have a base deployment which enables a rapid deployment of an Enterprise GIS.

For overall architectural guidance on deploying ArcGIS in Azure, check out the Azure Architecture Center documentation -> [Deploy Esri ArcGIS Pro in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop). Also, see [Esri's ArcGIS Architecture Center](https://architecture.arcgis.com/).

Below is a diagram of the components of this solution.

![ArcGIS on Azure diagram](./images/ArcGIS-on-Azure.svg)

The ArcGIS on Azure Landing Zone Accelerator is modular and designed to be usable for organizations that have no Azure infrastructure, as well as those who already have assets in Azure. The path is comprised of four steps, each  may be done sequentially, or not at all depending upon the requierments of your project. However, let's first discuss landing zones.

## What is a Landing Zone?

A [**landing zone**](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone)  is networking & infrastructure configured to provide a secure environment for hosting workloads.

An Azure landing zone consists of platform landing zones and application landing zones.

**Platform landing zone:** A platform landing zone is a subscription that provides shared services (identity, connectivity, management) to applications in application landing zones. Consolidating these shared services often improves operational efficiency. One or more central teams manage the platform landing zones.

**Application landing zone:** An application landing zone is a subscription for hosting an application. You pre-provision application landing zones through code and use management groups to assign policy controls to them. In the conceptual architecture above, the ArcGIS Enterprise Single Machine or Multiple-Machine deployments represent two different application landing zones.

Reference: [ArcGIS Enterprise Single Machine or Multiple-Machine](https://enterprise.arcgis.com/en/server/latest/install/windows/deployment-scenarios.htm)

## ArcGIS on Azure

In this ArcGIS on Azure accelerator, you have access to step by step guides covering various customer scenarios that can help accelerate the deployment of ArcGIS on Azure which conforms with best practices. This is a good starting point if you are **new** to Azure or Infrastructure-As-Code (IaC) . Each scenario represents common use cases, with the goal of accelerating the deployment process.

### ArcGIS Enterprise base deployment single-tier

This option will deploy ArcGIS Enterprise on one Virutal Server, which is suiteable for Prof-of-Concept implementations.

![alt text](images/ArcGIS-on-Azure-Single-Tier.png)

<!-- markdownlint-disable MD013 -->
| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) |
<!-- markdownlint-enable MD013 -->

### ArcGIS Enterprise base deployment multi-tier

This option will deploy ArcGIS Enterprise across multiple virtual machines, which is more suitable for production implementations which require high availability.

![alt text](images/ArcGIS-on-Azure-multi-tier.png)

<!-- markdownlint-disable MD013 -->
| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) |
<!-- markdownlint-enable MD033 -->

If you would like step by step guidance on how to deploy ESRI’s ArcGIS Enterprise on Azure and access it with ArcGIS Pro GPU enabled Azure virtual desktops, check out the Azure Architecture Center documentation: [Deploy Esri ArcGIS Pro in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop).

## More options for quick start automated deployments for Azure Landing Zones

:arrow_forward: [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

:arrow_forward: [Implement Cloud Adoption Framework enterprise-scale landing zones in Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/implementation)

### Or check out one of our other application Landing Zone Accelerators

:arrow_forward: [Deploy Azure application landing zones](https://learn.microsoft.com/en-us/azure/architecture/landing-zones/landing-zone-deploy#application)
