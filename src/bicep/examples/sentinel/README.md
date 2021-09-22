# Sentinel Example

This example adds an Azure Sentinel solution to a Log Analytics Workspace using Terraform.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys Sentinel

The docs on Azure Sentinel: <https://docs.microsoft.com/en-us/azure/sentinel/overview>

## Pre-requisites

1. Terraform ([link to download](https://www.terraform.io/downloads.html))
1. An internet connection (you can bundle Terraform dependencies, but this example does not and retrieves them from the internet)
1. A desired region to deploy Azure Sentinel into described below
1. A Mission LZ deployment (a deployment of mlz.bicep)
1. The output from that deployment described below

Required Parameters | Description
------------------- | -----------
location | The region to deploy Azure Sentinel into

Deployment Output Name | Description
-----------------------| -----------
operationsSubscriptionId | The subscription that contains the Log Analytics Workspace and to deploy the Sentinel solution into
operationsResourceGroupName | The resource group that contains the Log Analytics Workspace to link Azure Sentinel to
logAnalyticsWorkspaceName | The name of the Log Analytics Workspace to link Azure Sentinel to
logAnalyticsWorkspaceResourceId | The resource ID of the Log Analytics Workspace to link Azure Sentinel to

One way to retreive these values is with the Azure CLI:

```bash
# after a Mission LZ deployment
#
# az deployment sub create \
#   --subscription $deploymentSubscription \
#   --name "myMlzDeployment" \
#   --template-file ./mlz.bicep \

az deployment sub show \
  --subscription $deploymentSubscription \
  --name "myMlzDeployment" \
  --query properties.outputs
```

...which should return an object containing the values you need:

```plaintext
{
  "operationsSubscriptionId": {
    "type": "String",
    "value": "0987654-3210..."
  },
  ...
  "operationsResourceGroupName": {
    "type": "String",
    "value": "mlz-dev-operations"
  },
  ...
  "logAnalyticsWorkspaceName": {
    "type": "String",
    "value": "mlz-dev-laws"
  },
  ...
  "logAnalyticsWorkspaceResourceId": {
    "type": "String",
    "value": "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/mlz-dev-laws"
  },
}
```

...and if you're on a BASH terminal, this command (take note to replace "myMlzDeployment" with your deployment name) will export the values as environment variables:

<!-- markdownlint-disable MD013 -->
```bash
export $(az deployment sub show --name "myMlzDeployment" --query "properties.outputs.{ args: [ join('', ['operationsSubscriptionId=', operationsSubscriptionId.value]), join('', ['operationsResourceGroupName=', operationsResourceGroupName.value]), join('', ['logAnalyticsWorkspaceName=', logAnalyticsWorkspaceName.value]), join('', ['logAnalyticsWorkspaceResourceId=', logAnalyticsWorkspaceResourceId.value]) ] }.args" --output tsv | xargs)
```
<!-- markdownlint-enable MD013 -->

## Deploying Sentinel

You'll need to initialize Terraform in this directory:

```bash
cd examples/sentinel

terraform init
```

Then, using our MLZ deployment output [as input variables](https://www.terraform.io/docs/language/values/variables.html), and specifying a `location` variable, you can call Terraform apply:

```bash
location="eastus"

terraform apply \
  -var subscription_id="$operationsSubscriptionId" \
  -var location="$location" \
  -var resource_group_name="$operationsResourceGroupName" \
  -var workspace_resource_id="$logAnalyticsWorkspaceResourceId" \
  -var workspace_name="$logAnalyticsWorkspaceName"
```
