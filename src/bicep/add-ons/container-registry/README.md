# Azure Container Registry Example

This example deploys a premium Azure Container Registry suitable for hosting docker containers.  The registry will be deployed to the MLZ shared services resource group using default naming unless alternative values are provided at run time.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys an Azure Container Registry

The docs on Azure Container Registry: <https://docs.microsoft.com/en-us/azure/container-registry/>.  This sample shows how to deploy using Bicep and utilizes the shared file variable pattern to support the deployment.  By default, this template will deploy resources into standard default MLZ subscriptions and resource groups.  

The subscription and resource group can be changed by providing the resource group name (Param: targetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
2. The outputs from a deployment of mlz.bicep (./src/bicep/examples/deploymentVariables.json).  

See below for information on how to create the appropriate deployment variables file for use with this template.

### Template Parameters

Template Parameters Name | Description
-----------------------| -----------
contRegistryName | The name of the Container Registry.  If not specified, the name will default to the MLZ default naming pattern.  
targetResourceGroup | The name of the resource group where the Container Registry will be deployed.   If not specified, the resource group name will default to the shared services MLZ resource group name and subscription.

### Generate MLZ VAriable File (deploymentVariables.json)

For instructions on generating 'deploymentVariables.json' using both Azure PowerShell and Azure CLI, please see the [README at the root of the examples folder](../README.md).

Place the resulting 'deploymentVariables.json' file within the ./src/bicep/examples folder.

### Deploying an Container Registry

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure Container Registry post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\examples
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\containerRegistry
New-AzSubscriptionDeployment -DeploymentName deployContainerRegistry -TemplateFile .\container-registry.bicep -Location 'eastus'
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd examples
az deployment sub show -n contoso --query properties.outputs > ./deploymentVariables.json
cd containerRegistry
az deployment sub create -n deployContainerRegistry -f container-registry.bicep -l eastus
```

### References

* [Introduction to private Docker container registries in Azure](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans)
* [Bicep Shared Variable File Pattern](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file)
* [Azure Container Registry service tiers(Sku's)](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-skus)
