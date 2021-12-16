# New Workload Example

This example adds a spoke network and peers it to the Hub Virtual Network and routes traffic to the Hub Firewall.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys a Spoke Network

The docs on Azure virtual networking:  <https://docs.microsoft.com/en-us/azure/virtual-network/>.  This example deploys an additional [spoke network which is peered to the hub network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview) of your MLZ instance. Additionally a few other items are deployed to enable connectivity in a secure manner:

* A [route table is created and all external traffic is routed through the MLZ hub network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
* While this example does not deploy a firewall, the target for all external traffic is the MLZ [Azure Firewall](https://docs.microsoft.com/en-us/azure/firewall/overview) hosted in the hub to ensure appropriate traffic filtering.

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
1. Define values for required parameters described below, and generate a `deploymentVariables.json` file from the deployment (see below).

Required Parameters | Description
------------------- | -----------
workloadName | A name (3 to 24 characters) for your workload
hubSubscriptionId | The subscription that contain the Hub Resource Group
hubResourceGroupName | The resource group that contains the Hub Virtual Network and deploy the virtual machines into
hubVirtualNetworkName | The network to peer the new workload network to
hubVirtualNetworkResourceId | The network to peer the new workload network to
logAnalyticsWorkspaceResourceId | The resource ID of the Log Analytics Workspace to send diagnostic logs to
firewallPrivateIPAddress | The private IP Address to the Firewall to route traffic to from the new workload network

### Generate MLZ Variable File (deploymentVariables.json)

For instructions on generating 'deploymentVariables.json' using both Azure PowerShell and Azure CLI, please see the [README at the root of the examples folder](..\README.md).

Place the resulting 'deploymentVariables.json' file within the ./src/bicep/examples folder.

## Deploy the example

Once you have the Mission LZ output values, you can pass those in as parameters to this deployment.

And deploy with `az deployment sub create` from the Azure CLI or `New-AzSubscriptionDeployment` from Azure PowerShell.

### Deploying the new workload

Connect to the appropriate Azure Environment and set appropriate context, see [getting started with Azure PowerShell or Azure CLI](..\README.md) for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure App Service Plan post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\examples
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\newWorkload
New-AzSubscriptionDeployment -DeploymentName deployNewWorkload -TemplateFile .\newWorkload.bicep -workloadName newWorkload -Location 'eastus'
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd examples
az deployment sub show -n contoso --query properties.outputs > ./deploymentVariables.json
cd newWorkload
az deployment sub create -n deployNewWorkload -f newWorkload.bicep -l eastus --parameters workloadName='newWorkload'
```
