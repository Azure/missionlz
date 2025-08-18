# Tier-3 Add-On

This add-on deploys a spoke virtual network, peers it to the Hub virtual network, and routes traffic to the Hub firewall to support a workload. The tier-3 deployment is foundational to all add-on deployments. Each add-on calls the tier-3 module to consistently deploy a spoke VNET to support each workload.

## Pre-requisites

1. MLZ: ensure Mission Landing Zone is deployed
1. Encryption at Host: ensure the Encryption at Host feature is registered on the target subscription

### Deploy from the Azure Portal
<!-- markdownlint-disable MD013 -->
1. Deploy a new Tier-3 Workload Environment into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | ---------------- | ---------------- |
    |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2FuiDefinition.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Ftier3%2FuiDefinition.json) |
<!-- markdownlint-enable MD013 -->