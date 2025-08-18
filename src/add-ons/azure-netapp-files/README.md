# Azure NetApp Files Add-On

This add-on deploys Azure NetApp Files into a tier-3 spoke virtual network.

## Pre-requisites

1. Azure subscription
1. Owner RBAC on the Azure subscription
1. Deploy Mission Landing Zone
1. [Register the Encryption at Host feature](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal?tabs=azure-powershell#prerequisites)
1. [Register the Azure NetApp Files resource provider](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-register)

### Deploy from the Azure Portal
<!-- markdownlint-disable MD013 -->
1. Deploy the Azure NetApp Files Add-On into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | ---------------- | ---------------- |
    |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fazure-netapp-files%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fazure-netapp-files%2FuiDefinition.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fazure-netapp-files%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2Fazure-netapp-files%2FuiDefinition.json) |
<!-- markdownlint-enable MD013 -->