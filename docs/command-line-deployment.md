# Command-Line Deployment

The steps in this article assume the following pre-requisites for command-line deployments:

* Follow the Mission LZ [Getting Started](./getting-started.md) steps.

## Step-by-step

1. Follow the [steps to open the `.devcontainer`](../.devcontainer/README.md) as recommended (or start a local BASH shell with the prerequisites installed)

   > `vscode@missionlz-dev:/workspaces/missionlz$` is the root working directory for the BASH shell in the `.devcontainer`

1. Deploy with Bicep (recommended)
   1. [Deploy](../src/bicep/README.md#Azure-CLI)
   1. [Customize deployment](../src/bicep/README.md#Deploying-to-Other-Clouds)

1. Or, deploy with Terraform
   1. [Apply](../src/terraform/README.md)
   1. [Customize deployment](../src/terraform/README.md#Deploying-to-Other-Clouds)

See the development container [README](../.devcontainer/README.md) for more details on building and running the container.

## Helpful Links

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>
