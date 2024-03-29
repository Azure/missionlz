# New Tier-3 Workload Example

This example adds a spoke network and peers it to the Hub Virtual Network and routes traffic to the Hub Firewall.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys a Spoke Network

The docs on Azure virtual networking:  <https://docs.microsoft.com/en-us/azure/virtual-network/>.  This example deploys an additional [spoke network which is peered to the hub network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview) of your MLZ instance. Additionally a few other items are deployed to enable connectivity in a secure manner:

* A [route table is created and all external traffic is routed through the MLZ hub network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
* While this example does not deploy a firewall, the target for all external traffic is the MLZ [Azure Firewall](https://docs.microsoft.com/en-us/azure/firewall/overview) hosted in the hub to ensure appropriate traffic filtering.

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)

### Deploy from the Azure Portal
<!-- markdownlint-disable MD013 -->
1. Deploy a new Tier-3 Workload Environment into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | ---------------- | ---------------- |
    |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2FuiDefinition.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2FuiDefinition.json) |
<!-- markdownlint-enable MD013 -->


