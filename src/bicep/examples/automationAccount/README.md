# Azure Automation Account Example

This example deploys an MLZ compatible Azure Automation account, with diagnostic logs pointed to the MLZ Log Analytics Workspace (LAWS) instance.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys an Azure Automation Account

The docs on Azure Automation (Automation Accounts): <https://docs.microsoft.com/en-us/azure/automation/>.  

## Prerequisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
2. The outputs from a deployment of mlz.bicep (./src/bicep/examples/deploymentVariables.json).  
3. PowerShell Runbook for your MLZ deployment

See below for information on how to create the appropriate deployment variables file for use with this template.

### Template Parameters

Template Parameters Name | Description
-----------------------| -----------
automationAcctName | The name of automation account.  If not specified, the name will default to the MLZ default naming pattern.  
targetResourceGroup | The name of the resource group where the automation account will be deployed.   If not specified, the resource group name will default to the shared services MLZ resource group name and subscription.

### Generate MLZ Variable File (deploymentVariables.json)

For instructions on generating 'deploymentVariables.json' using both Azure PowerShell and Azure CLI, please see the [README at the root of the examples folder](../README.md).

Place the resulting 'deploymentVariables.json' file within the ./src/bicep/examples folder.

### Deploying Azure Automation

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an automation account to the operations resource group.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\examples
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\automationAccount
New-AzSubscriptionDeployment -DeploymentName deployAzureAUtomationt -TemplateFile .\automationAccount.bicep -Location 'eastus'
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd examples
az deployment sub show -n contoso --query properties.outputs > ./deploymentVariables.json
cd automationAccount
az deployment sub create -n deployAzureAutomation -f automationAccount.bicep -l eastus
```

### References

* [Azure Automation Documentation](https://docs.microsoft.com/en-us/azure/automation/)
* [Azure Automation Examples](https://github.com/azureautomation/)
