# Zero Trust (TIC3.0) Workbook Example

This example adds an Azure Sentinel: Zero Trust (TIC3.0) Workbook solution to MLZ, provided Sentinel has already been deployed; either through the bicep or [terraform implementation instructions](../sentinel/README.md) in the Operations (T1) resource group.

## What this example does

### Deploys a Zero Trust (TIC3.0) Workbook in Azure Sentinel

Documentation can be found here: [Build and monitor Zero Trust (TIC 3.0) security architectures with Microsoft Sentinel](https://docs.microsoft.com/en-us/security/zero-trust/integrate/sentinel-solution)

### Pre-requisites

1. A MissionLZ deployment with Security Center and Sentinel enabled

2. Enablement of [enhanced security features in Microfost Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security)

The following table lists the required parameters for a missionLZ deployment to enable a Azure Sentinel Workbook:

Required Parameters | Description
------------------- | -----------
_location_ | The region to deploy Azure Sentinel into
_resourcePrefix_ | A 3-10 alphanumeric character string without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements
_deploySentinel_ | A boolean expression indicating that Azure Sentinel is to be deployed with the MissionLZ deployment
_deployASC_ | A boolean expression indicating that Azure Security Center (or Microsoft Defender for Cloud) is enabled in the MissionLZ deployment

An example deployment with required deployment parameters included is shown below:

```bash
# after a Mission LZ deployment
#
# az deployment sub create \
#   --subscription $deploymentSubscription \
#   --name "myMlzDeployment" \
#   --template-file ./mlz.bicep \
#   --parameters resourcePrefix=$resourcePrefix \
#   deploySentinel=true \
#   deployDefender=true
```

## Deploying Sentinel Zero Trust (TIC3.0) Workbook

The Sentinel Zero Trust (TIC3.0) Workbook is maintained in the [Azure Sentinel GitHub repository](https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/ZeroTrust(TIC3.0)/readme.md)

With the link provided, it is possible to use the "Deploy to Azure" button with some simple input parameters for Azure Government and Azure Commercial clouds.

From the pre-existing deployment of MLZ shown above, the following parameters are required for deployment of the Azure Sentinel Workbook:

 Required Input Parameters | Description
---------------------------|------------
_operationsSubscriptionId_ | The subscription that contains the Log Analytics Workspace and to deploy the Sentinel solution into
_operationsResourceGroupName_ | The resource group that contains the Log Analytics Workspace to link Azure Sentinel to
_logAnalyticsWorkspaceName_ | The name of the Log Analytics Workspace to link Azure Sentinel to

One way to retreive these values is with the Azure CLI:

az deployment sub show \
  --subscription $deploymentSubscription \
  --name "myMlzDeployment" \
  --query properties.outputs

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
```

...and if you're on a BASH terminal, this command (take note to replace "myMlzDeployment" with your deployment name) will export the values as environment variables:

```bash
export $(az deployment sub show --name "myMlzDeployment" --query "properties.outputs.{ args: [ join('', ['operationsResourceGroupName=', operationsResourceGroupName.value]), join('', ['logAnalyticsWorkspaceName=', logAnalyticsWorkspaceName.value])] }.args" --out tsv | xargs)
```

To deploy the workbook through Azure CLI:

```bash
az deployment group create \
--name MlzWorkbookDeploy \
--resource-group $operationsResourceGroupName \
--template-uri "https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Solutions/ZeroTrust(TIC3.0)/Package/mainTemplate.json" \
--parameters workspace=$logAnalyticsWorkspaceName
```
