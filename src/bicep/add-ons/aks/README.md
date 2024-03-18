# Overview

The example below deploys an AKS cluster into [Tier 3 Spoke Network](../../add-ons/tier3/README.md) but could be deployed into any existing Spoke Network.

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

1. Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

    Optional Parameters | Default | Description
    ------------------- | ----------- | -----------
    resourcePrefix | mlz | A prefix, 3 to 10 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".
    resourceSuffix | mlz | A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".
    aksAgentCount| 1 | Number of agents (VMs) to host docker containers. Allowed values must be in the range of 0 to 1000 (inclusive) for user pools and in the range of 1 to 1000 (inclusive) for system pools. The default value is 1. Please note that increasing this value will require more available IPs in the subnet.
    aksDnsPrefix | mlzaks | Optional DNS prefix to use with hosted Kubernetes API server FQDN, 1 to 54 characters in length, can contain alphanumerics and hyphens, but should start and end with alphanumeric. This cannot be updated once the Managed Cluster has been created. It defaults to "mlzaks".
    kubernetesVersion | 1.21.9 | AKS cluster kubernetes version.
    vmSize | Standard_D2_v2 | VM size availability varies by region. If a node contains insufficient compute resources (memory, cpu, etc) pods might fail to run correctly. For more details on restricted VM sizes, see: [Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Deploy the example

Once you have the Mission LZ output values, you can pass those in as parameters to this deployment.

And deploy with `az deployment sub create` from the Azure CLI or `New-AzSubscriptionDeployment` from Azure PowerShell.

### Deploying AKS cluster into Tier 3 Subnet

Connect to the appropriate Azure Environment and set appropriate context, see [getting started with Azure PowerShell or Azure CLI](../../examples/README.md) for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure App Service Plan post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\add-ons
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\tier3
New-AzSubscriptionDeployment -DeploymentName deployTier3 -TemplateFile .\tier3.bicep -resourcePrefix myTier3 -subnetAddressPrefix '10.0.125.0/26' -Location 'eastus'
cd ..\aks
(Get-AzSubscriptionDeployment -Name deployTier3).outputs | ConvertTo-Json | Out-File -FilePath .\vnetDeploymentVariables.json
New-AzSubscriptionDeployment -DeploymentName deployAKS -TemplateFile .\aks.bicep -resourcePrefix myAKS -dnsServiceIp '10.1.0.10' -serviceCidr '10.1.0.0/16' -dockerBridgeCidr '170.10.0.1/16' -Location 'eastus' 
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd add-ons
az deployment sub show -n contoso --query properties.outputs > ./deploymentVariables.json
cd tier3
az deployment sub create -n deployTier3 -f tier3.bicep -l eastus --parameters resourcePrefix='myTier3' subnetAddressPrefix='10.0.125.0/26'
cd ../../examples/aks
az deployment sub show -n deployTier3 --query properties.outputs > ./vnetDeploymentVariables.json
az deployment sub create -n deployAKS -f aks.bicep -l eastus --parameters resourcePrefix='myAKS' dnsServiceIp='10.1.0.10' serviceCidr='10.1.0.0/16' dockerBridgeCidr='170.10.0.1/16'
```
