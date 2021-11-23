# App Service Plan Example

This example deploys an App Service Plan (AKA: Web Server Cluster) to support simple web accessible linux docker containers.  It also optionally supports the use of dynamic (up and down) scale settings based on CPU percentage up to a max of 10 compute instances.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys an Azure App Service Plan

The docs on Azure App Service Plans: <https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans>.  This sample shows how to deploy using Bicep and utilizes the shared file variable pattern to support the deployment.  By default, this template will deploy resources into standard default MLZ subscriptions and resource groups.  

The subscription and resource group can be changed by providing the resource group name (Param: targetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
2. The outputs from a deployment of mlz.bicep (./src/bicep/examples/deploymentVariables.json).  

See below for information on how to create the appropriate deployment variables file for use with this template.

### Template Parameters

Template Parameters Name | Description
-----------------------| -----------
appServicePlanName | The name of the App Service Plan.  If not specified, the name will default to the MLZ default naming pattern.  
targetResourceGroup | The name of the resource group where the App Service Plan will be deployed.   If not specified, the resource group name will default to the shared services MLZ resource group name and subscription.
enableAutoScale | A true/false value that determines if dynamic auto scale is enabled.  If set to "true", dynamic auto scale is enabled up to a maximum of 10 compute instances based on CPU percentage exceeding 70% for 10 minutes.   Will also scale down if CPU percentage is below 30% for 10 minutes.  If set to "false", the App Service Plan will statically maintain two compute instances indefinitely.

### Generate MLZ Variable File (deploymentVariables.json)

For instructions on generating 'deploymentVariables.json' using both Azure PowerShell and Azure CLI, please see the [README at the root of the examples folder](..\README.md).

Place the resulting 'deploymentVariables.json' file within the ./src/bicep/examples folder.

### Deploying App Service Plan

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure App Service Plan post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\examples
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\AppServicePlan
New-AzSubscriptionDeployment -DeploymentName deployAppServicePlan -TemplateFile .\appService.bicep -Location 'eastus'
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd examples
az deployment sub show -n contoso --query properties.outputs > ./deploymentVariables.json
cd appServicePlan
az deployment sub create -n deployAppServicePlan -f appService.bicep -l eastus
```

### References

* <https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans>
* <https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file>
