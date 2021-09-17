# Workload Deployment (Tier 3)

Mission LZ supports deploying multiple workload tiers that are connected to the hub. We call these tier 3s, or T3s, for convenience. Each tier 3 is intended to support a single workload or single team that needs isolation from the other teams and network connectivity via the hub.

You'll have to have completed the deployment of Mission LZ to peer this new workload to the Hub network and Firewall. See [Command-Line Deployment](./command-line-deployment.md) for steps on how to do deploy those things.

## Step-by-step

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

1. Deploy with Bicep (recommended)
   1. [Deploy](../src/bicep/examples/newWorkload/README.md)
   1. [Customize deployment](../src/bicep/README.md#Deploying-to-Other-Clouds)

1. Or, deploy with Terraform
   1. [Apply](../src/terraform/README.md#Deploying-new-Spoke-Networks)
   1. [Customize deployment](../src/terraform/README.md#Deploying-to-Other-Clouds)
