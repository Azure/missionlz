# MLZ Bicep

## Development Pre-requisites

If you want to develop with Bicep you'll need these:

1. Install Azure CLI <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#install>
1. Install Bicep <https://github.com/Azure/bicep/blob/main/docs/installing.md#install-and-manage-via-azure-cli-easiest>

However, you don't need Bicep to deploy the compiled `mlz.json` in this repository.

## Deployment

### Deployment Pre-requisites

You can deploy with the Azure Portal, the Azure CLI, or with both in an Air-Gapped Cloud. But first, you'll need these pre-requisites:

1. An Azure Subscription
1. Contributor RBAC permissions to that subscription

### Azure Portal

#### AzureCloud

[![Deploy To Azure](../../docs/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure%2Fmissionlz%2Fbicep%2Fsrc%2Fbicep%2Fmlz.json)

#### AzureUSGovernment

[![Deploy To Azure US Gov](../../docs/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure%2Fmissionlz%2Fbicep%2Fsrc%2Fbicep%2Fmlz.json)

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

### Adding Azure Policy

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the parameter with one of the following, NIST, IL5 or CMMC. For example deploying with MLZ:

```plaintext
az deployment sub create \
  --location eastus \
  --template-file mlz.bicep \
  --parameters policy=<one of 'CMMC', 'IL5', or 'NIST'>
```

For example deploying after MLZ:

```plaintext
az deployment group create \
  --resource-group <Resource Group to assign> \
  --name <original deployment name + descriptor> \
  --template-file ./src/bicep/modules/policyAssignment.bicep \
  --parameters builtInAssignment=<one of 'CMMC', 'IL5', or 'NIST'> logAnalyticsWorkspaceName=<Log analytics workspace name> workspaceResourceGroupName=<LA Workspace resource group name>
```

Under the modules\policies directory are files named accordingly for the initiatives parameters with defaults  except for where a Log Analytics workspace ID is required we substitute that with the MLZ workspace ID, All others can be changed appropriately.

The result will be a policy assignment created for each resource group deployed by MLZ base fabric which can be viewed in the 'Compliance' view of Azure Policy in the portal.

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
