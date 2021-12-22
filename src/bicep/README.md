# Mission LZ Bicep

## Deployment

### Prerequisites

You can deploy with the Azure Portal, the Azure CLI, or with both in a Azure Commercial, Azure for Government, or Air-Gapped Clouds. But first, you'll need these pre-requisites:

1. An Azure Subscription(s) where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)
1. A BASH or PowerShell terminal where you can run the Azure CLI. For example, [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), the MLZ [development container](../../.devcontainer/README.md), or a command shell on your local machine with the [AZ CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed.

> NOTE: The AZ CLI will automatically install the Bicep tools when a command is run that needs them, or you can manually install them following the [instructions here.](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)

#### Decide on a Resource Prefix

Resource Groups and resource names are derived from the mandatory parameter `resourcePrefix`.

Pick a unqiue resource prefix that is 3-10 alphanumeric characters in length without whitespaces.

#### Pick your deployment options

- Are you deploying into a cloud other than `AzureCloud` like say `AzureUsGovernment`?

  - See [Deploying to Other Clouds](#Deploying-to-Other-Clouds).

- Want to add Azure Policies to this deployment?

  - See [Adding Azure Policy](#Adding-Azure-Policy) to add policies like DoD IL5, NIST 800-53, CMMC Level 3, or how to apply your own.

- Want to remotely access the network without exposing it via Public IP Addresses?

  - See [Adding Remote Access via Bastion Host](#Adding-Remote-Access-via-Bastion-Host) to add virtual machines inside the network that you can access from an authenticated session in the Azure Portal with Azure Bastion.

- By default, this template deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features)**.

  - **Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions). If this doesn't fit your needs:
  - See [Setting the Firewall SKU](#Setting-the-Firewall-SKU) for steps on how to use the Standard SKU instead.
  - See [Setting the Firewall Location](#Setting-the-Firewall-Location) for steps on how to deploy into a different region.

- Review the default [Naming Convention](#Naming-Conventions) or apply your own

  - By default, Mission LZ creates resources with a naming convention
  - See [Naming Convention](#Naming-Conventions) to see what that convention is and how to provide your own to suit your needs

#### Know where to find your deployment output

After a deployment is complete, you can refer to the provisioned resources programmaticaly with the Azure CLI.

- See [Reference Deployment Output](#Reference-Deployment-Output) for steps on how to use `az deployment` subcommands and JMESPath to query for specific properties.

### Azure Portal

<!-- markdownlint-disable MD013 -->
<!-- allow for longer lines to acommodate button links -->
| Azure Commercial | Azure Government |
| :--- | :--- |
| [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
<!-- markdownlint-enable MD013 -->

### Azure CLI

Use `az deployment sub` to deploy MLZ across 1:M subscriptions (and `az deployment sub create --help` for more information).

#### Single subscription deployment

To deploy Mission LZ into a single subscription, give your deployment a name and a location and specify the `./mlz.bicep` template file (replacing `mlz.bicep` with `mlz.json` if I'm disconnected from the internet or do not have an installation of [Bicep](https://aka.ms/bicep) available):

```plaintext
az deployment sub create \
  --name myMlzDeployment \
  --location eastus \
  --template-file ./mlz.bicep
```

You'll be prompted for the one required argument `resourcePrefix` (a unique alphanumeric string 3-10 characters in length), which is used to to generate names for your resource groups and resources:

```plaintext
> Please provide string value for 'resourcePrefix' (? for help): mymlz01
```

#### Multiple subscription deployment

I can deploy into multiple subscriptions by specifying the `--parameters` flag and passing `key=value` arguments:

```plaintext
az deployment sub create \
  --subscription $deploymentSubscription \
  --location eastus \
  --name multiSubscriptionTest \
  --template-file ./mlz.bicep \
  --parameters \
    hubSubscriptionId=$hubSubscriptionId \
    identitySubscriptionId=$identitySubscriptionId \
    operationsSubscriptionId=$operationsSubscriptionId \
    sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

When deploying to multiple subscriptions, you must have at least [Contributor RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all) to those subscriptions.

#### Deploying to Other Clouds

If I'm deploying to another cloud, say Azure Government, I will first login to that cloud...

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

And if I need to deploy into multiple subscriptions, I would pass the relevant subscription IDs as `parameters` as described in [Multiple subscription deployment](#Multiple-subscription-deployment).

### Air-Gapped Clouds

#### Air-Gapped Clouds Deployment with Azure CLI

If I were in an offline environment that didn't have a Bicep installation available (like an air-gapped cloud), I could always deploy the `az bicep build` output ARM template **`mlz.json`**:

```plaintext
az cloud set -n <my cloud name>

az deployment sub create \
  --subscription $deploymentSubscription \
  --location <my location> \
  --name multisubtest \
  --template-file ./mlz.json \
  --parameters \
    hubSubscriptionId=$hubSubscriptionId \
    identitySubscriptionId=$identitySubscriptionId \
    operationsSubscriptionId=$operationsSubscriptionId \
    sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

## Adding Azure Policy

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the `deployPolicy=true` parameter with `policy` assigned to one of the following: `NIST`, `IL5`, or `CMMC`.

For example, deploying with MLZ:

```plaintext
az deployment sub create \
  --location eastus \
  --template-file mlz.bicep \
  --parameters deployPolicy=true \
  --parameters policy=<one of 'CMMC', 'IL5', or 'NIST'>
```

Or, apply policy to a resource group after deploying MLZ:

```plaintext
az deployment group create \
  --resource-group <Resource Group to assign> \
  --name <original deployment name + descriptor> \
  --template-file ./src/bicep/modules/policyAssignment.bicep \
  --parameters builtInAssignment=<one of 'CMMC', 'IL5', or 'NIST'> logAnalyticsWorkspaceName=<Log analytics workspace name> \
  --parameters logAnalyticsWorkspaceName=<Log Analytics Workspace Name> \
  --parameters logAnalyticsWorkspaceResourceGroupName=<Log Analytics Workspace Resource Group Name>
```

The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

Under the [modules/policies](modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

## Adding Azure Security Center

By default [Azure Security Center](https://docs.microsoft.com/en-us/azure/security-center/security-center-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when your first set up a subscription and view Azure Security Center portal blade.

Azure Security Center offers a standard/defender sku which enables a greater depth of awareness including more reccomendations and threat analytics. You can enable this higher depth level of security in MLZ by setting the parameter `deployASC` during deployment. In addition you can include the `emailSecurityContact` parameter to set a contact email for alerts.

```plaintext
az deployment sub create \
  --location eastus \
  --template-file mlz.bicep \
  --parameters policy=<one of 'CMMC', 'IL5', or 'NIST'> \
  --parameters deployASC=true \
  --parameters emailSecurityContact=<user#domain.com>
```

## Adding Remote Access via Bastion Host

Want to remotely access the network and the resources you've deployed into it? You can use [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/) to remotely access virtual machines within the network without exposing them via Public IP Addresses.

To deploy a virtual machine as a jumpbox into the network without a Public IP Address using Azure Bastion Host, provide two parameters `deployRemoteAccess=true` and `linuxVmAdminPasswordOrKey=<your password>` and `windowsVmAdminPassword=<your password>` to the deployment. A quick and easy way to generate a secure password from the .devcontainer is the command `openssl rand -base64 14`.

```plaintext
my_password=$(openssl rand -base64 14)

az deployment sub create \
  --name "myRemoteAccessDeployment" \
  --location "eastus" \
  --template-file "src/bicep/mlz.bicep" \
  --parameters deployRemoteAccess="true" \
  --parameters linuxVmAdminPasswordOrKey="$my_password" \
  --parameters windowsVmAdminPassword="$my_password"
```

Then, once you've deployed the virtual machines and Bastion Host, use these docs to connect with the provided password: <https://docs.microsoft.com/en-us/azure/bastion/bastion-connect-vm-rdp-windows#rdp>

The default username is set to `azureuser`.

### Using an SSH Key with Remote Access via Bastion Host

If you have a key pair you'd like to use for SSH connections to the Linux virtual machine that is deployed with `deployRemoteAccess=true`, specify the `linuxVmAuthenticationType` parameter to `sshPublicKey` like so:

```plaintext
my_sshkey=$(cat ~/.ssh/id_rsa.pub) # or, however you source your public key
my_password=$(openssl rand -base64 14)

az deployment sub create \
  --name "myRemoteAccessDeployment" \
  --location "eastus" \
  --template-file "src/bicep/mlz.bicep" \
  --parameters deployRemoteAccess="true" \
  --parameters linuxVmAuthenticationType="sshPublicKey" \
  --parameters linuxVmAdminPasswordOrKey="$my_sshkey" \
  --parameters windowsVmAdminPassword="$my_password"
```

For more information on generating a public/private key pair see <https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed#generate-keys-with-ssh-keygen>.

Then, once you've deployed the virtual machines and Bastion Host, use these docs to connect with an SSH Key: <https://docs.microsoft.com/en-us/azure/bastion/bastion-connect-vm-ssh#privatekey>

The default username is set to `azureuser`.

## Configuring the Firewall

### Setting the Firewall SKU

By default, this template deploys [Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features).

Not all regions support Azure Firewall Premium. Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions).

You can manually specify which SKU of Azure Firewall to use for your deployment by specifying the `firewallSkuTier` parameter. This parameter only accepts values of `Standard` or `Premium`:

```plaintext
az deployment sub create \
  --name "myFirewallStandardDeployment" \
  --location "eastus" \
  --template-file "src/bicep/mlz.bicep" \
  --parameters firewallSkuTier="Standard"
```

### Setting the Firewall Location

If you'd like to specify a different region to deploy your resources into, just change the location of the deployment in the `az deployment sub create` command's `--location` argument:

```plaintext
az deployment sub create \
  --name "SouthCentralUsDeployment" \
  --location "South Central US" \
  --template-file "src/bicep/mlz.bicep"
```

### Reference Deployment Output

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

## Naming Conventions

By default, Mission LZ resources are named according to a naming convention that uses the mandatory `resourcePrefix` parameter and the optional `resourceSuffix` parameter (that is defaulted to `mlz`).

### Default Naming Convention Example

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

### Modifying The Naming Convention

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
