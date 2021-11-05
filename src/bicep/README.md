# Mission LZ Bicep

## Deployment

### Prerequisistes

You can deploy with the Azure Portal, the Azure CLI, or with both in a Azure Commercial, Azure for Government, or Air-Gapped Clouds. But first, you'll need these pre-requisites:

1. An Azure Subscription(s) where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)

Are you deploying into a cloud other than `AzureCloud` like say `AzureUsGovernment`?

- See [Deploying to Other Clouds](#Deploying-to-Other-Clouds).

Want to add Azure Policies to this deployment?

- See [Adding Azure Policy](#Adding-Azure-Policy) to add policies like DoD IL5, NIST 800-53, CMMC Level 3, or how to apply your own.

Want to remotely access the network without exposing it via Public IP Addresses?

- See [Adding Remote Access via Bastion Host](#Adding-Remote-Access-via-Bastion-Host) to add virtual machines inside the network that you can access from an authenticated session in the Azure Portal with Azure Bastion.

By default, this template deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features)**.

**Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions). If this doesn't fit your needs:

- See [Setting the Firewall SKU](#Setting-the-Firewall-SKU) for steps on how to use the Standard SKU instead.
- See [Setting the Firewall Location](#Setting-the-Firewall-Location) for steps on how to deploy into a different region.

After a deployment is complete, you can refer to the provisioned resources programmaticaly with the Azure CLI.

- See [Reference Deployment Output](#Reference-Deployment-Output) for steps on how to use `az deployment` subcommands and JMESPath to query for specific properties.

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

### Azure Portal

You can also deploy Mission LZ from the Azure Portal. The compiled JSON ARM template of `mlz.bicep` can be executed from the Custom Deployment feature.

There is work in progress to provide a more elegant user-interface, but today, with the compiled output of `mlz.bicep`, you can set the deployment subscription and a deployment region and click 'Create' to start deployment.

#### AzureCloud

[![Deploy To Azure](../../docs/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json)

#### AzureUSGovernment

[![Deploy To Azure US Gov](../../docs/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json)

### Air-Gapped Clouds

#### Air-Gapped Clouds Deployment from the Azure Portal

1. Save `mlz.json` to disk: <https://raw.githubusercontent.com/Azure/missionlz/main/src/bicep/mlz.json>
1. Create a deployment using the 'Custom Deployment' feature: <https://portal.azure.com/#create/Microsoft.Template> or <https://portal.azure.us/#create/Microsoft.Template>
1. Click 'Build your own template in the editor'
1. Click 'Load file'
1. Select the 'mlz.json' file you saved
1. Click 'Save'
1. Click 'Review + Create'

Check out this GIF in the docs to see a visual explanation: [../../docs/images/custom_template_deployment.gif](../../docs/images/custom_template_deployment.gif)

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

## Development Pre-requisites

If you want to develop with Bicep you'll need these:

1. Install Azure CLI <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#install>
1. Install Bicep <https://github.com/Azure/bicep/blob/main/docs/installing.md#install-and-manage-via-azure-cli-easiest>

However, you don't need to develop with Bicep to deploy the compiled `mlz.json` in this repository.
