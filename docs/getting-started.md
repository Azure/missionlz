# Getting Started

## Prerequisites

* Current version of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* An Azure Subscription where you have ['Owner' RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)

## Concepts

### Command Line Deployments

You can deploy Mission LZ from your workstation using the command line. Some other configurations are possible, but this is the simplest path.

We highly recommend deploying from the Development Container since it comes packaged with all the right versions of the dependencies you'll need.

### Use the Development Container for Command Line Deployments

If you are planning to deploy from your local workstation, we recommend using the VS Code development container specified in this repository.

* The container includes all the tools and pre-requisites, but you have to build and run the container.
* If you have Docker Desktop installed, then VS Code makes the rest of it easy.

See the [Development Container docs](../.devcontainer/README.md) for how to configure your workstation.

If you want to deploy from the command line on your workstation but do not want to use the development container take a look at the [`Dockerfile`](../.devcontainer/Dockerfile) and the [`devcontainer.json`](../.devcontainer/Dockerfile) file for examples on required tools and how configure your environment.

## Next steps

### 1. Deploy the Hub and Spoke

With the environment pre-requisites out of the way, deploy the hub and spoke using the [Command Line Deployment](./command-line-deployment.md) for step-by-step instructions:

* [Command Line Deployment](./command-line-deployment.md)

### 2. Deploy Your Workloads

Now that you have the core hub and spoke tiers deployed (Hub, Tier 0, Tier 1, Tier 2), the next step is to deploy one or more workload tiers. Misson LZ supports multiple workload tiers. See [Workload Deployment](./workload-deployment.md) for details and step-by-step instructions:

* [Workload Deployment](./workload-deployment.md)

### 3. Manage Your Deployment

Once you have a lab deployment of Mission Landing Zone established and have decided to move forward, you will want to start planning your production deployment. We recommend reviewing the following pages during your planning phase.

* [Using Management Groups with Mission Landing Zone](./management-groups.md)
