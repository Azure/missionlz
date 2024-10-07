# Mission Landing Zone - Walkthrough Guide

[**Home**](../../README.md) | [**Design**](../design.md) | [**Add-Ons**](../../src/bicep/add-ons/README.md) | [**Resources**](../resources.md)

A walkthrough guide to the Quickstart MLZ deployment available at [Quickstart](https://github.com/Azure/missionlz)

## Table of Contents

- [MLZ Deployment Walkthrough](#mlz-deployment-walkthrough)
- [Delete an MLZ-Core deployment](#delete-an-mlz-core-deployment)
- [See Also](#see-also)  

This guide describes each tab and the components of an MLZ deployment.  

## MLZ Deployment Walkthrough

### Basics step

The first tab will prompt you for basic information regarding your MLZ deployment: Subscription(s), Location, Resource Naming Prefix, and Environment Abbreviation.

#### One Subscription or Multiple

MLZ can deploy to a single subscription or multiple subscriptions. Microsoft recommends for test and evaluation deployments use a single subscription. For a production deployment a single subscription maybe used or multiple if you wish to keep billing of resources separate.

Select subscription(s) for each: Hub, Identity, Operations, and Shared Services.  

>Note: Identity is optional and includes a check box to deploy it or not.

#### Location

Select the necessary region in your Environment to deploy your MLZ resources.

#### Resource Naming Prefix

Specify a prefix for your MLZ resources. This prefix can help distinguish your MLZ resources and resource groups from other Azure resources. Ideally, the prefix would be an abbreviation for your organization or the department governing these resources.  The value must be a minimum of 3 letters and/or numbers to a maximum of 6.

#### Environment Abbreviation

Available options include dev, test, or prod.

Click the 'Next' button.

### Networking step

#### Networks

The following parameters affect networking. Each virtual network and subnet has been given a default address prefix to ensure they fall within the default super network. Refer to the [Networking page](docs/networking.md) for all the default address prefixes.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`hubVirtualNetworkAddressPrefix` | '10.0.128.0/23' | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.
`hubSubnetAddressPrefix` | '10.0.128.128/26' | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.
`firewallClientSubnetAddressPrefix` | '10.0.128.0/26' | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallManagementSubnetAddressPrefix` | '10.0.128.64/26' | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.
`identityVirtualNetworkAddressPrefix` | '10.0.130.0/24' | The CIDR Virtual Network Address Prefix for the Identity Virtual Network.
`identitySubnetAddressPrefix` | '10.0.130.0/24' | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.
`operationsVirtualNetworkAddressPrefix` | '10.0.131.0/24' | The CIDR Virtual Network Address Prefix for the Operations Virtual Network.
`operationsSubnetAddressPrefix` | '10.0.131.0/24' | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.
`sharedServicesVirtualNetworkAddressPrefix` | '10.0.132.0/24' | The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.
`sharedServicesSubnetAddressPrefix` | '10.0.132.0/24' | The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.

>Note: The SuperCIDR range of /18 will allow for future expansion tiers such as: AVD, ESRI, and any future Tier3 add-ons.

#### Firewall SKUs

By default, MLZ deploys **[Azure Firewall Premium](https://docs.microsoft.com/azure/firewall/premium-features). Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/azure/firewall/premium-features#supported-regions). If necessary you can set a different firewall SKU (Standard or Basic).

Please validate the SKU availability in your region before deploying as there can be differences between clouds.

Click the 'Next' button.

### Security and Compliance step

MLZ has optional features that can be enabled by setting parameters during the MLZ deployment.

#### Microsoft Defender for Cloud

By default [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when you first set up a subscription and view the Microsoft Defender for Cloud portal blade.

Microsoft Defender for Cloud (DfC) offers a standard / defender SKU which enables a greater depth of awareness including more recommendations and threat analytics. You can enable this higher depth level of security in MLZ by clicking the box 'Enable additional features for Microsoft Defender for Cloud.'  Then use the pulldown menu to select additional DfC features.

If additional features are enabled then a Security Contact E-mail Address will also be prompted.

To manually enable DfC, if not enabled during the MLZ deployment, see the following documentation,
[here](https://docs.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security)

#### Assign Regulatory Compliance Policies

Optionally, Azure Policy can be applied to your MLZ deployment.

Simply check the 'Create policy assignments' checkbox and select your desired Regulatory Compliance option.  The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

#### Available Regulatory Compliances and Policies

Please validate the availability of Regulatory Compliances and Policies in your region before deploying as there can be differences between clouds.

Under the [src/bicep/modules/policies](../src/bicep/modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

#### Azure Sentinel

[Sentinel](https://docs.microsoft.com/en-us/azure/sentinel/overview) is a scalable, cloud-native, security information and event management (SIEM) and security orchestration, automation, and response (SOAR) solution.

A basic Sentinel deployment can be initiated by MLZ by simply clicking the checkbox 'Enable Microsoft Sentinel.'

Further configuration of Sentinel post MLZ deployment is required to take full advantage of threat detection, log retention, and response capabilities.

Click the 'Next' button.

### Remote Access step

#### Remote access with a Bastion Host

If you wish to remotely access the network and the resources you've deployed you can use [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/) to remotely access 2 virtual machines (jumpboxes), one Windows and/or one Linux, within the hub network without exposing them via Public IP Addresses.

#### Enable Remote Access

You will see check boxes for:

Azure Bastion
Azure Gateway Subnet
Windows Virtual Machine
Linux Virtual Machine

Any or all 4 resources may be deployed.  See below for options for each resource.

1. Azure Bastion subnet CIDR range.
2. Azure Gateway subnet CIDR range.

>Note: GatewaySubnet is a reserved name in Azure and is required only if you plan to implement a Site-to-Site or ExpressRoute VPN.

3. Windows VM:
      1. Username
      2. Password
      3. Password confirmation
      4. Option for Hybrid Use Benefit for Windows [Azure Hybrid Benefit](https://learn.microsoft.com/en-us/windows-server/get-started/azure-hybrid-benefit?tabs=azure)
4. Linux VM:
      1. Username
      2. Password
      3. Password confirmation

Click the 'Next' button.

### Tags step

#### Best Practices for Azure Tags

Tags are name/value pairs that enable you to categorize resources and view consolidated billing by applying the same tag to multiple resources and resource groups.

Microsoft recommends the following documentation for best practices regarding [Azure Tags](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging).

Click 'Next' to Validate Settings and finally, 'Create.'

>Note: Deployment time can vary depending on options selected.

## Delete an MLZ-Core deployment

If necessary, the deployment of a Mission Landing Zone can be deleted with these steps:

1. Delete the 4 default resource groups: Hub, Identity, Shared Services, and Operations.  Delete any add-on tier resource groups that were added in addition to MLZ-Core.
2. Delete the diagnostic setting for the Activity Log deployed at the subscription level.
3. If Microsoft Defender for Cloud was deployed (parameter `deployDefender=true` was used) then remove subscription-level policy assignments and downgrade the Microsoft Defender for Cloud pricing tiers.

To delete the diagnostic settings from the Azure Portal: choose the subscription blade, then Activity log in the left panel. At the top of the Activity log screen click the Diagnostics settings button. From there you can click the Edit setting link and delete the diagnostic setting.

To delete the diagnotic settings in script, use the AZ CLI or PowerShell. An AZ CLI example is below:

```BASH
# View diagnostic settings in the current subscription
az monitor diagnostic-settings subscription list --query value[] --output table

# Delete a diagnostic setting
az monitor diagnostic-settings subscription delete --name <diagnostic setting name>
```

To delete the subscription-level policy assignments in the Azure portal:

1. Navigate to the Policy page and select the Assignments tab in the left navigation bar.
1. At the top, in the Scope box, choose the subscription(s) that contain the policy assignments you want to remove.
1. In the table click the ellipsis menu ("...") and choose "Delete assignment".

To delete the subscription-level policy assignments using the AZ CLI:

```BASH
# View the policy assignments for the current subscription
az policy assignment list -o table --query "[].{Name:name, DisplayName:displayName, Scope:scope}"

# Remove a policy assignment in the current subscription scope.
az policy assignment delete --name "<name of policy assignment>"
```

To downgrade the Microsoft Defender for Cloud pricing level in the Azure portal:

1. Navigate to the Microsoft Defender for Cloud page, then click the "Environment settings" tab in the left navigation panel.
1. In the tree/grid select the subscription you want to manage.
1. Click the large box near the top of the page that says "Enhanced security off".
1. Click the save button.

To downgrade the Microsoft Defender for Cloud pricing level using the AZ CLI:

```BASH
# List the pricing tiers
az security pricing list -o table --query "value[].{Name:name, Tier:pricingTier}"

# Change a pricing tier to the default free tier
az security pricing create --name "<name of tier>" --tier Free
```

> NOTE: The Azure portal allows changing all pricing tiers with a single setting, but the AZ CLI requires each setting to be managed individually.

## See Also

[Bicep documentation](https://aka.ms/bicep/)

[`az deployment` documentation](https://docs.microsoft.com/en-us/cli/azure/deployment?view=azure-cli-latest)

[Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell)
