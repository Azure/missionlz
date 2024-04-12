# Mission LZ Deployment Guide for Bicep

## Table of Contents

- [Prerequisites](#prerequisites)  
- [Planning](#planning)  
- [Deployment](#deployment)  
- [Cleanup](#cleanup)  
- [Development Setup](#development-setup)  
- [See Also](#see-also)  

This guide describes how to deploy Mission Landing Zone using the Bicep template at [src/bicep/mlz.bicep](../src/bicep). The template can be deployed using the Azure Portal, the Azure CLI, or PowerShell. Supported clouds include the Azure Cloud (commercial Azure), Azure US Government, Azure Secret, and Azure Top Secret.

MLZ also provides the ARM template compiled from the Bicep file at [src/bicep/mlz.json](../src/bicep/mlz.json).

MLZ has only one required parameter and provides sensible defaults for the rest, allowing for simple deployments that specify only the parameters that need to differ from the defaults. See the [README.md](../src/bicep/README.md) document in the `src/bicep` folder for a complete list of parameters.

Below is an example of an Azure CLI deployment that uses all the defaults, and sets the `resourcePrefix` parameter, which is the only required parameter.

```BASH
az deployment sub create \
  --name myMlzDeployment \
  --location eastus \
  --template-file ./mlz.bicep \
  --parameters resourcePrefix=myMlz
```

## Prerequisites

- One or more Azure subscriptions where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)
- Azure Resource Provider Feature for Encryption At Host

To adhere to zero trust principles, the virtual machine disks deployed in this solution must be encrypted. The encryption at host feature enables disk encryption on virtual machine temp and cache disks. To use this feature, a resource provider feature must enabled on your Azure subscription. Use the following PowerShell script to enable the feature:

```powershell
Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
```

- For deployments in the Azure Portal you need access to the portal in the cloud you want to deploy to, such as [https://portal.azure.com](https://portal.azure.com) or [https://portal.azure.us](https://portal.azure.us).
- For deployments in BASH or a Windows shell, then a terminal instance with the AZ CLI installed is required. For example, [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), the MLZ [development container](../.devcontainer/README.md), or a command shell on your local machine with the [AZ CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed.
- For PowerShell deployments you need a PowerShell terminal with the [Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell) installed.

> NOTE: The AZ CLI will automatically install the Bicep tools when a command is run that needs them, or you can manually install them following the [instructions here.](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)

## Planning

### Decide on a Resource Prefix

Resource Groups and resource names are derived from the required parameter `resourcePrefix`. Pick a unqiue resource prefix that is 3-10 alphanumeric characters in length without whitespaces.

### One Subscription or Multiple

MLZ can deploy to a single subscription or multiple subscriptions. A test and evaluation deployment may deploy everything to a single subscription, and a production deployment may place each tier into its own subscription.

The optional parameters related to subscriptions are below. They default to the subscription used for deployment.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`hubSubscriptionId` | Deployment subscription | Subscription containing the firewall and network hub
`identitySubscriptionId` | Deployment subscription | Tier 0 for identity solutions
`operationsSubscriptionId` | Deployment subscription | Tier 1 for network operations and security tools
`sharedServicesSubscriptionId` | Deployment subscription | Tier 2 for shared services

### Networking

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

### Optional Features

MLZ has optional features that can be enabled by setting parameters on the deployment.

#### Azure Policy Initiatives: NISTRev4, NISTRev5, IL5, CMMC

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the `deployPolicy=true` parameter with `policy` assigned to one of the following: `NISTRev4`, `NISTRev5`, `IL5`, or `CMMC`.

The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deployPolicy` | 'false' | When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".
`policy` | 'NISTRev4' | [NISTRev4/NISTRev5/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NISTRev4". IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.

Under the [src/bicep/modules/policies](../src/bicep/modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

#### Microsoft Defender for Cloud

By default [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when you first set up a subscription and view the Microsoft Defender for Cloud portal blade.

Microsoft Defender for Cloud offers a standard/defender sku which enables a greater depth of awareness including more recomendations and threat analytics. You can enable this higher depth level of security in MLZ by setting the parameter `deployDefender` during deployment. In addition you can include the `emailSecurityContact` parameter to set a contact email for alerts.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deployDefender` | 'false' | When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".
`emailSecurityContact` | '' | Email address of the contact, in the form of <john@doe.com>

The Defender plan by resource type for Microsoft Defender for Cloud is enabled by default in the following [Azure Environments](https://docs.microsoft.com/en-us/powershell/module/servicemanagement/azure.service/get-azureenvironment?view=azuresmps-4.0.0): `AzureCloud` and `AzureUSGovernment`. To enable this for other Azure Cloud environments, this will need to executed manually.
Documentation on how to do this can be found
[here](https://docs.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security)

#### Azure Sentinel

[Sentinel](https://docs.microsoft.com/en-us/azure/sentinel/overview) is a scalable, cloud-native, security information and event management (SIEM) and security orchestration, automation, and response (SOAR) solution. Sentinel can be enabled by setting the `deploySentinel=true` parameter.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deploySentinel` | 'false' | When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment. It defaults to "false".

#### Remote access with a Bastion Host

If you want to remotely access the network and the resources you've deployed you can use [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/) to remotely access virtual machines within the network without exposing them via Public IP Addresses.

Deploy a Linux and Windows virtual machine as jumpboxes into the network without a Public IP Address using Azure Bastion Host by providing values for these parameters:

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deployRemoteAccess` | 'false' | When set to "true", provisions Azure Bastion Host and virtual machine jumpboxes. It defaults to "false".
`windowsVmAdminPassword` | new guid | The administrator password the Windows Virtual Machine to Azure Bastion remote into. It must be > 12 characters in length. See [password requirements for creating a Windows VM](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-).
`linuxVmAuthenticationType` | 'password' | [sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".
`linuxVmAdminPasswordOrKey` | new guid | The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See [password requirements for creating a Linux VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm-).
`windowsVmAdminUsername` | 'azureuser' | The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`linuxVmAdminUsername` | 'azureuser' | The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".

#### Azure Firewall Premium

By default, MLZ deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features). Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions). If necessary you can set a different firewall SKU or location.

You can manually specify which SKU of Azure Firewall to use for your deployment by specifying the `firewallSkuTier` parameter. This parameter only accepts values of `Standard` or `Premium` or `Basic`.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`firewallSkuTier` | 'Premium' | [Standard/Premium/Basic] The SKU for Azure Firewall. It defaults to "Premium".

If you'd like to specify a different region to deploy your resources into, change the location of the deployment. For example, when using the AZ CLI set the deployment command's `--location` argument.

### Naming Conventions

By default, Mission LZ resources are named according to a naming convention that uses the mandatory `resourcePrefix` parameter and the optional `resourceSuffix` parameter (that is defaulted to `mlz`).

#### Default Naming Convention Example

Let's look at an example using `--parameters resourcePrefix=FOO` and `--parameters resourceSuffix=BAR`

In `mlz.bicep` you will find a variable titled `namingConvention`:

```bicep
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'
# this generates a value of: foo-${resourceToken}-${nameToken}-bar
```

This naming convention uses Bicep's `replace()` function to substitute resource abbreviations for `resourceToken` and resource names for `nameToken`.

For example, when naming the Hub Resource Group, first the `resourceToken` is substituted with the recommended abbreviation `rg`:

```bicep
var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
# this generates a value of: foo-rg-${nameToken}-bar
```

Then, the `nameToken` is substituted with the Mission LZ name `hub`:

```bicep
var hubResourceGroupName =  replace(resourceGroupNamingConvention, nameToken, 'hub')
# this generates a value of: foo-rg-hub-bar
```

Finally, the `hubResourceGroupName` is assigned to the resource group `name` parameter:

```bicep
params: {
  name: hubResourceGroupName # this is the calculated value 'foo-rg-hub-bar'
  location: location
  tags: calculatedTags
}
```

#### Modifying the Naming Convention

You can modify this naming convention to suit your needs.

In `mlz.bicep` you can modify the root naming convention. This is the default convention:

```bicep
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'
```

Say you did not want to use the `resourceSuffix` value, but instead wanted to add your own token to the naming convention like `team`:

First, you added the new parameter `team`:

```bicep
@allowedValues([
  'admin'
  'marketing'
  'sales'
])
param team
```

Then, you modified the naming convention to allow for mixed case `resourcePrefix` values and your new `team` value (while retaining the token identifiers `resourceToken` and `nameToken`):

```bicep
var namingConvention = '${resourcePrefix}-${team}-${resourceToken}-${nameToken}'
```

Now, given a `--parameters resourcePrefix=FOO` and `--parameters team=sales` the generated Hub Resource Group Name would be:

```bicep
params: {
  name: hubResourceGroupName # this is the calculated value 'FOO-sales-rg-hub'
  location: location
  tags: calculatedTags
}
```

### Planning for Workloads

MLZ allows for deploying one or many workloads that are peered to the hub network. Each workload can be in its own subscription or multiple workloads may be combined into a single subscription.

A separate Bicep template is provided for deploying an empty workload. It deploys a virtual network, a route table, a network security group, a storage account (for logs), and a network peering to the hub network. The template is at [src/bicep/add-ons/tier3](../src/bicep/add-ons/tier3). You can use this template as a starting point to create and customize specific workload deployments.

The `tier3` template contains defaults for IP address ranges, but additional workloads will require planning for additional ranges. The following parameters affect `tier3` networking:

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`virtualNetworkAddressPrefix` | '10.0.125.0/26' | The address prefix for the network spoke vnet.
`subnetAddressPrefix` | '10.0.125.0/27' | The subnet address prefix for the network spoke vnet.

## Deployment

Mission Landing Zone can be deployed using the Azure Portal or with command-line tools provided with the AZ CLI or PowerShell.

### Deploy Using the Azure Portal

The Azure Portal can be used to deploy Mission Landing Zone. The buttons below invoke an Azure Portal input form that maps user input values to the MLZ ARM template that was compiled from the Bicep template.

<!-- markdownlint-disable MD013 -->
<!-- allow for longer lines to acommodate button links -->
| Azure Commercial | Azure Government |
| :--- | :--- |
| [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
<!-- markdownlint-enable MD013 -->

### Command Line Deployment Using the Azure CLI or PowerShell

Use the AZ CLI command `az deployment sub` to deploy MLZ across one or many subscriptions or use the PowerShell cmdlet `New-AzSubscriptionDeployment`.

#### Single Subscription Deployment

To deploy Mission LZ into a single subscription, give your deployment a name and a location and specify the `./mlz.bicep` template file.

```BASH
# AZ CLI
az deployment sub create \
  --name myMlzDeployment \
  --location eastus \
  --template-file ./mlz.bicep \
  --parameters resourcePrefix="myMlz"
```

```PowerShell
# PowerShell
New-AzSubscriptionDeployment `
  -Name myMlzDeployment `
  -Location 'eastus' `
  -TemplateFile .\mlz.bicep `
  -resourcePrefix 'myMlz' 
```

#### Multiple Subscription Deployment

Deployment to multiple subscriptions requires specifying the subscription IDs for each tier:

```BASH
# AZ CLI
az deployment sub create \
  --subscription $deploymentSubscription \
  --location eastus \
  --name multiSubscriptionTest \
  --template-file ./mlz.bicep \
  --parameters \
      resourcePrefix='myMlz' \
      hubSubscriptionId=$hubSubscriptionId \
      identitySubscriptionId=$identitySubscriptionId \
      operationsSubscriptionId=$operationsSubscriptionId \
      sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

```PowerShell
# PowerShell
New-AzSubscriptionDeployment `
  -Name myMlzDeployment `
  -Location 'eastus' `
  -TemplateFile .\mlz.bicep `
  -resourcePrefix "myMlz" `
  -hubSubscriptionId $hubSubscriptionId `
  -identitySubscriptionId $identitySubscriptionId `
  -operationsSubscriptionId $operationsSubscriptionId `
  -sharedServicesSubscriptionId $sharedServicesSubscriptionId
```

#### Deploying to Other Clouds

When deploying to another cloud, like Azure US Government, first set the cloud and log in.

Logging into `AzureUSGovernment`:

```BASH
# AZ CLI
az cloud set -n AzureUsGovernment
az login
```

```PowerShell
# PowerShell
Connect-AzAccount -Environment AzureUSGovernment
```

...and supply a different value for the deployment `--location` argument:

```BASH
# AZ CLI
az deployment sub create \
  --name myMlzDeployment \
  --location usgovvirginia \
  --template-file ./mlz.bicep \
  --parameters resourcePrefix=myMlz
```

```PowerShell
# PowerShell
New-AzSubscriptionDeployment `
  -Name myMlzDeployment `
  -Location 'usgovvirginia' `
  -TemplateFile .\mlz.bicep `
  -resourcePrefix 'myMlz'
```

#### Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

The ARM template is at [src/bicep/mlz.json](../src/bicep/mlz.json). The AZ CLI command for deploying the ARM template is the same as for deploying Bicep: use `az deployment sub create` and supply `mlz.json` as the template file name instead of `mlz.bicep`.

#### Reference Deployment Output

After you've deployed Mission Landing Zone you can integrate additional services or infrastructure. Bicep templates, the Azure CLI, and JMESpath queries allow you to retrieve outputs from a deployment and pass them as parameters into another deployment.

You can use the `az deployment sub show` command with a `--query` argument to retrieve information about the resources you deployed. In PowerShell use the `Get-AzSubscriptionDeployment` cmdlet.

In this example, MLZ was deployed using a deployment name of `myMissionLandingZone`. (The deployment name is the `name` parameter you set on `az deployment sub create` or `New-AzSubscriptionDeployment`.)

When an MLZ deployment is complete, you can see all the resources provisioned in that deployment by querying the `outputs` property:

```BASH
# AZ CLI
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs"
```

```PowerShell
# PowerShell
(Get-AzSubscriptionDeployment -Name myMissionLandingZone).outputs | ConvertTo-Json
```

If you need a single property value you can retrieve it like this:

```BASH
# AZ CLI
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs.firewallPrivateIPAddress.value"
```

```PowerShell
# PowerShell
(Get-AzSubscriptionDeployment -Name myMissionLandingZone).outputs.firewallPrivateIPAddress
```

If you want to export the data for use by other Bicep deployments, like the [shared variable file pattern](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file), you can export the outputs to a json file.

```BASH
# AZ CLI
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs" > ./deploymentVariables.json
```

```PowerShell
# PowerShell
(Get-AzSubscriptionDeployment -Name myMissionLandingZone).outputs `
  | ConvertTo-Json `
  | Out-File -FilePath .\deploymentVariables.json
```

## Cleanup

The Bicep/ARM deployment of Mission Landing Zone can be deleted with these steps:

1. Delete all resource groups.
1. Delete the diagnostic settings deployed at the subscription level.
1. If Microsoft Defender for Cloud was deployed (parameter `deployDefender=true` was used) then remove subscription-level policy assignments and downgrade the Microsoft Defender for Cloud pricing tiers.

> NOTE: If you deploy and delete Mission Landing Zone in the same subscription multiple times without deleting the subscription-level diagnostic settings, the sixth deployment will fail. Azure has a limit of five diagnostic settings per subscription. The error will be similar to this: `"The limit of 5 diagnostic settings was reached."`

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

## Development Setup

If you want to develop with Bicep you'll need these:

1. Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#install).
1. If using Visual Studio Code, install the [Bicep extension](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#vs-code-and-bicep-extension).

## See Also

[Bicep documentation](https://aka.ms/bicep/)

[`az deployment` documentation](https://docs.microsoft.com/en-us/cli/azure/deployment?view=azure-cli-latest)

[JMESPath queries](https://jmespath.org/)

[Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell)
