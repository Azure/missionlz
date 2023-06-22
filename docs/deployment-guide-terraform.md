# Mission LZ Deployment Guide for Terraform

## Table of Contents

- [Prerequisites](#prerequisites)  
- [Planning](#planning)  
- [Deployment](#deployment)  
- [Cleanup](#cleanup)  
- [Development Setup](#development-setup)  
- [See Also](#see-also)  

This guide describes how to deploy Mission Landing Zone using the [Terraform](https://www.terraform.io/) template at [src/terraform/mlz](../src/terraform/mlz).

To get started with Terraform on Azure check out their [tutorial](https://learn.hashicorp.com/collections/terraform/azure-get-started/).

Below is an example of a Terraform deployment that uses all the defaults.

```bash
cd src/terraform/mlz
terraform init
terraform apply # supply some parameters, approve, copy the output values
cd src/terraform/tier3
terraform init
terraform apply # supply some parameters, approve
```

## Prerequisites

- Current version of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- The version of the [Terraform CLI](https://www.terraform.io/downloads.html) described in the [.devcontainer Dockerfile](../.devcontainer/Dockerfile)
- An Azure Subscription(s) where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)

<!-- markdownlint-disable MD013 -->
> NOTE: Azure Cloud Shell is often our preferred place to deploy from because the AZ CLI and Terraform are already installed. However, sometimes Cloud Shell has different versions of the dependencies from what we have tested and verified, and sometimes there have been bugs in the Terraform Azure RM provider or the AZ CLI that only appear in Cloud Shell. If you are deploying from Azure Cloud Shell and see something unexpected, try the [development container](../.devcontainer) or deploy from your machine using locally installed AZ CLI and Terraform. We welcome all feedback and [contributions](../CONTRIBUTING.md), so if you see something that doesn't make sense, please [create an issue](https://github.com/Azure/missionlz/issues/new/choose) or open a [discussion thread](https://github.com/Azure/missionlz/discussions).
<!-- markdownlint-enable MD013 -->

## Planning

### Decide on a Resource Prefix

Resource Groups and resource names are derived from the `resourcePrefix` parameter, which defaults to 'mlz'. Pick a unqiue resource prefix that is 3-10 alphanumeric characters in length without whitespaces.

### One Subscription or Multiple

MLZ can deploy to a single subscription or multiple subscriptions. A test and evaluation deployment may deploy everything to a single subscription, and a production deployment may place each tier into its own subscription.

The optional parameters related to subscriptions are below. At least one subscription is required.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`hub_subid` | '' | Subscription ID for the Hub deployment
`tier0_subid` | value of hub_subid | Subscription ID for tier 0
`tier1_subid` | value of hub_subid | Subscription ID for tier 1
`tier2_subid` | value of hub_subid | Subscription ID for tier 2

### Networking

The following parameters affect networking addresses. To override the defaults edit the variables file at [`src/terraform/mlz/variables.tf`](../src/terraform/mlz/variables.tf).

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`hub_vnet_address_space` | `["10.0.100.0/24"]` | The address space to be used for the virtual network
`hub_client_address_space` | `"10.0.100.0/26"` | The address space to be used for the Firewall virtual network
`hub_management_address_space` | `"10.0.100.64/26"` | The address space to be used for the Firewall virtual network subnet used for management traffic
`tier0_vnet_address_space` | `["10.0.110.0/26"]` | VNet prefix for tier 0
`tier0_subnets.address_prefixes` | `["10.0.110.0/27"]` | Subnet prefix for tier 0
`tier1_vnet_address_space` | `["10.0.115.0/26"]` | VNet prefix for tier 1
`tier1_subnets.address_prefixes` | `["10.0.115.0/27"]` | Subnet prefix for tier 1
`tier2_vnet_address_space` | `["10.0.120.0/26"]` | VNet prefix for tier 2
`tier2_subnets.address_prefixes` | `["10.0.120.0/27"]` | Subnet prefix for tier 2

### Optional Features

### Assigning Azure Policy

This template supports assigning NIST 800-53 policies. See the [policies documentation](./policies.md) for more information.

You can enable this by providing a `true` value to the `create_policy_assignment` variable.

At `apply` time:

```plaintext
terraform apply -var="create_policy_assignment=true"
```

Or, by updating `src/terraform/mlz/variables.tf`:

```terraform
variable "create_policy_assignment" {
  description = "Assign Policy to deployed resources?"
  type        = bool
  default     = true
}
```

### Planning for Workloads

MLZ allows for deploying one or many workloads that are peered to the hub network. Each workload can be in its own subscription or multiple workloads may be combined into a single subscription.

A separate Terraform template is provided for deploying an empty workload `src/terraform/tier3`. You can use this template as a starting point to create and customize specific workload deployments.

The following parameters affect tier3 networking. To override the defaults edit the variables file at [`src/terraform/tier3/variables.tf`](../src/terraform/tier3/variables.tf).

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`tier3_vnet_address_space` | `["10.0.125.0/26"]` | Address space prefix for tier 3
`tier3_subnets.address_prefixes` | `["10.0.125.0/27"]` | Subnet prefix for tier 3

## Deployment

### Login to Azure CLI

Log in using the Azure CLI.

```BASH
az login
```

If you are deploying to another cloud, such as Azure Government, set the cloud name before logging in.

  ```BASH
  az cloud set -n AzureUSGovernment
  az login
  ```

### Terraform init

Before provisioning any Azure resources with Terraform you must [initialize a working directory](https://www.terraform.io/docs/cli/commands/init.html/).

1. Navigate to the directory in the repository that contains the MissionLZ Terraform module:

    ```bash
    cd src/terraform/mlz
    ```

1. Execute `terraform init`

    ```bash
    terraform init
    ```

### Terraform apply

After intializing the directory, use [`terraform apply`](https://www.terraform.io/docs/cli/commands/apply.html) to provision the resources described in `mlz/main.tf` and its referenced modules at `mlz/modules/*`.

When you run `terraform apply`, by default, Terraform will inspect the state of your environment to determine what resource creation, modification, or deletion needs to occur as if you invoked a [`terraform plan`](https://www.terraform.io/docs/cli/commands/plan.html) and then prompt you for your approval before taking action.

1. From the directory in which you executed `terraform init` execute `terraform apply`:

    ```bash
    terraform apply
    ```

1. You'll be prompted for a subscription ID. Supply the subscription ID you want to use for the Hub network:

    ```plaintext
    > terraform apply
    var.hub_subid
    Subscription ID for the deployment

    Enter a value: 
    ```

1. Terraform will then inspect the state of your Azure environment and compare it with what is described in the Mission LZ Terraform module. Eventually, you'll be prompted for your approval to create, modify, or destroy resources. Supply `yes`:

    ```plaintext
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

    Enter a value: yes
    ```

1. The deployment will begin. These commands will deploy all of the resources that make up Mission LZ. Deployment could take up to 45 minutes.

### Apply Complete

When it's complete, you'll see some output values that will be necessary if you want to stand up new spoke, or Tier 3, networks:

```plaintext
Apply complete! Resources: 99 added, 0 changed, 0 destroyed.

Outputs:

firewall_private_ip = "10.0.100.4"
hub_rgname = "hub-rg"
hub_subid = "{the Hub subscription ID}"
hub_vnetname = "hub-vnet"
laws_name = "{the name of the Log Analytics Workspace}"
laws_rgname = "operations-rg"
tier1_subid = "{the Tier 1 subscription ID}"
```

### Deploy New Workloads

Once you've deployed Mission LZ, you can use the Tier 3 module to deploy and peer new Spoke Networks and workloads to the Hub and Firewall.

1. Navigate to the directory in the repository that contains the MissionLZ Tier 3 Terraform module:

    ```bash
    cd src/terraform/tier3
    ```

1. Execute `terraform init`

    ```bash
    terraform init
    ```

1. Execute `terraform apply`

    ```bash
    terraform apply
    ```

1. You'll be prompted for environment values for resources deployed by the core Mission LZ deployment for: 1) the Hub Firewall, 2) the Log Analytics Workspace resources and 3) the desired subscription ID for the new spoke network/Tier 3:

    ```plaintext
    > terraform apply
    var.firewall_private_ip
      Firewall IP to bind network to

      Enter a value: 10.0.100.4

    var.hub_rgname
      Resource Group for the Hub deployment

      Enter a value: hub-rg

    var.hub_subid
      Subscription ID for the Hub deployment

      Enter a value: {the Hub subscription ID}

    var.hub_vnetname
      Virtual Network Name for the Hub deployment

      Enter a value: hub-vnet

    var.laws_name
      Log Analytics Workspace Name for the deployment

      Enter a value: {the name of the Log Analytics Workspace}

    var.laws_rgname
      The resource group that Log Analytics Workspace was deployed to

      Enter a value: operations-rg

    var.tier1_subid
      Subscription ID for the Tier 1 deployment

      Enter a value: {the Tier 1 subscription ID}

    var.tier3_subid
      Subscription ID for this Tier 3 deployment

      Enter a value: {the Tier 3 subscription ID}
    ```

    You get these values when `terraform apply` is complete for the core Mission LZ deployment. See the [Apply Complete](#apply-complete) section for what these values look like. You can also source the values after a successful core Mission LZ deployment by inspecting the `outputs` object in the Terraform state file. By default that state file is at `src/terraform/mlz/terraform.tfstate`.

1. Terraform will then inspect the state of your Azure environment and compare it with what is described in the Tier 3 Terraform module. Eventually, you'll be prompted for your approval to create, modify, or destroy resources. Supply `yes`:

    ```plaintext
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

    Enter a value: yes
    ```

### Deploy with a Service Principal

If you are using a Service Principal to deploy Azure resources with Terraform, [some additional configuration is required](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret/).

Using a Service Principal will require [updating the resource providers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform/) for `mlz/main.tf`.

```terraform
variable "client_secret" {
}

terraform {
  required_providers {
    azurerm = {
      ...
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "00000000-0000-0000-0000-000000000000"
  client_id       = "00000000-0000-0000-0000-000000000000"
  client_secret   = var.client_secret
  tenant_id       = "00000000-0000-0000-0000-000000000000"
}
```

### Deploy to Other Clouds

The `azurerm` Terraform provider provides a mechanism for changing the Azure cloud in which to deploy Terraform modules.

If you want to deploy to another cloud, pass in the correct value for `environment`,  `metadata_host`, and `location` for the cloud you're targeting to the relevant module's variables file [mlz/variables.tf](../src/terraform/mlz/variables.tf) or [tier3/variables.tf](../src/terraform/tier3/variables.tf):

```terraform
variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  default     = "usgovernment"
}

variable "metadata_host" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
  type        = string
  default     = "management.usgovcloudapi.net"
}

variable "location" {
  description = "The Azure region for most Mission LZ resources"
  type        = string
  default     = "usgovvirginia"
}
```

```terraform
provider "azurerm" {
  features {}
  
  environment     = var.environment # e.g. 'public' or 'usgovernment'
  metadata_host   = var.metadata_host # e.g. 'management.azure.com' or 'management.usgovcloudapi.net'
}
```

For the supported `environment` values, see this doc: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#environment/>

For the supported `metadata_host` values, see this doc: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#metadata_host/>

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>

### Terraform Providers

The [development container definition](../.devcontainer/Dockerfile) downloads the required Terraform plugin providers during the container build so that the container can be transported to an air-gapped network.

The container sets the `TF_PLUGIN_CACHE_DIR` environment variable, which Terraform uses as the search location for locally installed providers.

If you are not using the [development container](../.devcontainer) to deploy or if the `TF_PLUGIN_CACHE_DIR` environment variable is not set, Terraform will automatically attempt to download the provider from the internet when you execute the `terraform init` command.

See the development container [README](/.devcontainer/README.md) for more details on building and running the container.

### Terraform Backends

The default templates write a state file directly to disk locally to where you are executing terraform from. If you wish to change the output directory you can set the path directly in the terraform backend block located in the main.tf file via the path variable in the backend configuration block.

```terraform
terraform {
  backend "local" {
    path = "relative/path/to/terraform.tfstate"
  }

  required_version = ">= 1.0.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.71.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
  }
}
```

To find more information about setting the backend see [Local Backend](https://www.terraform.io/docs/language/settings/backends/local.html),  if you wish to AzureRM backend please see [AzureRM Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)

## Cleanup

If you want to delete an MLZ deployment you can use [`terraform destroy`](https://www.terraform.io/docs/cli/commands/destroy.html). If you have deployed more than one Terraform template, e.g., if you have deployed `mlz/main.tf` and then `tier3/main.tf`, run the `terraform destroy` commands in the reverse order that you applied them. For example:

```bash
# Deploy core MLZ resources
cd src/terraform/mlz
terraform apply

# Deploy a tier 3 spoke network
cd ../tier3
terraform apply

# Reverse order to destroy:
# Destroy the tier 3 spoke network (still in the src/terraform/tier3 folder)
terraform destroy

# Destroy core MLZ resources
cd ../mlz
terraform destroy
```

Running `terraform destroy` for `mlz/main.tf` looks like this:

1. From the directory in which you executed `terraform init` and `terraform apply` execute `terraform destroy`:

    ```bash
    terraform destroy
    ```

1. You'll be prompted for a subscription ID. Supply the subscription ID you want to used previously:

    ```plaintext
    > terraform destroy
    var.hub_subid
    Subscription ID for the deployment

    Enter a value: 
    ```

1. Terraform will then inspect the state of your Azure environment and compare it with what is described in Terraform state. Eventually, you'll be prompted for your approval to destroy resources. Supply `yes`:

    ```plaintext
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

    Enter a value: yes
    ```

This command will attempt to remove all the resources that were created by `terraform apply` and could take up to 45 minutes.

## Development Setup

For development of the Mission Landing Zone Terraform templates we recommend using the development container because it has the necessary dependencies already installed. To get started follow the [guidance for using the development container](../.devcontainer/README.md).

## See Also

[Terraform](https://www.terraform.io/)

[Terraform Tutorial](https://learn.hashicorp.com/collections/terraform/azure-get-started/)

[Developing in a container](https://code.visualstudio.com/docs/remote/containers) using Visual Studio Code
