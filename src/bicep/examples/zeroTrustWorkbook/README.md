# Zero Trust (TIC3.0) Workbook Example

This example adds an Azure Sentinel: Zero Trust (TIC3.0) Workbook solution to MLZ, provided Sentinel has already been deployed; either through the bicep or [terraform implementation instructions](../sentinel/README.md) in the Operations (T1) resource group.

## What this example does

### Deploys a Zero Trust (TIC3.0) Workbook in Azure Sentinel

Documentation can be found here: [Build and monitor Zero Trust (TIC 3.0) security architectures with Microsoft Sentinel](https://docs.microsoft.com/en-us/security/zero-trust/integrate/sentinel-solution)

### Pre-requisites

1. A MissionLZ deployment with Microsoft Defender for Cloud and Azure Sentinel enabled

2. Enablement of [enhanced security features in Microfost Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security)

The following table lists the required parameters for a Mission LZ deployment to enable an Azure Sentinel Workbook:

Required Parameters | Description
------------------- | -----------
_location_ | The region to deploy Azure Sentinel into
_resourcePrefix_ | A 3-10 alphanumeric character string without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements
_deploySentinel_ | A boolean expression indicating that Azure Sentinel is to be deployed with the MissionLZ deployment
_deployDefender_ | A boolean expression indicating that Microsoft Defender for Cloud is enabled in the Mission LZ deployment

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

The `$operationsResourceGroupName` utilizes the `$resourcePrefix` in a typical Mission LZ deployment. The standard naming convention of the Operations resource group will be:

`$resourcePrefix-rg-operations-mlz`

This can be searchable through the Azure CLI as an example:

```bash
az group list --query [].name --out tsv | grep "operations"
```

To retrieve the `$logAnalyticsWorkspaceName`, the following naming convention will be adhered to in a typical Mission LZ deployment:

`$resourcePrefix-log-operations-mlz`

This parameter is searchable with the Azure CLI:

```bash
az monitor log-analytics workspace list --query [].name --out tsv --resource-group $operationsResourceGroupName
```

To deploy the workbook through Azure CLI:

```bash
az deployment group create \
--name MlzWorkbookDeploy \
--resource-group $operationsResourceGroupName \
--template-uri "https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Solutions/ZeroTrust(TIC3.0)/Package/mainTemplate.json" \
--parameters workspace=$logAnalyticsWorkspaceName
```
