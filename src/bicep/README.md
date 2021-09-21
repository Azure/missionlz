# MLZ Bicep

## Development Pre-requisites

If you want to develop with Bicep you'll need these:

1. Install Azure CLI <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#install>
1. Install Bicep <https://github.com/Azure/bicep/blob/main/docs/installing.md#install-and-manage-via-azure-cli-easiest>

However, you don't need to develop with Bicep to deploy the compiled `mlz.json` in this repository.

## Deployment

### Deployment Pre-requisites

You can deploy with the Azure Portal, the Azure CLI, or with both in an Air-Gapped Cloud. But first, you'll need these pre-requisites:

1. An Azure Subscription
1. Contributor RBAC permissions to that subscription

Looking to deploy into another cloud than `AzureCloud` like say `AzureUsGovernment`? See [Deploying to Other Clouds](#Deploying-to-Other-Clouds).

Want to add Azure Policies to this deployment? See [Adding Azure Policy](#Adding-Azure-Policy) to add policies like DoD IL5, NIST 800-53, CMMC Level 3, or how to apply your own.

Want to remotely access the network without exposing it via Public IP Addresses? See [Adding Remote Access via Bastion Host](#Adding-Remote-Access-via-Bastion-Host) to add virtual machines inside the network that you can access from an authenticated session in the Azure Portal with Azure Bastion.

### Azure CLI

Use `az deployment sub` to deploy MLZ across 1:M subscriptions (and `az deployment sub create --help` for more information):

```plaintext
# az bicep install

# the minimum needed to deploy (deployment will occur in your default subscription):
az deployment sub create \
  --location eastus \
  --name test \
  --template-file ./mlz.bicep

# to deploy into multiple subscriptions specify the `--parameters` flag and pass `key=value` arguments:
az deployment sub create \
  --subscription $deploymentSubscription \
  --location eastus \
  --name multisubtest \
  --template-file ./mlz.bicep \
  --parameters \
    hubSubscriptionId=$hubSubscriptionId \
    identitySubscriptionId=$identitySubscriptionId \
    operationsSubscriptionId=$operationsSubscriptionId \
    sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

#### Deploying to Other Clouds

Supply a different deployment `--location` or override variables with the `--parameters` options:

```plaintext
# if I were deploying into AzureUSGovernment for example:
az cloud set -n AzureUsGovernment
az deployment sub create \
  --subscription $deploymentSubscription \
  --location usgovvirginia \
  --name multisubtest \
  --template-file ./mlz.bicep \
  --parameters \
    hubSubscriptionId=$hubSubscriptionId \
    identitySubscriptionId=$identitySubscriptionId \
    operationsSubscriptionId=$operationsSubscriptionId \
    sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

### Azure Portal

#### AzureCloud

[![Deploy To Azure](../../docs/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json)

#### AzureUSGovernment

[![Deploy To Azure US Gov](../../docs/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json)

### Air-Gapped Clouds

#### Manually upload and deploy from Portal

1. Save `mlz.json` to disk: <https://github.com/Azure/missionlz/blob/bicep/src/bicep/mlz.json>
1. Create a deployment using the 'Custom Deployment' feature: <https://portal.azure.com/#create/Microsoft.Template> or <https://portal.azure.us/#create/Microsoft.Template>
1. Click 'Build your own template in the editor'
1. Click 'Load file'
1. Select the 'mlz.json' file you saved
1. Click 'Save'
1. Click 'Review + Create'

Check out this GIF in the docs to see a visual explanation: [../../docs/images/custom_template_deployment.gif](../../docs/images/custom_template_deployment.gif)

#### Deploy with Azure CLI

If I were in an environment that didn't have a bicep installation available (like an air-gapped cloud), I could always deploy the `az bicep build` generated ARM template `mlz.json`:

```plaintext
az bicep build -f ./mlz.bicep --outfile mlz.json

az cloud set -n AzureUsGovernment

az deployment sub create \
  --subscription $deploymentSubscription \
  --location usgovvirginia \
  --name multisubtest \
  --template-file ./mlz.json \
  --parameters \
    hubSubscriptionId=$hubSubscriptionId \
    identitySubscriptionId=$identitySubscriptionId \
    operationsSubscriptionId=$operationsSubscriptionId \
    sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

## Adding Azure Policy

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the parameter with one of the following, NIST, IL5 or CMMC. For example deploying with MLZ:

```plaintext
az deployment sub create \
  --location eastus \
  --template-file mlz.bicep \
  --parameters policy=<one of 'CMMC', 'IL5', or 'NIST'>
```

Or, apply policy after deploying MLZ:

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
