# Overview

This example adds an aks module into an existing subnet.

## Pre-requisites

1. A virtual network and subnet is deployed.
1. Define values for Required Parameters described below

Required Parameters | Description
------------------- | -----------
vnetName | Existing Vnet Name
subnetName | Existing Subnet Name
vnetRgName | Resource group that the Vnet belongs to
dnsServiceIp | An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.
serviceCidr | A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.
dockerBridgeCidr | A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.

## Deploy the example

Once you have the Mission LZ output values, you can pass those in as parameters to this deployment.

And deploy with `az deployment sub create` from the Azure CLI or `New-AzSubscriptionDeployment` from Azure PowerShell.

### Deploying aks Module into Tier 3 Subnet

Connect to the appropriate Azure Environment and set appropriate context, see [getting started with Azure PowerShell or Azure CLI](..\examples\README.md) for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure App Service Plan post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\add-ons
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\tier3
New-AzSubscriptionDeployment -DeploymentName deployTier3 -TemplateFile .\tier3.bicep -resourcePrefix myTier3 -Location 'eastus'
cd ..\aks
(Get-AzSubscriptionDeployment -Name deployTier3).outputs | ConvertTo-Json | Out-File -FilePath .\vnetDeploymentVariables.json
New-AzSubscriptionDeployment -DeploymentName deployAKS -TemplateFile .\aks.bicep -resourcePrefix myAKS -dnsServiceIp '' -serviceCidr='' -dockerBridgeCidr='' -Location 'eastus' 
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd add-ons
az deployment sub show -n contoso --query properties.outputs > ./deploymentVariables.json
cd tier3
az deployment sub create -n deployTier3 -f tier3.bicep -l eastus --parameters resourcePrefix='myTier3'
cd ../aks
az deployment sub show -n deployTier3 --query properties.outputs > ./vnetDeploymentVariables.json
az deployment sub create -n deployAKS -f aks.bicep -l eastus --parameters resourcePrefix='myAKS' dnsServiceIp='' serviceCidr='' dockerBridgeCidr=''
```

### Note
Values provided above for the address space uses up all the VNET and works for 1 aks node count. 