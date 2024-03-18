# Welcome to the ArcGIS on Azure with Azure Virtual Desktop (AVD) Landing Zone Accelerator

Azure Landing Zone Accelerators are architectural guidance, reference architecture, reference implementations and automation packaged to deploy workload platforms on Azure at scale and aligned with industry proven practices.

ArcGIS geospatial Landing Zone Accelerator represents the strategic design path and automated deployment options to deploy ESRI’s ArcGIS Enterprise on Azure and access it with ArcGIS Pro GPU enabled Azure virtual desktops.  This solution provides an architectural approach and reference implementation to prepare Azure subscriptions for a scalable ArcGIS implementation on Azure, utilizing a combination of Azure cloud native services and traditional infrastructure virtual machines. For overall architectural guidance on deploying ArcGIS in Azure , check out the Azure Architetcure Center documentation -> [Deploy Esri ArcGIS Pro in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop).

Below is a diagram of the components of this solution.

<img src="https://github.com/Borg-GitHub/ArcGIS-on-Azure-with-AVD/blob/main/images/ArcGIS-on-Azure.jpg">

The ArcGIS on Azure Landing Zone Accelerator is modular and designed to be usable for organizations that have no Azure infrastructure, as well as those who already have assets in Azure. The path is comprised of three steps, each  may be done sequentially, or not at all depending upon the requierments of your project.

:arrow_forward: The first step is to deploy [Enterprise-Scale foundation](https://github.com/Azure/Enterprise-Scale/blob/main/docs/reference/wingtip/README.md). This allows organizations to start with a foundational landing zone that supports their application portfolios, regardless of whether the applications are being migrated or are newly developed and deployed to Azure. The architecture enables organizations to start as small as needed and scale alongside their business requirements. If you allready have an LZ you can skip this step. For more on what an Azure Landing Zone is, see here -> [Azure Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone).

 :arrow_forward: The second step is to deploy the [ArcGIS on Azure accelerator](https://github.com/Borg-GitHub/ArcGIS-on-Azure-with-AVD). Esri's technology is a geographic information system (GIS) that contains capabilities for the visualization, analysis, and data management of geospatial data. Esri's core technology is called the ArcGIS platform. It includes capabilities for mapping, spatial analysis, 3D GIS, imagery and remote sensing, data collection and management, and field operations. For more information, see the [ArcGIS page on the Esri website](https://www.esri.com/en-us/arcgis/about-arcgis/overview).

There are two primary components to this component in this geospatial accelerator, ArcGIS Pro & ArcGIS Enterprise.

- ArcGIS Pro is a 64-bit professional desktop GIS application. GIS analysts can use it to perform spatial analysis and edit spatial data. GIS administrators can use it to create and publish geospatial services. This app will be deployed on the Windows 10 or 11 desktop virtual machines used as the Azure Virtual Desktop (AVD) hosts. Geospatial analysis in Azure is typicaly done on [GPU optimized](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-gpu) virtual desktops.

- ArcGIS Enterprise is a software system for GIS that powers mapping and visualization, analytics, and data management. It is the backbone for running the Esri suite of applications. ArcGIS Enterprise includes ArcGIS Server, which is the core web services component for making maps and performing analysis, and Portal for ArcGIS, which allows you to share maps, applications, and other geographic information with other people in your organization. ArcGIS Enterprise will be deployed and configured on Windows virtual machines in it's own landing zone as shown in the image above.

 :arrow_forward: The third step is to deploy the [Azure Virtual Desktop (AVD) accelerator](https://github.com/microsoft/AVDAccelerator), which represents the strategic design path and target technical state for Azure Virtual Desktop deployment. This solution provides an architectural approach and reference implementation to prepare landing zone subscriptions for a scalable Azure Virtual Desktop deployment. For the architectural guidance, check out [Enterprise-scale for Azure Virtual Desktop in Microsoft Docs](https://docs.microsoft.com/azure/cloud-adoption-framework/scenarios/wvd/enterprise-scale-landing-zone).

The Azure Virtual Desktop Accelerator only addresses what gets deployed in the specific Azure Virtual Desktop landing zone subscriptions, shown in the architectural diagram above. It is assumed that an appropriate platform foundation is already setup which may or may not be the official [ALZ platform foundation](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/implementation#reference-implementation). This means that policies and governance should already be in place. The policies applied to management groups in the hierarchy above the subscription will flow down to the Enterprise-scale for Azure Virtual Desktop landing zone subscriptions.

## Choosing a Deployment Model

The reference implementation is spread across three repos

1. The [Enterprise-Scale foundation landing zone accelerator](https://github.com/Azure/Enterprise-Scale/blob/main/docs/reference/wingtip/README.md)
1. This [ArcGIS on Azure accelerator](https://github.com/Borg-GitHub/ArcGIS-on-Azure-with-AVD)
1. The [Azure Virtual Desktop (AVD) accelerator](https://github.com/Azure/avdaccelerator)

## Enterprise-Scale foundation landing zone

If you are you just getting started in Azure and have no foundation in place, we reccomend deploying the **Enterprise-Scale foundation landing zone accelerator**. This Azure landing zone portal accelerator deploys the conceptual architecture shown above,  and applies predetermined configurations to key components such as management groups and policies. It suits organizations whose conceptual architecture aligns with the planned operating model and resource structure. This reference implementation is ideal for customers who want to start with Landing Zones for their workloads in Azure, where hybrid connectivity to their on-premises datacenter is not required from the start.

Please refer to [Enterprise-Scale Landing Zones User Guide](https://github.com/Azure/Enterprise-Scale/wiki/Deploying-Enterprise-Scale) for detailed information on prerequisites and deployment steps.

| ARM Template | Scale without refactoring |
|:--------------|:--------------|
|[![Deploy To Azure](https://learn.microsoft.com/azure/templates/media/deploy-to-azure.svg)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FEnterprise-Scale%2Fmain%2FeslzArm%2FeslzArm.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FEnterprise-Scale%2Fmain%2FeslzArm%2Feslz-portal.json) | Yes |

The Enterprise-Scale architecture is modular by design and allow organizations to start with foundational landing zones that support their application portfolios, regardless of whether the applications are being migrated or are newly developed and deployed to Azure. The architecture enables organizations to start as small as needed and scale alongside their business requirements regardless of scale point.

### Platform landing zones vs. application landing zones

An Azure landing zone consists of platform landing zones and application landing zones. It's worth explaining the function of both in more detail.

**Platform landing zone:** A platform landing zone is a subscription that provides shared services (identity, connectivity, management) to applications in application landing zones. Consolidating these shared services often improves operational efficiency. One or more central teams manage the platform landing zones. In the conceptual architecture (*see figure 1*), the "Identity subscription", "Management subscription", and "Connectivity subscription" represent three different platform landing zones. The conceptual architecture shows these three platform landing zones in detail. It depicts representative resources and policies applied to each platform landing zone.

**Application landing zone:** An application landing zone is a subscription for hosting an application. You pre-provision application landing zones through code and use management groups to assign policy controls to them. In the conceptual architecture above, the "ArcGIS-Multi Tier" and "ArcGIS-Single Tier" represent two different application landing zones.

## ArcGIS on Azure

In this ArcGIS on Azure acclerator, you have access to step by step guides covering various customer [scenarios](./Scenarios) that can help accelerate the development and deployment of ArcGIS on Azure which conform with best practices. This is a good starting point if you are **new** to Azure or Infrastructure-As-Code (IaC) . Each scenario aims to represent common customer use cases, with the goal of accelerating the deployment process using Infrastructure-As-Code (IaC) assets. They also provide a step by step learning experience for deploying well architected Azure environments.

### ArcGIS Enterprise base deployment single tier

This option will deploy ArcGIS Enterprise on one Virutal Server, which is suiteable for Prof-of-Concept implementations.

 <img src="https://github.com/Borg-GitHub/ArcGIS-on-Azure-with-AVD/blob/main/images/ArcGIS-on-Azure-Single-Tier.png">

| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) |

### ArcGIS Enterprise base deployment multi tier

This option will deploy ArcGIS Enterprise across multiple virtual machines, which is more suitable for production implementations which require high availability. 

#### Pre-Reqs

If deploying ArcGIS Enterprise please follow the below guidance and pre-req steps:

##### Upload the following scripts and files to your storage account container

* [Az.Accounts 2.13.1 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.Accounts/2.13.1)
* [Az.Automation 1.9.0 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.Automation/1.9.0)
* [Az.Compute 5.7.0 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.Compute/5.7.0)
* [Az.Resources 6.6.0 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.Resources/6.6.0)
* [Az.KeyVault 4.12.0 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.Resources/6.6.0)
* [Az.Storage 5.1.0 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.Storage/5.1.0)
* [Az.MarketplaceOrdering 2.0.0 PowerShell Module](https://www.powershellgallery.com/api/v2/package/Az.MarketplaceOrdering/2.0.0)
* [PFX Certificate for ESRI Enterprise that is password protected](https://enterprise.arcgis.com/en/server/latest/administer/windows/best-practices-for-server-certificates.htm)

<img src="https://github.com/Borg-GitHub/ArcGIS-on-Azure-with-AVD/blob/main/images/ArcGIS-on-Azure-multi-tier.png">

| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) |

## Azure Virtual Desktop (AVD) accelerator

Azure Virtual Desktop Landing Zone Accelerator (LZA) represents the strategic design path and target technical state for Azure Virtual Desktop deployment. This solution provides an architectural approach and reference implementation to prepare landing zone subscriptions for a scalable Azure Virtual Desktop deployment. For the architectural guidance, check out Enterprise-scale for Azure Virtual Desktop in Microsoft Docs.

The Azure Virtual Desktop Landing Zone Accelerator (LZA) only addresses what gets deployed in the specific Azure Virtual Desktop landing zone subscriptions, as shown in the architectural diagram above. It is assumed that an appropriate platform foundation is already setup which may or may not be the official ALZ platform foundation. This means that policies and governance should already be in place prior to deploying Azure Virtual Desktop . The policies applied to management groups in the hierarchy above the subscription will flow down to the Enterprise-scale for Azure Virtual Desktop landing zone subscriptions.

### Azure Virtual Desktop - LZA - Baseline

[Getting Started](/workload/docs/getting-started-baseline.md) deploying Azure Virtual Desktop (AVD) resources and dependent services for establishing the baseline

- Azure Virtual Desktop resources: workspace, two (2) application groups, scaling plan and a host pool
- [Optional]: new virtual network (VNet) with NSGs, ASG and route tables
- Azure Files with Integration to the identity service
- Key vault
- Session Hosts

| Deployment Type | Link |
|:--|:--|
| Azure portal UI |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Farm%2Fdeploy-baseline.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Fportal-ui%2Fportal-ui-baseline.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Farm%2Fdeploy-baseline.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Fportal-ui%2Fportal-ui-baseline.json)|
| Command line (Bicep/ARM) | [![Powershell/Azure CLI](./images/powershell.png)](./workload/bicep/readme.md#avd-accelerator-baseline) |
| Terraform | [![Terraform](./images/terraform.png)](./workload/terraform/greenfield/readme.md) |

[Brownfield deployments](/workload/brownfieldReadme.md) deploy new features to existing Azure Virtual Desktop deployments.

### Azure Virtual Desktop - LZA - Custom image build (Optional)

[Getting Started](/workload/docs/getting-started-custom-image-build.md) deploying a custom image based on the latest version of the Azure marketplace image to an Azure Compute Gallery. The following images are offered:

- Windows 10 21H2
- Windows 10 22H2 (Gen 2)
- Windows 11 21H2 (Gen 2)
- Windows 11 22H2 (Gen 2)
- Windows 10 21H2 with O365
- Windows 10 22H2 with O365 (Gen 2)
- Windows 11 21H2 with O365 (Gen 2)
- Windows 11 22H2 with O365 (Gen 2)

You can also select to enable the Trusted Launch or Confidential VM security type feature on the Azure Compute Gallery image definition.

Custom image is optimized using [Virtual Desktop Optimization Tool (VDOT)](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool) and patched with the latest Windows updates.

| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Farm%2Fdeploy-custom-image.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Fportal-ui%2Fportal-ui-custom-image.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Farm%2Fdeploy-custom-image.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Favdaccelerator%2Fmain%2Fworkload%2Fportal-ui%2Fportal-ui-custom-image.json) |
| Command line (Bicep/ARM) | [![Powershell/Azure CLI](./images/powershell.png)](./workload/bicep/readme.md#optional-custom-image-build-deployment) |
| Terraform | [![Terraform](./images/terraform.png)](./workload/terraform/customimage) |

If you would like step by step guidance on how to deploy  ESRI’s ArcGIS Enterprise on Azure and access it with ArcGIS Pro GPU enabled Azure virtual desktops, check out the Azure Architetcure Center documentation -> [Deploy Esri ArcGIS Pro in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop).

## More options for quick start automated deployments for Azure Landing Zones

:arrow_forward: [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

:arrow_forward: [Implement Cloud Adoption Framework enterprise-scale landing zones in Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/implementation)

### Or check out one of our other application Landing Zone Accelerators

:arrow_forward: [Deploy Azure application landing zones](https://learn.microsoft.com/en-us/azure/architecture/landing-zones/landing-zone-deploy#application)
