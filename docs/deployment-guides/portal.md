# Mission Landing Zone - Deployment Guide using the Azure Portal

[**Home**](../../README.md) | [**Design**](../design.md) | [**Add-Ons**](../../src/bicep/add-ons/README.md) | [**Resources**](../resources.md)

## Table of Contents

- [Deploy MLZ in the Azure Portal](#deploy-mlz-in-the-azure-portal)
- [Remove MLZ in the Azure Portal](#remove-mlz-in-the-azure-portal)

This guide provides the steps to deploy MLZ and remove an MLZ deployment in the Azure Portal. Azure Commercial and Azure Government are the only supported clouds for Azure Portal deployments of MLZ.

## Deploy MLZ in the Azure Portal

### Prerequisites

The following prerequisites are required on the target Azure subscription(s):

- [Owner RBAC permissions](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner)
- [Enable the Encryption At Host feature](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal?tabs=azure-powershell#prerequisites)

### Open the deployment UI

Click the appropriate button below to open the deployment UI.

| Cloud  | Deployment Button |
| :----- | :----- |
| Azure Commercial | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
| Azure Government |  [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |

### STEP 1: Basics

The first step in the deployment UI is the Basics step. This requires basic information for your MLZ deployment: Subscription(s), Location, Resource Naming Prefix, and Environment Abbreviation.

#### Project Details

The project details provide the scope of the deployment. These elements also help inform other elements in the UI like the VM size for the remote access VMs.

- **Subscriptions:** select the subscription you plan to use for the hub.
- **Region:** select the location you plan to use for the resources.

#### Select Subscription(s)

MLZ can deploy to a single subscription or multiple subscriptions. Microsoft recommends for test and evaluation deployments use a single subscription. For a production deployment a single subscription maybe used or multiple if you wish to keep billing of resources separate.

Select subscription(s) for each: Hub, Identity, Operations, and Shared Services.  

> [!NOTE]
> The Identity option is not required. This is intended for customers that need to deploy domain controllers in Azure.

#### Location

- **Location:** Select the desired location to deploy your MLZ resources. The drop down menu will be populated with locations that support all the resources in the deployment.

#### Naming Components

- **Resource Naming Prefix:** Specify a prefix for your MLZ resources. This prefix can help distinguish your MLZ resources and resource groups from other Azure resources. Ideally, the prefix would be an abbreviation for your organization or the department governing these resources.  The value must be between 3 to 6 alphanumeric characters.
- **Environment Abbreviation:** Select the abbreviation for the target environment: `dev` = development, `test` = test, or `prod` = production.

### STEP 2: Networking

The following parameters affect networking. Each virtual network and subnet has been given a default address prefix to ensure they fall within the default super network. Refer to the [Networking page](docs/networking.md) for all the default address prefixes.

#### Hub Virtual Network

- **Super Network CIDR Range:** the full address space that will be allowed by the Azure Firewall network rule.
- **Hub Virtual Network CIDR Range:** the address space for the default subnet, firewall subnets, bastion subnet (optional), and gateway subnet (optional).
- **Hub Subnet CIDR Range:** the default subnet for the Hub virtual network. The range must fit in the Hub virtual network.
- **Firewall Client Subnet CIDR Range:** the address space for the Azure Firewall Client subnet. The range must fit in the Hub Virtual Network CIDR range. The network mask must be a /26. |
- **Firewall Management Subnet CIDR Range:** the address space for the Azure Firewall Management subnet. The range must fit in the Hub Virtual Network CIDR range. The network mask must be a /26.
- **Firewall SKU:** the SKU for the Azure Firewall. For SCCA compliance, Azure Firewall Premium should be deployed for production. If necessary you can set a different firewall SKU, Standard or Basic. Please [validate the SKU availability in your region](https://learn.microsoft.com/azure/firewall/premium-features#supported-regions) before deploying as there can be differences between clouds.

#### Identity Virtual Network (Optional)

- **Identity Virtual Network CIDR Range:** the address space for the Identity virtual network.
- **Identity Subnet CIDR Range:** the address space for the default Identity subnet. The range must fit in the Identity virtual network.

#### Operations Virtual Network

- **Operations Virtual Network CIDR Range:** the CIDR range for the Operations virtual network.
- **Operations Subnet CIDR Range:** the CIDR range for the default Operations subnet. The range must fit in the Operations virtual network.

#### Shared Services Virtual Network

- **Shared Services Virtual Network CIDR Range:** the CIDR range for the Shared Services virtual network.
- **Shared Services Subnet CIDR Range:** the CIDR range for the default Shared Services subnet. The range must fit in the Shared Services virtual network.

### STEP 3: Security and Compliance

MLZ has optional features that can be enabled in the Security and Compliance step.

#### Microsoft Defender for Cloud - Cloud Security Posture Management

By default [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when you first set up a subscription and view the Microsoft Defender for Cloud portal blade.

#### Microsoft Defender for Cloud - Workload Protection Plans and other advanced management features

- **Enable additional features for Microsoft Defender for Cloud:** Microsoft Defender for Cloud (DfC) offers a standard / defender SKU which enables a greater depth of awareness including more recommendations and threat analytics.
- **Defender for Cloud Additional Features:** enable cloud workload protections to surface workload-specific recommendations to enhance security controls.
- **Security Contact E-Mail Address:** setup email notifications for alerts and attack paths in DfC.

#### Assign Regulatory Compliance Policies

Azure Policy can be applied to your MLZ deployment. The policies are assigned to each resource group deployed by MLZ and can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

- **Create policy assignments:** choose whether to enable Azure Policy assignments on your MLZ resource groups.
- **Policy Assignment:** select the desired Azure policy initiative. Please validate the availability of the policies in your target Azure cloud before deploying as there can be differences between clouds.

#### Microsoft Sentinel

- **Enable Microsoft Sentinel:** enable a basic Sentinel deployment which adds several security solutions to the log analytics workspace in the Operations resource group.

### STEP 4: Remote Access

#### Azure Bastion

- **Deploy Bastion:** enable [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/) in the Hub virtual network to remotely access the network and the resources deployed with and on MLZ.
- **Azure Bastion Subnet CIDR Range:** the address space for the Azure Bastion subnet. The network mask must be a /26 or larger.

#### Azure Gateway Subnet

- **Deploy Azure Gateway Subnet:** enable the deployment of a Gateway subnet in the Hub virtual network. This simplifies the integration of a site-to-site VPN or Express Route connectivity post deployment.
- **Azure Gateway Subnet CIDR Range:** the address space for the Gateway subnet. The network mask must be a /27 or larger.

#### Windows Virtual Machine

- **Deploy Windows Virtual Machine:** choose whether to deploy a management Windows Server virtual machine in the Hub.
- **Windows Server Version:** select the desired version of Windows Server.
- **Size:** select the size for your virtual machine, ensuring your subscription has enough quota.
- **Username:** input the username for the local administrator account on the virtual machine.
- **Password:** input the password for the local administrator account on the virtual machine.
- **Confirm password:** input the password again for the local administrator account on the virtual machine.
- **Enable Hybrid Use Benefit:** choose whether to enable the [Azure Hybrid Use Benefit](https://learn.microsoft.com/windows-server/get-started/azure-hybrid-benefit) on the Windows virtual machine.

#### Linux Virtual Machine

- **Deploy Linux Virtual Machine:** choose whether to deploy a management Linux virtual machine in Hub.
- **Linux Image Publisher:** select the desired Linux image publisher from the Azure marketplace.
- **Linux Image Offer:** select the desired Linux image offer from the Azure marketplace.
- **Linux Image SKU:** select the desired Linux image SKU from the Azure marketplace. Please note, some distributions of Linux have additional license fees.
- **Size:** select the size for your virtual machine, ensuring your subscription has enough quota.
- **Username:** input the username for the local administrator account on the virtual machine.
- **Password:** input the password for the local administrator account on the virtual machine.
- **Confirm password:** input the password again for the local administrator account on the virtual machine.

### STEP 5: Tags

Tags are key / value pairs that enable you to categorize resources and view consolidated billing by applying the same tag to multiple resources and resource groups. Please refer to [Microsoft's best practices for resource tagging](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging).

### STEP 6: Review + Create

Review and validate the values selected for element in the UI. Once the values have been confirmed, click the Create button to start the deployment.

> [!NOTE]
> Deployment time can vary depending on options selected.

## Remove MLZ in the Azure Portal

If necessary, the deployment of a Mission Landing Zone can be deleted with these steps:

1. Delete the resource groups for the Hub, Identity (if applicable), Shared Services, and Operations.
1. Delete the diagnostic setting for the Activity Log deployed.
   1. On the Home blade, click the Subscriptions icon
   1. Click on the target subscription name
   1. Click the "Activity log" option in the left menu
   1. Click the "Export Activity Logs" option from the top menu
   1. Click the "Edit setting" link next to the diagnostic setting
   1. Click the "Delete" option from the top menu
1. Delete the subscription-level Azure Policy assignments
   1. Navigate to the Policy page and select the Assignments tab in the left navigation bar.
   1. At the top, in the Scope box, choose the subscription(s) that contain the policy assignments you want to remove.
   1. In the table click the ellipsis menu ("...") and choose "Delete assignment".
1. Downgrade the Microsoft Defender for Cloud pricing tier(s).
   1. Navigate to the Microsoft Defender for Cloud page, then click the "Environment settings" tab in the left navigation panel.
   1. In the tree/grid select the subscription you want to manage.
   1. Click the large box near the top of the page that says "Enhanced security off".
   1. Click the save button.
