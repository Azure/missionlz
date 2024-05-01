# Mission LZ Deployment Guide using a TemplateSpec File to mimic the Quickstart experience available to Azure Commercial and Azure Government

## Table of Contents

- [Prerequisites](#prerequisites)  
- [TemplateSpecFile Creation](#templatespecfile-creation)
- [MLZ Deployment Walkthrough](#mlz-deployment-walkthrough)
- [Cleanup](#cleanup)  
- [See Also](#see-also)  

This guide describes how to create an Azure TemplateSpecFile. The TemplateSpecFile is used to execute a user-friendly MLZ deployment GUI.  This GUI is the same Quickstart experience available in Azure Commercial and Azure Government. The TemplateSpec File is created via Powershell and requires only 2 files, [src/bicep/mlz.json](../src/bicep/mlz.json) and [src/bicep/form/mlz.portal.json].

The TemplateSpecFile is created and deployed using the Azure Portal in Azure Secret and Azure Top Secret environments.

Note: Microsoft recommends using the CloudShell tool in the Azure Portal with Powershell since it will be populated with the necessary Powershell cmdlets.

## Prerequisites

- One or more Azure subscriptions where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)
- Azure Resource Provider Feature for Encryption At Host

To adhere to zero trust principles, the virtual machine disks deployed in this solution must be encrypted. The encryption at host feature enables disk encryption on virtual machine temp and cache disks. To use this feature, a resource provider feature must enabled on your Azure subscription. Use the following PowerShell script to enable the feature:

```powershell
Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
```

- For PowerShell deployments you need a PowerShell terminal with the [Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell) installed. Or simply use CloudShell in the Azure Portal.

## templatespecfile-creation

To create the TemplateSpecFile follow the steps below:

1. Download [src/bicep/mlz.json](../src/bicep/mlz.json) and [src/bicep/form/mlz.portal.json] to your local workstation.
2. Upload the mlz.json and mlz.portal.json files to your Secret or Top Secret environment following any and all required Security regulations and procedures.
3. Login to your Secret or Top Secret Azure portal environment.
4. You will need to create or use an available Azure StorageAccount and File Share to store the mlz.json and mlz.portal.json files.
   a. Create or designate an available storageaccount.
   b. Create or designate an available file share in the storageaccount.
   c. Upload the mlz.json and mlz.portal.json files into the Azure file share.
   d. Open CloudShell in the Portal (Use CloudShell because it will have all the necessary PS cmdlets).  If your current CloudShell already defaults to the FileShare containing the mlz.json and mlz.portal.json files then skip steps 5 - 11.
   e. Click the Gear icon and select 'Reset user settings.'
   f. Click 'Reset' button.
   g. Click 'Powershell' when prompted.
   h. Click 'Subscription' and select the correct subscription for your         FileShare.
   i. Click 'Show advanced settings'
   j. Select the 'use existing' radio buttons for your Resource Group, Storage account, and FileShare.
   k. Click 'attach storage' (This will mount the file share with mlz.json and mlz.portal.json files to your CloudShell terminal)  
   l. cd to ./clouddrive and type 'ls' to verify the mlz.json and mlz.portal.json file are present.
   m. Run the following PS command to create TemplateSpec File

```PowerShell
# PowerShell
New-AzTemplateSpec -ResourceGroupName <rg-name> -Name <templatespecfilename> -Version 1.0 -Location <shortnameregion> -TemplateFile /home/<user>/clouddrive/mlz.json -UIFormDefinitionFile /home/<user>/clouddrive/mlz.portal.json
```

The parameters explained:
    ResourceGroupName - any available ResourceGroup to host the TemplateSpecFile
    Name - An arbitrary name for the TemplateSpecFile using Standard Naming Conventions for Azure, ie mlz-dev-tsf-1
    Version - Version control of the tsf created.
    Location - This is the short name of the region where the RG exists. Note, to get your location use the PS command below:
    File locations - You must use the complete path to the file names.

```PowerShell
# PowerShell
    Get-AzLocation | select displayname,location
```

5. After running the command verify the templatespecfile was created and exists in the ResourceGroup listed in the command.
6. To execute the MLZ deployment, simply click the templatespecfile.
7. A custom template deployment is triggered.  Click the 'deploy' icon in the upper left hand corner of the 2nd blade. (This will begin the MLZ template wizard).

## MLZ Deployment Walkthrough

### Basics tab

The first tab will prompt you for Basic information regarding your MLZ deployment; Subscription(s), Location, Resource Naming Prefix and Environment Abbreviation.

#### One Subscription or Multiple

MLZ can deploy to a single subscription or multiple subscriptions. A test and evaluation deployment may deploy everything to a single subscription, and a production deployment may place each tier into its own subscription.

Select a subscription for each Hub, Identity, Operations, and Shared Services.  Note: Identity is optional and includes a check box to deploy it or not.

#### Location

Select the necessary region in your Environment to deploy your MLZ resources.

#### Resource Naming Prefix

Specify a prefix for your MLZ resources.  This prefix can help distinguish your MLZ resources and ResourceGroups from other Azure resources.  Minimum of 3 letters and/or numbers to a maximum of 6.

#### Environment Abbreviation

Available options include dev, test, or prod.

Click the 'Next' button.

### Networking tab

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

Note: The SuperCIDR range of /18 will allow for future expansion tiers such as: AVD and ESRI.

#### Firewall SKUs

By default, MLZ deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features). Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions). If necessary you can set a different firewall SKU (Standard) or location.
Please validate the SKU availability in your region before deploying as there can be differences between clouds.

### Security and Compliance tab

MLZ has optional features that can be enabled by setting parameters during the MLZ deployment.

#### Microsoft Defender for Cloud

By default [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when you first set up a subscription and view the Microsoft Defender for Cloud portal blade.

Microsoft Defender for Cloud offers a standard/defender sku which enables a greater depth of awareness including more recommendations and threat analytics. You can enable this higher depth level of security in MLZ by clicking the box 'Enable additional features for Microsoft Defender for Cloud.'  Then use the pulldown menu to select additional DfC features.

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

### Remote Access tab

#### Remote access with a Bastion Host

If you want to remotely access the network and the resources you've deployed you can use [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/) to remotely access 2 virtual machines (jumpboxes), one Windows and one Linux, within the hub network without exposing them via Public IP Addresses.

#### Enable Remote Access

To enable Remote Access simply click the 'Remotely access the network' checkbox.

This will enable parameters for the following:
    1. Azure Bastion subnet CIDR range
    2. Windows VM:
       1. Username
       2. Password
       3. Password confirmation
       4. Option for Hybrid Use Benefit for Windows [Azure Hybrid Benefit](https://learn.microsoft.com/en-us/windows-server/get-started/azure-hybrid-benefit?tabs=azure)
    3. Linux VM:
       1. Username
       2. Password
       3. Password confirmation

### Tags tab

#### Best Practices for Azure Tags

Tags are name/value pairs that enable you to categorize resources and view consolidated billing by applying the same tag to multiple resources and resource groups.

Microsoft recommends the following documentation for best practices regarding [Azure Tags](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging).

Click 'Next' to Validate Settings and finally, 'Create.'

## MLZ Core resources deployed

### MLZ Resources

Once deployed MLZ will deploy a number of resources in 4 Resource Groups:
    1. Hub
    2. Operations
    3. Identity (if selected)
    4. Shared Services

