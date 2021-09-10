# MLZ Bicep

## Development Pre-requisites

If you want to develop with Bicep you'll need these:

1. Install Azure CLI https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#install
1. Install Bicep https://github.com/Azure/bicep/blob/main/docs/installing.md#install-and-manage-via-azure-cli-easiest

However, you don't need Bicep to deploy the compiled `mlz.json` in this repository.

## Deployment

### Deployment Pre-requisites

You can deploy with the Azure Portal, the Azure CLI, or with both in an Air-Gapped Cloud. But first, you'll need these pre-requisites:

1. An Azure Subscription
1. Contributor RBAC permissions to that subscription

### Azure Portal

#### AzureCloud
[![Deploy To Azure](docs/imgs/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fglennmusa%2Fmissionlz%2Fglennmusa%2Fbicep%2Fsrc%2Fbicep%2Fmlz.json)

#### AzureUSGovernment
[![Deploy To Azure US Gov](docs/imgs/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fglennmusa%2Fmissionlz%2Fglennmusa%2Fbicep%2Fsrc%2Fbicep%2Fmlz.json)

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

### Air-Gapped Clouds

#### Manually upload and deploy from Portal

1. Save `mlz.json` to disk: https://raw.githubusercontent.com/glennmusa/missionlz/glennmusa/bicep/src/bicep/mlz.json
1. Create a deployment using the 'Custom Deployment' feature: https://portal.azure.com/#create/Microsoft.Template or https://portal.azure.us/#create/Microsoft.Template
1. Click 'Build your own template in the editor'
1. Click 'Load file'
1. Select the 'mlz.json' file you saved
1. Click 'Save'
1. Click 'Review + Create'

Check out this GIF in the docs to see a visual explanation: [docs/imgs/custom_template_deployment.gif](docs/imgs/custom_template_deployment.gif)

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

Under the [modules/policies](modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

## Adding Remote Access via Bastion Host

To deploy a virtual machine as a jumpbox into the network without a Public IP Address using Azure Bastion Host, provide two parameters `deployRemoteAccess=true` and `linuxVmAdminPasswordOrKey=<your password>` to the deployment. A quick and easy way to generate a secure password from the .devcontainer is the command `openssl rand -base64 14`.

```plaintext
my_password=$(openssl rand -base64 14)

az deployment sub create \
  --name "myRemoteAccessDeployment" \
  --location "eastus" \
  --template-file "src/bicep/mlz.bicep" \
  --parameters deployRemoteAccess="true" \
  --parameters linuxVmAdminPasswordOrKey="$my_password"
```
