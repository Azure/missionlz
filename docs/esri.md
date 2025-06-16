
# Esri ArcGIS Pro on Azure Virtual Desktop (AVD) Accelerator

> [!CAUTION]
> This repository is a WORK-IN-PROGRESS and is not yet fully complete.  

## Quick Start Summary

- **Scenario 1:** [ArcGIS Pro on Azure Virtual Desktop (AVD)](#scenario-1-arcgis-pro-on-avd)
- **Scenario 2:** [Single-Tier Deployment (ArcGIS Enterprise + ArcGIS Pro on AVD)](#scenario-2-single-tier-deployment-arcgis-enterprise--arcgis-pro-on-avd)
- **Scenario 3:** [Multi-Tier Deployment (ArcGIS Enterprise + ArcGIS Pro on AVD)](#scenario-3-multi-tier-deployment-arcgis-enterprise--arcgis-pro-on-avd)
- **Who Would Use Each:** [Guidance on Choosing the Right Deployment Scenario](#who-would-use-each)

## Solution Description

This accelerator offers an architectural approach and reference implementation to prepare Azure subscriptions for scalable ArcGIS deployments. It combines Azure cloud-native services and traditional infrastructure virtual machines. Upon completion, users will have a base deployment for rapid enterprise GIS adoption.

### Who is this for?

This accelerator is designed for GIS administrators, IT/cloud architects, and organizations looking to modernize their GIS infrastructure by leveraging Azure's scalability, performance, and security. Whether you're migrating from on-premises or expanding your cloud footprint, this solution provides the tools and guidance needed for successful deployment.

### Major Benefits

This accelerator provides a modern, cloud-native foundation for deploying ArcGIS Pro and ArcGIS Enterprise on Azure. Benefits span both desktop GIS performance and enterprise GIS infrastructure modernization:

### 🔷 ArcGIS Pro on Azure Virtual Desktop (AVD)

- **Enhanced Performance:** GPU-enabled virtual desktops deliver fast rendering and processing for complex 2D/3D geospatial workflows.
- **Remote Access:** Users can securely access ArcGIS Pro from anywhere, enabling hybrid and distributed teams.
- **Cost Optimization:** Flexible pricing with pooled or personal desktops reduces idle capacity and aligns with usage patterns.
- **Simplified Management:** Centralized provisioning, updates, and policy enforcement streamline IT operations.

### ☁️ ArcGIS Enterprise on Azure

- **Elastic Scalability:** Easily scale compute, storage, and services to meet growing user and data demands — without hardware constraints.
- **High Availability & Resilience:** Azure-native features like availability zones, load balancing, and backup services improve uptime and disaster recovery.
- **Security & Compliance:** Benefit from Azure’s enterprise-grade security, identity integration (Microsoft Entra ID), and compliance certifications.
- **Operational Efficiency:** Automate deployments with infrastructure-as-code (Bicep/ARM), reducing manual setup and configuration time.
- **Global Reach:** Deploy closer to your users with Azure’s global data center footprint, improving performance and reducing latency.
- **Integration Ready:** Seamlessly connect ArcGIS Enterprise with other Azure services (e.g., Azure SQL, Azure Maps, AI/ML tools) for advanced workflows.

## Components

This accelerator is designed to be deployed **after** the [Mission Landing Zone](https://github.com/Azure/missionlz) has been set up. The Mission Landing Zone provides the foundational Azure infrastructure (identity, networking, security, and governance) required to support ArcGIS workloads.

Once the Mission Landing Zone is deployed, you can choose from three deployment scenarios depending on your needs:

- **Scenario 1:** ArcGIS Pro on Azure Virtual Desktop (AVD)
- **Scenario 2:** Single-Tier ArcGIS Enterprise + ArcGIS Pro on AVD
- **Scenario 3:** Multi-Tier ArcGIS Enterprise + ArcGIS Pro on AVD

Each scenario is self-contained and can be deployed independently, depending on your organization's GIS architecture and operational goals.

![ArcGIS on Azure diagram](./images/ArcGIS-on-Azure_Updated.png)

## Scenario 1: ArcGIS Pro on AVD

ArcGIS Pro on Azure Virtual Desktop (AVD) provides a modern, cloud-based solution for delivering high-performance GIS desktops to users anywhere. This deployment scenario focuses on enabling GIS professionals to access GPU-accelerated ArcGIS Pro sessions remotely, without the need for local high-end hardware.

This scenario is ideal for organizations that:

- Need to provide remote access to ArcGIS Pro for distributed teams or hybrid workforces.
- Want to leverage GPU-enabled virtual desktops for intensive 2D/3D geospatial analysis and visualization.
- Require flexible, scalable desktop environments that can be pooled or assigned per user.

**Benefits:**

- **Remote Productivity:** Users can access ArcGIS Pro from virtually anywhere, enabling collaboration across geographies.
- **GPU Acceleration:** Delivers high-performance rendering and analysis for demanding GIS workflows.
- **Centralized Management:** Simplifies IT operations with centralized updates, security policies, and user provisioning.
- **Cost Optimization:** Offers flexible pricing models with pooled or personal desktops to match usage patterns.
- **Secure Access:** Integrates with Microsoft Entra ID and supports conditional access, MFA, and other enterprise-grade security features.

<!-- markdownlint-disable MD013 -->
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json)
<!-- markdownlint-enable MD013 -->

## Scenario 2: Single-Tier Deployment (ArcGIS Enterprise + ArcGIS Pro on AVD)

The single-tier ArcGIS Enterprise deployment involves installing all components of ArcGIS Enterprise on a single virtual machine. This setup is straightforward and suitable for smaller implementations or proof-of-concept projects. It is ideal for organizations that:

- Have limited resources and need a simple, cost-effective solution.
- Are conducting a proof-of-concept, testing or development.
- Do not require high availability or scalability.

**Benefits:**

- **Simplicity:** Easier to set up and manage since all components are on one machine.
- **Cost-Effective:** Lower infrastructure costs as it requires fewer resources.
- **Quick Deployment:** Faster to deploy and configure, making it suitable for short-term projects.

<!-- markdownlint-disable MD013 -->
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json)
<!-- markdownlint-enable MD013 -->

## Scenario 3: Multi-Tier Deployment (ArcGIS Enterprise + ArcGIS Pro on AVD)

A multi-tier deployment involves distributing the components of ArcGIS Enterprise across multiple virtual machines. This setup is more complex but offers better performance, scalability, and high availability. It is ideal for organizations that:

- Require a robust and scalable solution for production environments.
- Need to support a large number of users and high-demand applications.
- Require high availability and disaster recovery capabilities.

**Benefits:**

- **Scalability:** Can handle larger workloads and more users by distributing components across multiple machines.
- **High Availability:** Provides redundancy and failover capabilities, ensuring continuous operation.
- **Performance:** Improved performance as different components can be optimized and scaled independently.

<!-- markdownlint-disable MD013 -->
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fesri-enterprise%2FuiDefinition.json)
<!-- markdownlint-enable MD013 -->

## Who Would Use Each?

Choosing the right deployment scenario depends on your GIS goals, collaboration needs, and infrastructure preferences:

### Scenario 1: ArcGIS Pro on Azure Virtual Desktop (AVD)

Ideal for users who need high-performance desktop GIS capabilities with remote access. This scenario is especially useful when:

- You already use **ArcGIS Online** for sharing and collaboration and just need better hardware or centralized desktop access.
- You work with local or cloud-hosted data but don’t need to manage your own GIS server infrastructure.
- You want to enable GPU-accelerated workflows for 2D/3D analysis, cartography, or geoprocessing.

> [!NOTE]
> ArcGIS Pro can connect directly to ArcGIS Online, making this scenario a great fit for SaaS-first organizations.

### Scenario 2: Single-Tier Deployment (ArcGIS Enterprise + ArcGIS Pro)

Best for smaller teams or pilot projects that need to host and manage GIS services internally. Choose this when:

- You need to publish feature services, manage users, or host web maps and apps.
- You want a simple, cost-effective way to evaluate ArcGIS Enterprise capabilities.
- You’re not ready for a full-scale production deployment but need more control than ArcGIS Online offers.

### Scenario 3: Multi-Tier Deployment (ArcGIS Enterprise + ArcGIS Pro)

Designed for production environments requiring scalability, high availability, and enterprise-grade GIS workflows. Choose this when:

- You need to support many users, complex data models, or mission-critical GIS operations.
- You require enterprise geodatabases, versioned editing, or integration with internal systems.
- You need to meet strict performance, security, or compliance requirements in a cloud-hosted environment.

## Learn More and Explore Further

If you're looking to deepen your understanding of deploying ArcGIS in the cloud or want to explore related architectures and tools, here are some helpful resources:

### 🌐 ArcGIS Architecture Resources

- **[ArcGIS on Azure – Example Scenario](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/data/esri-arcgis-azure-virtual-desktop):** Learn how to deploy ArcGIS Pro in Azure Virtual Desktop with step-by-step guidance.
- **[Esri Architecture Center](https://architecture.arcgis.com/):** Explore Esri’s official architecture patterns, best practices, and deployment strategies.

### 🚀 Azure Landing Zone Resources

- **[What is an Azure Landing Zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/):** Understand the foundational building blocks for deploying workloads in Azure.
- **[Enterprise-Scale Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/implementation):** Learn how to implement scalable, secure, and governed environments for enterprise workloads.

### 🧭 Other Application Accelerators

- **[Deploy Azure Application Landing Zones](https://learn.microsoft.com/en-us/azure/architecture/landing-zones/landing-zone-deploy#application):** Discover other accelerators for deploying applications in Azure using landing zone principles.
