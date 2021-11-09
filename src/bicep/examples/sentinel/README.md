# Sentinel Example

This example adds an Azure Sentinel solution to a Log Analytics Workspace using two independent deployment methods:  Bicep or Terraform.  Pick whichever works best.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys Sentinel

The docs on Azure Sentinel: <https://docs.microsoft.com/en-us/azure/sentinel/overview>.  This sample shows how to deploy using either Bicep or Terraform.  The deployment options are not intended to be used together, both are wholly independent options.

## Pre-requisites

### Bicep Deployment Option

1. A Mission LZ deployment (a deployment of mlz.bicep)
2. The output from that deployment described below:

Deployment Output Name | Description
-----------------------| -----------
logAnalyticsWorkspaceName | The Log Analytics Workspace to which Azure Sentinel will be added as as solution
logAnalyticsWorkspaceResourceId | The resource ID of the Log Anayltics Workspace for use within Azure Sentinel
operationsResourceGroupName | The resource group name which contains the Log Analytics Workspace to be used with Azure Sentinel
operationsSubscriptionId | The Azure subscription ID which contains the operations resource group deployed as part of MLZ

One way to generate a global variable file(deploymentVariables.json) which contains all of the needed values for this examples and others as well is through PowerShell Core and the Azure PowerShell module.  Both PowerShell Core and the Azure PowerShell module are open source projects and avaliable for all major operating systems (Mac, Linux, Windows).

* Get PowerShell Core:  <https://github.com/PowerShell/PowerShell/releases>
* Get Azure PowerShell: <https://docs.microsoft.com/en-us/powershell/azure/install-az-ps>
* Getting Started with Azure PowerShell: <https://docs.microsoft.com/en-us/powershell/azure/get-started-azureps>
* Generate 'deploymentVariables.json': (Get-AzSubscriptionDeployment -Name MLZDeploymentName).outputs | ConvertTo-Json -Depth 10 | Out-File -FilePath .\deploymentVariables.json
* Replace "MLZDeploymentName" with your deployment name:  Browse to 'Subscriptions', to the subscription MLZ was deployed into, and then look at 'Deployments'

Place the 'deploymentVariables.json' file ./src/bicep/examples folder.  See the sample for reference.

### Deploying Sentinel - Bicep

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding Azure Sentinel post-deployment. 

```PowerShell
cd ./src/bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contosoMLZ -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd ./examples
(Get-AzSubscriptionDeployment -Name contosoMLZ).outputs | ConvertTo-Json -Depth 10 | Out-File -FilePath .\deploymentVariables.json
cd ./sentinel
New-AzSubscriptionDeployment -DeploymentName deploySentinel -TemplateFile .\sentinel.bicep -Location 'eastus'
```

Or, completely experimentally, try the Portal:

### AzureCloud

[![Deploy To Azure](../../../../docs/images/deploytoazure.svg?sanitze=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fexamples%2Fsentinel%2Fmodules%2FdeploySentinel.json)

### AzureUSGovernment

[![Deploy To Azure US Gov](../../../../docs/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fexamples%2Fsentinel%2Fmodules%2FdeploySentinel.json)

## Terraform Deployment Option

1. Terraform ([link to download](https://www.terraform.io/downloads.html))
2. An internet connection (you can bundle Terraform dependencies, but this example does not and retrieves them from the internet)
3. A desired region to deploy Azure Sentinel into described below
4. A Mission LZ deployment (a deployment of mlz.bicep)
5. The output from that deployment described below

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

## Deploying Sentinel - Terraform

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
