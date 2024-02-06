# Welcome to the ArcGIS on Azure with Azure Virtual Desktop (AVD) Landing Zone Accelerator

Azure Landing Zone Accelerators are architectural guidance, reference architecture, reference implementations and automation packaged to deploy workload platforms on Azure at scale and aligned with industry proven practices.

This ArcGIS Landing Zone Accelerator represents the strategic design path and automated deployment options to deploy Esri’s ArcGIS Enterprise on Azure and access it with ArcGIS Pro GPU enabled Azure virtual desktops. This solution provides an architectural approach and reference implementation to prepare Azure subscriptions for a scalable ArcGIS implementation on Azure, utilizing a combination of Azure cloud native services and traditional infrastructure virtual machines. For overall architectural guidance on deploying ArcGIS in Azure, check out the Azure Architetcure Center documentation -> [Deploy Esri ArcGIS Pro in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop). Also, see [Esri's ArcGIS Architecture Center](https://architecture.arcgis.com/).

Below is a diagram of the components of this solution.

<img src="https://github.com/Borg-GitHub/missionlz-esri/blob/main/docs/images/ArcGIS-on-Azure.jpg">

The ArcGIS on Azure Landing Zone Accelerator is modular and designed to be usable for organizations that have no Azure infrastructure, as well as those who already have assets in Azure. The path is comprised of four steps, each  may be done sequentially, or not at all depending upon the requierments of your project.

## What is a Landing Zone?

A [**landing zone**](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone)  is networking & infrastructure configured to provide a secure environment for hosting workloads.

An Azure landing zone consists of platform landing zones and application landing zones. 

**Platform landing zone:** A platform landing zone is a subscription that provides shared services (identity, connectivity, management) to applications in application landing zones. Consolidating these shared services often improves operational efficiency. One or more central teams manage the platform landing zones.

**Application landing zone:** An application landing zone is a subscription for hosting an application. You pre-provision application landing zones through code and use management groups to assign policy controls to them. In the conceptual architecture above, the ArcGIS Enterprise [Single Machine or Multiple-Machine](https://enterprise.arcgis.com/en/server/latest/install/windows/deployment-scenarios.htm) deployments represent two different application landing zones.

<br>

:arrow_forward: The first step is to deploy [Mission Landing Zone](https://github.com/Azure/missionlz/blob/main/README.md). This allows organizations to start with a foundational landing zone that supports their application portfolios, regardless of whether the applications are being migrated or are newly developed and deployed to Azure. Mission Landing Zone is a highly opinionated Infrastructure-as-Code (IaC) template which IT oversight organizations can use to create a cloud management system to deploy Azure environments for their workloads and teams.
Mission Landing Zone provides a Secure Cloud Computing Architecture (SCCA) compliant hub and spoke infrastructure. If you allready have an Azure Landing Zone you can skip this step. For more on what an Azure Landing Zone is, see here -> [Azure Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone).

There are two primary components to this component in this geospatial accelerator, ArcGIS Pro & ArcGIS Enterprise.

- ArcGIS Pro is a 64-bit professional desktop GIS application. GIS analysts can use it to perform spatial analysis and edit spatial data. GIS administrators can use it to create and publish geospatial services. This app will be deployed on the Windows 10 or 11 desktop virtual machines used as the Azure Virtual Desktop (AVD) hosts. Geospatial analysis in Azure is typicaly done on [GPU optimized](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-gpu) virtual desktops.

- ArcGIS Enterprise is a software system for GIS that powers mapping and visualization, analytics, and data management. It is the backbone for running the Esri suite of applications. ArcGIS Enterprise includes ArcGIS Server, which is the core web services component for making maps and performing analysis, and Portal for ArcGIS, which allows you to share maps, applications, and other geographic information with other people in your organization. ArcGIS Enterprise will be deployed and configured on Windows virtual machines in it's own landing zone as shown in the image above.

<br>

 :arrow_forward: The second step is to create the Windows image which will be used to create the Azure Virtual Desktops. This image will have ArcGIS Pro pre-installed when you use this template ->  [Zero Trust and Azure Imaging](https://github.com/Azure/missionlz/tree/main/src/bicep/add-ons/Imaging/README.MD). 

<br>

 :arrow_forward: The third step is to deploy the Azure Virtual Desktop (AVD) solution will provide a fully operational [stamp](https://learn.microsoft.com/azure/architecture/patterns/deployment-stamp) in an Azure subscription adhereing to the [Zero Trust principles](https://learn.microsoft.com/security/zero-trust/azure-infrastructure-avd). This template represents the strategic design path and target technical state for Azure Virtual Desktop deployment. Many of the [common features](./docs/features.md) used with AVD have been automated in this solution for your convenience. Be sure to complete the necessary [prerequisites](./docs/prerequisites.md) and to review the parameter descriptions to the understand the consequences of your selections.

This Azure Virtual Desktop Accelerator only addresses what gets deployed in the specific Azure Virtual Desktop landing zone subscriptions, shown in the architectural diagram above. It is assumed that an appropriate landing zone foundation is already setup. This means that policies and governance should already be in place.

<br>

> [!WARNING]
> Failure to complete the [prerequisites](./docs/prerequisites.md) will result in an unsuccessful deployment.

<br>
 :arrow_forward: The fourth step is to run the ArcGIS Enterprise on Azure accelerator. This automation template will setup Esri's ArcGIS Enterprise in either the single tier or multi tier configuration as shown in the diagrams.  Esri's technology is a geographic information system (GIS) that contains capabilities for the visualization, analysis, and data management of geospatial data. Esri's core technology is called [ArcGIS](https://www.esri.com/en-us/arcgis/about-arcgis/overview). It includes capabilities for mapping, spatial analysis, 3D GIS, imagery and remote sensing, data collection and management, and field operations. 

<br>
<br>

## Choosing a Deployment Model

The below automation templates can be deployed in your Azure subscriptions by clicking the blue buttons.  

<br>

## Mission Landing Zone

[Mission Landing Zone](https://github.com/Azure/missionlz/blob/main/README.md) is a highly opinionated Infrastructure-as-Code (IaC) template which IT organizations can use to create a cloud management system in Azure for their workloads and teams. Mission Landing Zone provides a Secure Cloud Computing Architecture (SCCA) compliant hub and spoke infrastructure.

<!-- markdownlint-disable MD013 -->
1. Deploy Mission Landing Zone into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | :--- | :--- |
    | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
<!-- markdownlint-enable MD013 -->


<br>

## Zero Trust and Azure Imaging

This [Zero Trust and Azure Imaging](https://github.com/Azure/missionlz/tree/main/src/bicep/add-ons/Imaging/README.MD)
solution for Azure allows you create images in an Azure environment that adheres to zero trust. While other options exist in Azure, they are either a manual processes or do not adhere to zero trust. This solution uses a storage account with a private endpoint to store applications and the existing, preconfigured resources that comply with Zero Trust principles. This solution will enable you to create an Windows image for Azure virtual desktop that comes with ArcGIS Pro pre installed.   

<!-- markdownlint-disable MD013 -->
1. Deploy Zero Trust Imaging into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | :--- | :--- |
    [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FImaging%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FImaging%2FuiDefinition.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FImaging%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FImaging%2FuiDefinition.json) |
<!-- markdownlint-enable MD013 -->

<br>

## The Azure Virtual Desktop (AVD) solution

The [Azure Virtual Desktop (AVD) solution](https://github.com/jamasten/AzureVirtualDesktop/blob/main/README.md) provides an architectural approach and reference implementation to prepare landing zone subscriptions for a scalable Azure Virtual Desktop deployment. The Azure Virtual Desktop Landing Zone Accelerator (LZA) only addresses what gets deployed in the specific Azure Virtual Desktop landing zone subscriptions, as shown in the architectural diagram above. It is assumed that an appropriate Azure landing zone foundation is already setup.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureVirtualDesktop%2Fmain%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureVirtualDesktop%2Fmain%2FuiDefinition.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureVirtualDesktop%2Fmain%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureVirtualDesktop%2Fmain%2FuiDefinition.json)

<br>

## ArcGIS on Azure

In this ArcGIS on Azure acclerator, you have access to step by step guides covering various customer [scenarios](./Scenarios) that can help accelerate the development and deployment of ArcGIS on Azure which conform with best practices. This is a good starting point if you are **new** to Azure or Infrastructure-As-Code (IaC) . Each scenario aims to represent common customer use cases, with the goal of accelerating the deployment process using Infrastructure-As-Code (IaC) assets.

### ArcGIS Enterprise base deployment single tier

This option will deploy ArcGIS Enterprise on one Virutal Server, which is suiteable for Prof-of-Concept implementations.

 <img src="https://github.com/Borg-GitHub/missionlz-esri/blob/main/docs/images/ArcGIS-on-Azure-Single-Tier.png">

| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FBorg-GitHub%2FArcGIS-on-Azure-with-AVD%2Fmain%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FBorg-GitHub%2FArcGIS-on-Azure-with-AVD%2Fmain%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FBorg-GitHub%2FArcGIS-on-Azure-with-AVD%2Fmain%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FBorg-GitHub%2FArcGIS-on-Azure-with-AVD%2Fmain%2FuiDefinition.json) |

### ArcGIS Enterprise base deployment multi tier

This option will deploy ArcGIS Enterprise across multiple virtual machines, which is more suitable for production implementations which require high availability.

<img src="https://github.com/Borg-GitHub/missionlz-esri/blob/main/docs/images/ArcGIS-on-Azure-multi-tier.png">

| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Farm%2Fdeploy-custom-image.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Fportal-ui%2Fportal-ui-custom-image.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Farm%2Fdeploy-custom-image.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Fportal-ui%2Fportal-ui-custom-image.json) |


If you would like step by step guidance on how to deploy  ESRI’s ArcGIS Enterprise on Azure and access it with ArcGIS Pro GPU enabled Azure virtual desktops, check out the Azure Architetcure Center documentation -> [Deploy Esri ArcGIS Pro in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop).

## More options for quick start automated deployments for Azure Landing Zones

:arrow_forward: [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

:arrow_forward: [Implement Cloud Adoption Framework enterprise-scale landing zones in Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/implementation)

### Or check out one of our other application Landing Zone Accelerators

:arrow_forward: [Deploy Azure application landing zones](https://learn.microsoft.com/en-us/azure/architecture/landing-zones/landing-zone-deploy#application)

