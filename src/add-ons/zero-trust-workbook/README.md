# Zero Trust (TIC3.0) Workbook Example

This example adds an Azure Sentinel: Zero Trust (TIC3.0) Workbook solution to MLZ, provided Sentinel has already been deployed in the Operations (T1) resource group.

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

 az deployment sub create \
   --name "myMlzDeployment" \
   --location eastus \
   --template-file src/bicep/mlz.bicep \
   --parameters resourcePrefix=myPrefix \
   deploySentinel=true \
   deployDefender=true
```

## Deploying Sentinel Zero Trust (TIC3.0) Workbook

The Sentinel Zero Trust (TIC3.0) Workbook is maintained in the [Azure Sentinel GitHub repository](https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/ZeroTrust(TIC3.0)/readme.md)

With the link provided, it is possible to use the "Deploy to Azure" button with some simple input parameters for Azure Government and Azure Commercial clouds.

### Command Line Workbook Deployment

The workbook can be deployed using the Azure CLI `az deployment` command. The workbook template requires the `workspace` parameter, which is the name of the Log Analytics workspace connected to Sentinel in MLZ. The workspace name can be found in the MLZ operations resource group, which also contains the Log Analytics and Sentinel deployment. The same resource group is where the `az deployment` command
is deployed. See the example below:

```bash
az deployment group create \
--name MlzWorkbookDeploy \
--resource-group myPrefix-rg-operations-mlz \
--template-uri "https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Solutions/ZeroTrust(TIC3.0)/Package/mainTemplate.json" \
--parameters workspace=myPrefix-log-operations-mlz
```
