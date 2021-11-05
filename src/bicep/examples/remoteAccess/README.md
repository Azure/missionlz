# Remote Access Example

This example adds a virtual machine to the Hub resource group to serve as a jumpbox into the network using Azure Bastion Host as the remote desktop solution without exposing the virtual machine via a Public IP address.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys Azure Bastion Host

The docs on Azure Bastion: <https://docs.microsoft.com/en-us/azure/bastion/bastion-overview>

Some particulars about Bastion:

- Azure Bastion Host requires a subnet of /27 or larger
- the subnet must be titled `AzureBastionSubnet`
- Azure Bastion Hosts require a public IP address

### Deploys Virtual Machine

This example deploys two virtual machines into a new subnet in the existing Hub virtual network to serve as jumpboxes.

The docs on Virtual Machines: <https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?tabs=json>

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
1. The output from that deployment described below:

Deployment Output Name | Description
-----------------------| -----------
hubResourceGroupName | The resource group that contains the Hub Virtual Network and deploy the virtual machines into
hubVirtualNetworkName | The resource to deploy a subnet configured for Bastion Host
hubSubnetResourceId | The resource ID of the subnet in the Hub Virtual Network for hosting virtual machines
hubNetworkSecurityGroupResourceId | The resource ID of the Network Security Group in the Hub Virtual Network that hosts rules for Hub Subnet traffic

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
  ...
  "hub": {
    "type": "Object",
    "value": {
      ...
      "resourceGroupName": "mlz-dev-hub",
      ...
      "networkSecurityGroupResourceId": "/subscriptions/.../providers/Microsoft.Network/networkSecurityGroups/hub-nsg
      ...
      "subnetResourceId": "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/hub-vnet/subnets/hub-subnet",
      ...
      "virtualNetworkName": "hub-vnet"
    }
  },
  "logAnalyticsWorkspaceResourceId": {
    "type": "String",
    "value": "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/mlz-dev-laws"
  },
  ...
}
```

## Deploy the example

Once you have the Mission LZ output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment group create` command in the Azure CLI:

```bash
cd examples/remoteAccess

hubResourceGroupName="mlz-dev-hub"
hubVirtualNetworkName="hub-vnet"
hubSubnetResourceId="/subscriptions/.../providers/Microsoft.Network/virtualNetworks/hub-vnet/subnets/hub-subnet"
hubNetworkSecurityGroupResourceId="/subscriptions/.../providers/Microsoft.Network/networkSecurityGroups/hub-nsg"
logAnalyticsWorkspaceResourceId="/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/mlz-dev-laws"

my_password=$(openssl rand -base64 14) # generate a random 14 character password

az deployment group create \
  --name "RemoteAccessExample" \
  --resource-group $hubResourceGroupName \
  --template-file "./main.bicep" \
  --parameters \
  hubVirtualNetworkName="$hubVirtualNetworkName" \
  hubSubnetResourceId="$hubSubnetResourceId" \
  hubNetworkSecurityGroupResourceId="$hubNetworkSecurityGroupResourceId" \
  logAnalyticsWorkspaceResourceId="$logAnalyticsWorkspaceResourceId" \
  linuxVmAdminPasswordOrKey="$my_password" \
  windowsVmAdminPassword="$my_password"
```

Or, completely experimentally, try the Portal:

### AzureCloud

[![Deploy To Azure](../../../../docs/images/deploytoazure.svg?sanitze=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fexamples%2FremoteAccess%2Fmain.json)

### AzureUSGovernment

[![Deploy To Azure US Gov](../../../../docs/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fexamples%2FremoteAccess%2Fmain.json)
