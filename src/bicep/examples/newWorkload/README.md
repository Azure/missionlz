# New Workload Example

This example adds a spoke network and peers it to the Hub Virtual Network and routes traffic to the Hub Firewall.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys a Spoke Network

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
1. Define some new values for required parameters described below.
1. The output from the Mission LZ deployment described below.

Required Parameters | Description
------------------- | -----------
subscriptionID | The subscription ID where you want to deploy the new spoke network
workloadName | A name (3 to 24 characters) for your workload

Deployment Output Name | Description
-----------------------| -----------
hubSubscriptionId | The subscription that contain the Hub Resource Group
hubResourceGroupName | The resource group that contains the Hub Virtual Network and deploy the virtual machines into
hubVirtualNetworkName | The network to peer the new workload network to
hubVirtualNetworkResourceId | The network to peer the new workload network to
logAnalyticsWorkspaceResourceId | The resource ID of the Log Analytics Workspace to send diagnostic logs to
firewallPrivateIPAddress | The private IP Address to the Firewall to route traffic to from the new workload network

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
  "hubSubscriptionId": {
    "type": "String",
    "value": "0987654-3210..."
  },
  ...
  "hubResourceGroupName": {
    "type": "String",
    "value": "mlz-dev-hub"
  },
  ...
  "hubVirtualNetworkName": {
    "type": "String",
    "value": "hub-vnet"
  },
  ...
  "hubVirtualNetworkId": {
    "type": "String",
    "value": "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/hub-vnet"
  },
  ...
  "logAnalyticsWorkspaceResourceId": {
    "type": "String",
    "value": "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/mlz-dev-laws"
  },
  ...
  "firewallPrivateIPAddress": {
    "type": "String",
    "value": "10.0.100.4"
  },
}
```

...and if you're on a BASH terminal, this command (take note to replace "myMlzDeployment" with your deployment name) will export the values as environment variables:

<!-- markdownlint-disable MD013 -->
```bash
export $(az deployment sub show --name "myMlzDeployment" --query "properties.outputs.{ args: [ join('', ['hubSubscriptionId=', hubSubscriptionId.value]), join('', ['hubResourceGroupName=', hubResourceGroupName.value]), join('', ['hubVirtualNetworkName=', hubVirtualNetworkName.value]), join('', ['hubVirtualNetworkResourceId=', hubVirtualNetworkResourceId.value]), join('', ['logAnalyticsWorkspaceResourceId=', logAnalyticsWorkspaceResourceId.value]), join('', ['firewallPrivateIPAddress=', firewallPrivateIPAddress.value]) ] }.args" --output tsv | xargs)
```
<!-- markdownlint-enable MD013 -->

## Deploy the example

Once you have the Mission LZ output values, you can pass those in as parameters to this deployment.

And deploy with `az deployment group create` from the Azure CLI:

```bash
cd examples/newWorkload

workloadSubscriptionId="12345678-1234..."
location="eastus"
workloadName="myNewWorkload"

az deployment sub create \
  --subscription $workloadSubscriptionId \
  --location $location \
  --name $workloadName \
  --template-file "./newWorkload.bicep" \
  --parameters \
  workloadName="$workloadName" \
  hubSubscriptionId="$hubSubscriptionId" \
  hubResourceGroupName="$hubResourceGroupName" \
  hubVirtualNetworkName="$hubVirtualNetworkName" \
  hubVirtualNetworkResourceId="$hubVirtualNetworkResourceId" \
  logAnalyticsWorkspaceResourceId="$logAnalyticsWorkspaceResourceId" \
  firewallPrivateIPAddress="$firewallPrivateIPAddress"
```

Or, completely experimentally, try the Portal:

### AzureCloud

[![Deploy To Azure](../../../../docs/images/deploytoazure.svg?sanitze=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fexamples%2FnewWorkload%2FnewWorkload.json)

### AzureUSGovernment

[![Deploy To Azure US Gov](../../../../docs/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fexamples%2FnewWorkload%2FnewWorkload.json)
