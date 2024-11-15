# Mission Landing Zone - Deployment Guide using a Template Spec

[**Home**](../../README.md) | [**Design**](../design.md) | [**Add-Ons**](../../src/bicep/add-ons/README.md) | [**Resources**](../resources.md)

## Table of Contents

- [Deploy using a Template Spec](#deploy-using-a-template-spec)
- [References](#references)

This guide provides the steps to create a template spec to deploy Mission Landing Zone (MLZ). The template spec deployment option may used in Azure Commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret. For simplicity, this guide uses Cloud Shell to create the template spec, negating the need to download and install software on your workstation.

For more information on Template Specs, go to the [References](#references) section.

## Deploy using a Template Spec

### Prerequisites

The following prerequisites are required on the target Azure subscription(s):

- [Owner RBAC permissions](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner)
- [Enable Encryption At Host](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal?tabs=azure-powershell#prerequisites)

### Create the Template Spec

Use the following steps to create the Template Spec resource using CloudShell:

1. Download the following files to your local workstation:
   1. [src/bicep/mlz.json](../../src/bicep/mlz.json)
   1. [src/bicep/form/mlz.portal.json](../../src/bicep/form/mlz.portal.json)
1. If applicable, transfer the files to a workstation in the target network.
1. Login to the Azure Portal.
1. Create a storage account for CloudShell using the following settings:
   1. **Basics**
      - **Subscription:** select the appropriate subscription. Ideally, select the subscription that will be used for the Hub resources.
      - **Resource group:** click the "Create new" link and input a name that follows your naming convention and alludes to the purpose of it, e.g. rg-cloudShell-dev-east.
      - **Storage account name:** input a globally unique name between 3 and 24 characters following your naming convention. The value can contain only lowercase letters and numbers.
      - **Region:** select the appropriate location. Ideally, select the location that will be used for the MLZ resources.
      - **Primary service:** select the "Azure Files" option.
      - **Performance:** select the "Standard: Recommended for general purpose file share and cost sensitive applications, such as HDD file shares" option.
      - **Redundancy:** leave the "Geo-redundant storage (GRS)" option selected.
   1. **Advanced**
      - **Require secure transfer for REST API operations:** leave check box checked.
      - **Allow enabling anonymous access on individual containers:** leave check box unchecked.
      - **Enable storage account key access:** uncheck the check box.
      - **Default to Microsoft Entra authorization in the Azure portal:** check the check box.
      - **Minimum TLS version:** leave the default option, Version 1.2.
      - **Permitted scope for copy operations (preview):** select the "From storage accounts that have a private endpoint to the same virtual network" option.
      - **Enable hierarchical namespace:** leave the check box unchecked.
      - **Allow cross-tenant replication:** leave the check box unchecked.
      - **Access tier:** select the "Cool: Optimized for infrequently accessed data and backup scenarios" option.
   1. **Networking**
      - **Network access:** select the "Enable public access from all networks" option.
      - **Routing preference:** leave the "Microsoft network routing" option selected.
   1. **Data Protection**
      - **Enable point-in-time restore for containers:** leave the check box unchecked.
      - **Enable soft delete for blobs:** uncheck the check box.
      - **Enable soft delete for containers:** uncheck the check box.
      - **Enable soft delete for file shares:** uncheck the check box.
      - **Enable versioning for blobs:** leave the check box unchecked.
      - **Enable blob change feed:** leave the check box unchecked.
      - **Enable version-level immutability support:** leave the check box unchecked.
   1. **Encryption**
      - **Encryption type:** leave the "Microsoft-managed keys (MMK)" option selected.
      - **Enable support for customer-managed keys:** select the "All service types (blobs, files, tables, and queues)" option.
      - **Enable infrastructure encryption:** check the check box.
   1. **Tags:** the key / value pairs that enable you to categorize resources and view consolidated billing by applying the same tag to multiple resources and resource groups. Please refer to [Microsoft's best practices for resource tagging](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging).
   1. **Review + Create:** review and validate the selected values before creating the deployment.
1. Setup a file share on the storage account using the following settings:
   1. **Basics**
      - **Name:** input a value for the file share name. Ideally, this should be your username.
      - **Access tier:** select the "Cool" option.
   1. **Backup**
      - **Enable backup:** uncheck the check box.
   1. **Review + create:** review and validate the selected values before creating the deployment.
1. Click the CloudShell button from the top Portal menu to setup the service:
   1. **Welcome to Azure Cloud Shell**
      1. Click on the desired command line tool.
   1. **Getting started**
      1. Select the "Mount storage account" option.
      1. Select the subscription that will be used for the Hub resources.
      1. Leave the check box uncheck for the "Use an existing private virtual network".
      1. Click the Apply button
   1. **Mount storage account**
      1. Choose the "Select existing storage account" option.
      1. Click the Next button
   1. **Select storage account**
      1. **Subscription:** select the subscription used for the storage account.
      1. **Resource group:** select the resource group used for the storage account.
      1. **Storage account name:** select the storage account created in the previous step.
      1. **File share:** select the file share created in the previous step.
      1. Click the Select button
1. Upload the files to your file share.
   1. Click the "Manage files" menu option.
   1. Click the "Upload" option.
   1. Select the JSON files
   1. Click the Open button
1. Deploy the template spec using CloudShell.
   1. Check your directory to ensure the JSON files are present: `ls`
   1. Copy one of the following commands below and paste it into CloudShell. The command must be updated with the values for your environment before it is executed.

   ```PowerShell
   # PowerShell
   New-AzTemplateSpec `
      -ResourceGroupName '<resource group name>' `
      -Name '<template spec name>' `
      -Version '1.0' `
      -Location '<location>' `
      -TemplateFile 'mlz.json' `
      -UIFormDefinitionFile 'mlz.portal.json' `
      -Force
   ```

   ```Bash
   # Azure CLI
   az ts create \
      --resource-group '<resource group name>' \
      --name '<template spec name>' \
      --version '1.0' \
      --location '<location>' \
      --template-file 'mlz.json' \
      --ui-form-definition 'mlz.portal.json' \
      --yes
   ```

#### Parameter Explanations

- **ResourceGroupName | resource-group:** the name of the resource group to host the template spec resource.
- **Name | name:** the name for the template spec resource using your naming convention for Azure, e.g. ts-mlz-dev-east.
- **Version | version:** the version number of the mlz code that will be stored in the template spec, e.g. 1.0.
- **Location | location:** the Azure location for the template spec resource.
- **TemplateFile | template-file:** the file path to the ARM template in the Azure Files share used by CloudShell.
- **UIFormDefinitionFile | ui-form-definition:** the file path to the ARM template in the Azure Files share used by CloudShell.
- **Force | yes:** this switch ensures the template spec is forcibly updated without confirmation if the resource and version already exist.

### Deploy MLZ

1. Open the template spec resource in the Azure Portal.
1. Click the Deploy button from the top menu.
1. Use the deployment guide for the [Azure Portal](./portal.md#step-1-basics) deployment option to complete the MLZ deployment.

## References

- [Azure CLI - az ts create](https://learn.microsoft.com/cli/azure/ts?view=azure-cli-latest#az-ts-create)
- [Azure PowerShell - New-AzTemplateSpec](https://learn.microsoft.com/powershell/module/az.resources/new-aztemplatespec?view=azps-12.4.0)
- [Template Specs documentation](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-specs?tabs=azure-powershell)
