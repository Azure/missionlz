# App Service Plan Example

This example deploys an App Service Plan (AKA: Web Server Cluster) to support simple web accessible linux docker containers.  It also optionally supports the use of dynamic(up and down) scale settings based on CPU percentage up to a max of 10 compute instances.

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

Deployment Output Name | Description
-----------------------| -----------
appServicePlanName | The name of the App Service Plan.  If not specified, the name will default to the MLZ default naming pattern.  
targetResourceGroup | The name of the resource group where the App Service Plan will be deployed.   If not specified, the resource group name will default to the shared services MLZ resource group name and subscription.
enableAutoScale | A true/false value that determines if dyname auto scale is enabled.  If set to "true", dyanmic auto scale is enabled up to a maximum of 10 compute instances based on CPU percentage exceeding 70% for 10 minutes.   Will also scale in if CPU percentage is below 30% for 10 minutes.  If set to "false", the App Service Plan will statically maintain two compute instances indefinitely.

### Generate MLZ VAriable File (deploymentVariables.json)

One way to generate the MLZ variable file(deploymentVariables.json) which contains all of the needed values for this examples and others as well is through PowerShell Core and the Azure PowerShell module.  Both PowerShell Core and the Azure PowerShell module are open source projects and avaliable for all major operating systems (Mac, Linux, Windows).

* Get PowerShell Core:  <https://github.com/PowerShell/PowerShell/releases>
* Get Azure PowerShell: <https://docs.microsoft.com/en-us/powershell/azure/install-az-ps>
* Getting Started with Azure PowerShell: <https://docs.microsoft.com/en-us/powershell/azure/get-started-azureps>
* Generate 'deploymentVariables.json': (Get-AzSubscriptionDeployment -Name MLZDeploymentName).outputs | ConvertTo-Json -Depth 10 | Out-File -FilePath .\deploymentVariables.json
* Replace "MLZDeploymentName" with your deployment name:  Browse to 'Subscriptions', to the subscription MLZ was deployed into, and then look at 'Deployments'

Place the 'deploymentVariables.json' file ./src/bicep/examples folder.  See the sample for reference.

### Deploying App Service Plan

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure App Service Plan post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\examples
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json -Depth 10 | Out-File -FilePath .\deploymentVariables.json
cd .\AppServicePlan
New-AzSubscriptionDeployment -DeploymentName deployAppServicePlan -TemplateFile .\appService.bicep -Location 'eastus'
```

### References

* <https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans>
* <https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file>
