# Mission LZ Deployment Guide for Bicep

This guide describes how to deploy Mission Landing Zone using the Bicep template at [src/bicep/mlz.bicep](../src/bicep). MLZ can be deployed using the Azure Portal, the Azure CLI, or PowerShell. Supported clouds include the Azure Cloud (commercial Azure), Azure US Government, Azure Secret, and Azure Top Secret.

MLZ also provides the ARM template compiled from the Bicep file at [src/bicep/mlz.json](../src/bicep/mlz.json).

MLZ provides defaults for all but one parameter, allowing a simple deployment to be run from the Azure CLI, PowerShell, or the Azure Portal. This is an example of an Azure CLI deployment that uses all the defaults, and sets the `resourcePrefix` parameter, which is the only required parameter for deploying MLZ.

```plaintext
az deployment sub create \
  --name myMlzDeployment \
  --location eastus \
  --template-file ./mlz.bicep \
  --parameters resourcePrefix=myMlz
```

See the [README.md](../src/bicep/README.md) document in the `src/bicep` folder for a complete list of parameters.

## Prerequisites

- One or more Azure subscriptions where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)
- If you plan to deploy using the Azure Portal, then you need access to the portal in the cloud you want to deploy to, such as [https://portal.azure.com](https://portal.azure.com) or [https://portal.azure.us](https://portal.azure.us).
- If you plan to deploy using BASH or a Windows shell, then a terminal instance with the AZ CLI installed is required. For example, [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), the MLZ [development container](../../.devcontainer/README.md), or a command shell on your local machine with the [AZ CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed.
- If you plan to deploy using PowerShell then you need a PowerShell terminal with the [Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/what-is-azure-powershell) installed.

> NOTE: The AZ CLI will automatically install the Bicep tools when a command is run that needs them, or you can manually install them following the [instructions here.](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)

## Planning

### Decide on a Resource Prefix

Resource Groups and resource names are derived from the mandatory parameter `resourcePrefix`.

Pick a unqiue resource prefix that is 3-10 alphanumeric characters in length without whitespaces.

### One Subscription or Multiple

MLZ can deploy to a single subscription or multiple subscriptions. A test and evaluation deployment may deploy everything to a single subscription, and a production deployment may place each tier into its own subscription.

The optional parameters related to subscriptions are below.

- `hubSubscriptionId`
- `identitySubscriptionId`
- `operationsSubscriptionId`
- `sharedServicesSubscriptionId`

### Networking

The following parameters affect networking.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`hubVirtualNetworkAddressPrefix` | '10.0.100.0/24' | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.
`hubSubnetAddressPrefix` | '10.0.100.128/27' | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.
`firewallClientSubnetAddressPrefix` | '10.0.100.0/26' | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallManagementSubnetAddressPrefix` | '10.0.100.64/26' | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.
`identityVirtualNetworkAddressPrefix` | '10.0.110.0/26' | The CIDR Virtual Network Address Prefix for the Identity Virtual Network.
`identitySubnetAddressPrefix` | '10.0.110.0/27' | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.
`operationsVirtualNetworkAddressPrefix` | '10.0.115.0/26' | The CIDR Virtual Network Address Prefix for the Operations Virtual Network.
`operationsSubnetAddressPrefix` | '10.0.115.0/27' | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.
`sharedServicesVirtualNetworkAddressPrefix` | '10.0.120.0/26' | The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.
`sharedServicesSubnetAddressPrefix` | '10.0.120.0/27' | The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.

### Optional Features

MLZ has optional features that can be enabled by setting parameters on the deployment.

#### Azure Policy Initiatives: NIST, IL5, CMMC

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the `deployPolicy=true` parameter with `policy` assigned to one of the following: `NIST`, `IL5`, or `CMMC`.

The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

Under the [src/bicep/modules/policies](..src/bicep/modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

#### Azure Security Center (Microsoft Defender for Cloud)

By default [Azure Security Center](https://docs.microsoft.com/en-us/azure/security-center/security-center-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when your first set up a subscription and view Azure Security Center portal blade.

Azure Security Center offers a standard/defender sku which enables a greater depth of awareness including more reccomendations and threat analytics. You can enable this higher depth level of security in MLZ by setting the parameter `deployASC` during deployment. In addition you can include the `emailSecurityContact` parameter to set a contact email for alerts.

#### Azure Sentinel

Azure Sentinel can be enabled by setting the `deploySentinel=true` parameter.

#### Remote access with a Bastion host plus a Linux VM and a Windows VM to serve as jump boxes

If you want to remotely access the network and the resources you've deployed you can use [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/) to remotely access virtual machines within the network without exposing them via Public IP Addresses.

To deploy a virtual machine as a jumpbox into the network without a Public IP Address using Azure Bastion Host, provide these parameters:

- `deployRemoteAccess=true`
- `windowsVmAdminPassword=<your password>`
- `linuxVmAuthenticationType=<'sshPublicKey' | 'password'>`
- `linuxVmAdminPasswordOrKey=<your password or SSH Key>`
- `windowsVmAdminUsername=<user name>` The default is 'azureuser'.
- `linuxVmAdminUsername=<user name>` The default is 'azureuser'.

#### Azure Firewall Premium

By default, MLZ deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features). Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions). If necessary you can set a different firewall SKU or location.

You can manually specify which SKU of Azure Firewall to use for your deployment by specifying the `firewallSkuTier` parameter. This parameter only accepts values of `Standard` or `Premium`.

If you'd like to specify a different region to deploy your resources into, change the location of the deployment. For example, when using the AZ CLI set the deployment command's `--location` argument.

- Review the default [Naming Convention](#Naming-Conventions) or apply your own

  - By default, Mission LZ creates resources with a naming convention
  - See [Naming Convention](#Naming-Conventions) to see what that convention is and how to provide your own to suit your needs

### Naming Conventions

By default, Mission LZ resources are named according to a naming convention that uses the mandatory `resourcePrefix` parameter and the optional `resourceSuffix` parameter (that is defaulted to `mlz`).

#### Default Naming Convention Example

Let's look at an example using `--parameters resourcePrefix=FOO` and `--parameters resourceSuffix=BAR`

- In `mlz.bicep` you will find a variable titled `namingConvention`:

    ```bicep
    var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'
    # this generates a value of: foo-${resourceToken}-${nameToken}-bar
    ```

- This naming convention uses Bicep's `replace()` function to substitute resource abbreviations for `resourceToken` and resource names for `nameToken`.

- For example, when naming the Hub Resource Group, first the `resourceToken` is substituted with the recommended abbreviation `rg`:

    ```bicep
    var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
    # this generates a value of: foo-rg-${nameToken}-bar
    ```

- Then, the `nameToken` is substituted with the Mission LZ name `hub`:

    ```bicep
    var hubResourceGroupName =  replace(resourceGroupNamingConvention, nameToken, 'hub')
    # this generates a value of: foo-rg-hub-bar
    ```

- Finally, the `hubResourceGroupName` is assigned to the resource group `name` parameter:

  ```bicep
  params: {
    name: hubResourceGroupName # this is the calculated value 'foo-rg-hub-bar'
    location: location
    tags: calculatedTags
  }
  ```

#### Modifying the Naming Convention

You can modify this naming convention to suit your needs.

- In `mlz.bicep` you can modify the root naming convention. This is the default convention:

    ```bicep
    var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'
    ```

- Say you did not want to use the `resourceSuffix` value, but instead wanted to add your own token to the naming convention like `team`:

- First, you added the new parameter `team`:

    ```bicep
    @allowedValues([
      'admin'
      'marketing'
      'sales'
    ])
    param team
    ```

- Then, you modified the naming convention to allow for mixed case `resourcePrefix` values and your new `team` value (while retaining the token identifiers `resourceToken` and `nameToken`):

    ```bicep
    var namingConvention = '${resourcePrefix}-${team}-${resourceToken}-${nameToken}'
    ```

- Now, given a `--parameters resourcePrefix=FOO` and `--parameters team=sales` the generated Hub Resource Group Name would be:

    ```plaintext
    params: {
      name: hubResourceGroupName # this is the calculated value 'FOO-sales-rg-hub'
      location: location
      tags: calculatedTags
    }
    ```

### Know where to find your deployment output

After a deployment is complete, you can refer to the provisioned resources programmaticaly with the Azure CLI. See [Reference Deployment Output](#Reference-Deployment-Output) for steps on how to use `az deployment` subcommands and JMESPath to query for specific properties.

From the Azure Portal you can see the deployment output by going to the subscription where the firewall was deployed, then clicking `Deployments` in the left navigation pane.

### Planning for Workloads

MLZ allows for deploying one or many workloads that are peered to the hub network. Each workload can be in its own subscription or multiple workloads may be combined into a single subscription.

A separate Bicep template is provided for deploying an empty workload. It deploys a virtual network, a route table, a network security group, a storage account (for logs), and a network peering to the hub network. The template is at [src/bicep/examples/newWorkload](../src/bicep/examples/newWorkload).

The `newWorkload` template contains defaults for IP address ranges, but additional workloads will require planning for additional ranges. The following parameters affect `newWorkload` networking:

- `virtualNetworkAddressPrefix`, defaults to '10.0.125.0/26'.
- `subnetAddressPrefix`, defaults to '10.0.125.0/27'.

For your workloads you can use this template as a starting point to create and customize specific workload deployments.

## Deployment

### Deploy Using the Azure Portal

The Azure Portal can be used to deploy Mission Landing Zone.

<!-- markdownlint-disable MD013 -->
<!-- allow for longer lines to acommodate button links -->
| Azure Commercial | Azure Government |
| :--- | :--- |
| [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
<!-- markdownlint-enable MD013 -->

### Deploy Using the Azure CLI

Use `az deployment sub` to deploy MLZ across one or many subscriptions. (See `az deployment sub create --help` for more information.)

#### Single subscription deployment

To deploy Mission LZ into a single subscription, give your deployment a name and a location and specify the `./mlz.bicep` template file (replacing `mlz.bicep` with `mlz.json` if disconnected from the internet or you do not have an installation of [Bicep](https://aka.ms/bicep) available):

```plaintext
az deployment sub create \
  --name myMlzDeployment \
  --location eastus \
  --template-file ./mlz.bicep \
  --parameters resourcePrefix="myMlz"
```

#### Multiple subscription deployment

Deployment to multiple subscriptions requires specifying the `--parameters` flag and passing `key=value` arguments:

```plaintext
az deployment sub create \
  --subscription $deploymentSubscription \
  --location eastus \
  --name multiSubscriptionTest \
  --template-file ./mlz.bicep \
  --parameters \
    resourcePrefix="myMlz" \
    hubSubscriptionId=$hubSubscriptionId \
    identitySubscriptionId=$identitySubscriptionId \
    operationsSubscriptionId=$operationsSubscriptionId \
    sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

#### Deploying to Other Clouds

When deploying to another cloud, like Azure US Government, first set the cloud and log in.

Logging into `AzureUsGovernment`:

```plaintext
az cloud set -n AzureUsGovernment
az login
```

...and supply a different value for the deployment `--location` argument:

```plaintext
az deployment sub create \
  --name myMlzDeployment \
  --location usgovvirginia \
  --template-file ./mlz.bicep
```

#### Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

The ARM template is at [src/bicep/mlz.json](../src/bicep/mlz.json)]. The AZ CLI command for deploying the ARM template is the same as for deploying Bicep: use `az deployment sub create` and supply `mlz.json` as the template file name instead of `mlz.bicep`.

#### Reference Deployment Output

After you've deployed Mission Landing Zone you'll probably want to integrate additional services or infrastructure.

You can use the `az deployment sub show` command with a `--query` argument to retrieve information about the resources you deployed.

Before giving the next steps a try, it's probably a good idea to [review the Azure CLI's documentation on querying with JMESPath](https://docs.microsoft.com/en-us/cli/azure/query-azure-cli).

First off, let's say you deployed Mission Landing Zone with a deployment name of `myMissionLandingZone`:

```plaintext
az deployment sub create \
  --name "myMissionLandingZone" \
  --location "East US" \
  --template-file "src/bicep/mlz.bicep"
```

Once it's complete, you could see all the resources provisioned in that deployment by querying the `properties.outputResources` property:

```plaintext
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputResources"
```

That's a lot of resources. Thankfully, the template produces outputs for just the things you _probably_ need at `properties.outputs`:

```plaintext
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs"
```

For example, if you need just the Firewall Private IP address you could retrieve it like this:

```plaintext
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs.firewallPrivateIPAddress.value"
```

Or, if you need just the Log Analytics Workspace that performs central logging you could retrieve it like this:

```plaintext
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs.logAnalyticsWorkspaceResourceId.value"
```

Or, say you wanted to deploy resources into the Identity spoke. You could retrieve information about the Identity spoke by querying it from the `properties.outputs.spokes` array like this:

```plaintext
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs.spokes.value[?name=='identity']"
```

Which would return an output similar to:

```json
[
  {
    "name": "identity",
    "networkSecurityGroupName": "identity-nsg",
    "networkSecurityGroupResourceId": ".../providers/Microsoft.Network/networkSecurityGroups/identity-nsg",
    "resourceGroupId": ".../resourceGroups/mlz-identity",
    "resourceGroupName": "mlz-identity",
    "subnetAddressPrefix": "10.0.110.0/27",
    "subnetName": "identity-subnet",
    "subscriptionId": "<A GUID>",
    "virtualNetworkName": "identity-vnet",
    "virtualNetworkResourceId": ".../providers/Microsoft.Network/virtualNetworks/identity-vnet"
  }
]
```

Bicep templates, the Azure CLI, and JMESpath queries allows you to manually, or in an automated fashion, compose infrastructure incrementally and pass output from one template as input to another.

Read more about `az deployment` at: [https://docs.microsoft.com](https://docs.microsoft.com/en-us/cli/azure/deployment?view=azure-cli-latest)

Read more about JMESPath queries at: <https://jmespath.org/>

## Cleanup

The Bicep/ARM deployment of Mission Landing Zone can be deleted with two steps:

1. Delete all resource groups.
1. Delete the diagnostic settings deployed at the subscription level.

> NOTE: If you deploy and delete Mission Landing Zone in the same subscription multiple times without deleting the subscription-level diagnostic settings, the sixth deployment will fail. Azure has a limit of five diagnostic settings per subscription. The error will be similar to this: `"The limit of 5 diagnostic settings was reached."`

To delete the diagnostic settings from the Azure Portal: choose the subscription blade, then Activity log in the left panel. At the top of the Activity log screen click the Diagnostics settings button. From there you can click the Edit setting link and delete the diagnostic setting.

To delete the diagnotic settings in script, use the AZ CLI or PowerShell. An AZ CLI example is below:

```BASH
# View diagnostic settings in the current subscription
az monitor diagnostic-settings subscription list --query value[] --output table

# Delete a diagnostic setting
az monitor diagnostic-settings subscription delete --name <diagnostic setting name>
```

## Development Pre-requisites

If you want to develop with Bicep you'll need these:

1. Install Azure CLI <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#install>
1. Install Bicep <https://github.com/Azure/bicep/blob/main/docs/installing.md#install-and-manage-via-azure-cli-easiest>

However, you don't need to develop with Bicep to deploy the compiled `mlz.json` in this repository.

## See Also

[Bicep documentation](https://aka.ms/bicep/) for documentation and general information on Bicep.
