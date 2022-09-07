# Examples

In this directory are examples of how to add and extend functionality on-top of MissionLZ.

You [must first deploy MissionLZ](../README.md#Deployment), then you can deploy these examples. Since most examples re-use outputs from the base deployment of MLZ, we make use of the [shared variable file pattern](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file) to make it easier to share common variables across all of the examples.

## Example Explanations

Example | Description
------- | -----------
[appServicePlan](./app-service-plan) | Deploys an App Service Plan (AKA: Web Server Cluster) to support simple web accessible linux docker containers with optional dynamic auto scaling.
[Automation Account](./automation-account) | Deploys an Azure Automation account that can be used to execute runbooks.
[Container Registry](./container-registry/) | Deploys an Azure Container Registry for holding and deploying docker containers.
[Inherit Tags](./inherit-tags) | Adds or replaces a specified tag and value from the parent resource group when any resource is created or updated.
[KeyVault](./key-vault/) | Deploys a premium Azure Key Vault with RBAC enabled to support secret, key, and certificate management.
[Azure Sentinel](./sentinel) | A Terraform module that adds an Azure Sentinel solution to a Log Analytics Workspace. Sentinel can also be deployed via bicep and the base deployment of mlz.bicep by using the boolean param '-deploySentinel'.
[Zero Trust (TIC3.0) Workbook](./zero-trust-workbook) | Deploys an Azure Sentinel Zero Trust (TIC3.0) Workbook
[IaaS DNS Forwarders](./iaas-dns-forwarders) | Deploys DNS Forwarder Virtual Machines in the HUB, for proper resolution of Private Endpoint and internal domains accross all Virtual Networks 

## Shared Variable File Pattern (deploymentVariables.json)

The shared variable file pattern reduced the repeition of shared values in a library of bicep files.   This pattern is utilized for all examples modules though in almost all cases you can over-ride the shared variable value by supplying custom parameter values at run time.  

Shown below are two ways by which the shared variable file (deploymentVariables.json) can be generated.  The first utilizing PowerShell Core and the second using the Azure CLI.  A deployment of mlz.bicep is required, please make note of the name and region of the deployment.

### PowerShell Core

Shown below are step by step instructions for generated the needed deploymentVariables.json file utilizing PowerShell Core and the Auzre PowerShell module.  PowerShell and the Azure PowerShell module are open-source and avaliable for all major operating systems.

* [Get PowerShell Core](https://github.com/PowerShell/PowerShell/releases)
* [Get Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)
* [Getting Started with Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/get-started-azureps)

Execute the following commands from '.\src\bicep\examples\'

```PowerShell
Connect-AzAccount
(Get-AzSubscriptionDeployment -Name MLZDeploymentName).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
```

Replace "MLZDeploymentName" with your deployment name.  If you do not know your deployment name then log into the Azure management portal, browse to 'Subscriptions', select the subscription MLZ was deployed into, and then look at 'Deployments' to obtain the deployment name.

Place the 'deploymentVariables.json' file '.\src\bicep\examples\' folder.  

### Azure CLI

Shown below are step by step instructions for generated the needed deploymentVariables.json file utilizing the Azure CLI.  The Azure CLI is open-source and avaliable for all major operating systems.

* [Get Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Getting started with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli)

Execute the following commands from '.\src\bicep\examples\'

```Azure CLI
az login
az deployment sub show -n MLZDeploymentName --query properties.outputs > ./deploymentVariables.json
```

Replace "MLZDeploymentName" with your deployment name.  If you do not know your deployment name then log into the [Azure management portal](https://portal.azure.com), browse to 'Subscriptions', select the subscription MLZ was deployed into, and then look at 'Deployments' to obtain the deployment name.

Place the 'deploymentVariables.json' file '.\src\bicep\examples\' folder.  For a specific example of a Bicep template utilizing 'deploymentVariables.json', take a look at [.\appServicePlan\appService.bicep](.\appServicePlan\appService.bicep)
