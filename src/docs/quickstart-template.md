# Quick Start Template  (Experimental Options)

The following buttons can be used to deploy Mission LZ but read the caveats below before continuing:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbuild%2Farm_quickstart%2FmainTemplate.json)
[![Deploy to Azure](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbuild%2Farm_quickstart%2FmainTemplate.json)

## Requirements

1. This deployment method for MLZ requires the use of a service principal with a contributor role.  It will not work otherwise and will fail when trying to deploy resources.

2. To create a service principal for the target subscription for this deployment method perform the following  (Reference: [Create an Azure Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)):

    > Login to Azure

    ```BASH
    az login
    ```

   > Create the Service Principal and assign the contributor role.  Record the password, and the appId.

     ```BASH
     az ad sp create-for-rbac --name <NameOfServicePrincipal>
     az role assignment create --assignee <appId> --role Contributor
     ```

## Considerations

### Scope

This method of executing MLZ will only deploy to a single subscription and is not as highly configurable as using the other available toolsets to configure your landing zone.k

### Errors

The deployment script option from ARM Templates is a relatively new option ([Use Deployment scripts in ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template)), we are using the capability with a remote installation of Terraform to roll out MLZ.  Sometimes this can lead to mysterious errors.  When these errors occur, before attempting to re-run the deployment check your subscription to see if resources have been created. If these resources have been created, it is unlikely that you need to re-run the deployment.   However if they have not, simply try to run the quickstart deployment again, often times this will self resolve and deploy the landing zone.

  > Example Benign Error:

  ```JSON
    {"code":"DeploymentFailed","message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.","details":[{"code":"DeploymentScriptOperationFailed","message":"Object reference not set to an instance of an object."}]}
  ```
