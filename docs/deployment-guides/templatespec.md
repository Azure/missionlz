# Mission Landing Zone - Deployment Guide using a TemplateSpec

[**Home**](../../README.md) | [**Design**](../design.md) | [**Add-Ons**](../../src/bicep/add-ons/README.md) | [**Resources**](../resources.md)

To mimic the Quickstart experience of an Azure Commercial or Azure Government MLZ deployment available at [Quickstart](https://github.com/Azure/missionlz) in Azure Secret or Azure Top Secret.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Create the TemplateSpecFile](#create-the-templatespecfile)
- [MLZ-Core resources deployed](#mlz-core-resources-deployed)
- [See Also](#see-also)

This guide describes how to create an Azure TemplateSpecFile. The TemplateSpecFile is used to execute a user-friendly MLZ deployment GUI.  This GUI is the same Quickstart experience available in Azure Commercial and Azure Government. The TemplateSpec File is created via Powershell and requires only 2 files, [src/bicep/mlz.json](../../src/bicep/mlz.json) and [src/bicep/form/mlz.portal.json](../../src/bicep/form/mlz.portal.json).

The TemplateSpecFile is created and deployed using the Azure Portal in Azure Secret and Azure Top Secret environments.

>Note: Microsoft recommends using the CloudShell tool in the Azure Portal with Powershell since it will be populated with the necessary Powershell cmdlets.

## Prerequisites

- One or more Azure subscriptions where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)
- Azure Resource Provider Feature 'Encryption At Host' enabled.

To adhere to zero trust principles, the virtual machine disks deployed in this solution must be encrypted. The 'Encryption at Host' feature enables disk encryption on virtual machine's temp and cache disks. To use this feature, the resource provider feature must be enabled on your Azure subscription. Use the following PowerShell script to enable the feature:

```powershell
Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
```

- For PowerShell deployments you need a PowerShell terminal with the [Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell) installed. Or simply use CloudShell in the Azure Portal.

## Create the TemplateSpecFile

To create the TemplateSpecFile follow the steps below:

1. Download [src/bicep/mlz.json](../../src/bicep/mlz.json) and [src/bicep/form/mlz.portal.json](../../src/bicep/form/mlz.portal.json) to your local workstation.
2. Upload the mlz.json and mlz.portal.json files to your Secret or Top Secret environment following any and all required Security regulations and procedures.
3. Login to your Secret or Top Secret Azure portal environment.
4. You will need to create or use an available Azure StorageAccount with a File Share to store the mlz.json and mlz.portal.json files.
   1. Create or designate an available storageaccount.
   1. Create or designate an available file share in the storageaccount.
   1. Upload the mlz.json and mlz.portal.json files into the Azure file share.
   1. Open CloudShell in the Portal (Use CloudShell because it will have all the necessary PS cmdlets).  If your current CloudShell already defaults to the FileShare containing the mlz.json and mlz.portal.json files then skip steps v - xi.
   1. Click the Gear icon and select 'Reset user settings.'
   1. Click 'Reset' button.
   1. Click 'Powershell' when prompted.
   1. Click 'Subscription' and select the correct subscription for your FileShare.
   1. Click 'Show advanced settings'
   1. Select the 'use existing' radio buttons for your Resource Group, Storage account, and FileShare.
   1. Click 'attach storage' (This will mount the file share with mlz.json and mlz.portal.json files to your CloudShell terminal)  
   1. CD to ./clouddrive and type 'ls' to verify the mlz.json and mlz.portal.json file are present.
   1. Run the following PS command to create the TemplateSpec File

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

To follow a walkthrough of the MLZ deployment click [Walkthrough](./deployment-guide-walkthrough.md).

## MLZ-Core resources deployed

Once deployed MLZ will deploy a number of resources into 4 Resource Groups:

1. Hub
2. Operations
3. Shared Services
4. Identity, if selected.

The majority of resources will exist in the Hub resource group, mostly Private DNS Zones.  All resource groups will contain VNETS, Route Tables, and Storage Accounts.  The Operations hub will include additional logging Solutions.  The items listed here are not a complete list of resources.

## See Also

[Bicep documentation](https://aka.ms/bicep/)

[`az deployment` documentation](https://docs.microsoft.com/en-us/cli/azure/deployment?view=azure-cli-latest)

[Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell)
