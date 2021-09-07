# Terraform Deployment

Mission LZ also deploys the Hub and Spoke network architecture using [Terraform](https://www.terraform.io/).

To get started with Terraform on Azure check out their useful tutorial: <https://learn.hashicorp.com/collections/terraform/azure-get-started/>

Once you're comfortable with Terraform, ensure you have the Prerequisites below and follow the instructions to deploy and clean-up Mission LZ.

## Prerequisistes

* Current version of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* The version of the [Terraform CLI](https://www.terraform.io/downloads.html) described in the [.devcontainer Dockerfile](../../../.devcontainer/Dockerfile)
* An Azure Subscription where you or an identity you manage has `Owner` [RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner)

## Login to Azure CLI

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

   > *(Optional)* If you needed to deploy into another cloud such as Azure Government, set the cloud name before logging in:

     ```BASH
     az cloud set -n AzureUSGovernment
     az login
     ```

1. (OPTIONAL) Deploying to a Cloud other than Azure Commercial? This requires updating the `azurerm` provider block `environment` and `metadata_host` values. Checkout the [Deploying to Other Clouds](#Deploying-to-Other-Clouds) documentation.

1. (OPTIONAL) Deploying with a Service Principal? This requires updating the `azurerm` provider block. Check out the [Deploying with a Service Principal](#Deploying-with-a-Service-Principal) documentation.

## Terraform init

Before provisioning any Azure resources with Terraform you must initialize a working directory.

Here's the docs on `terraform init`: <https://www.terraform.io/docs/cli/commands/init.html/>

1. Navigate to the directory in the repository that contains the MissionLZ Terraform module:

    ```bash
    cd src/terraform/mlz
    ```

1. Execute `terraform init`

    ```bash
    terraform init
    ```

## Terrafrom apply

After intializing the directory, use `terraform apply` to provision the resources described in `mlz/main.tf` and its referenced modules at `mlz/modules/*`.

Here's the docs on `terraform apply`: <https://www.terraform.io/docs/cli/commands/apply.html>

When you run `terraform apply`, by default, Terraform will inspect the state of your environment to determine what resource creation, modification, or deletion needs to occur as if you invoked a `terraform plan` and then prompt you for your approval before taking action.

Here's the docs on `terraform plan`: <https://www.terraform.io/docs/cli/commands/plan.html>

1. From the directory in which you executed `terraform init` execute `terraform apply`:

    ```bash
    terraform apply
    ```

1. When prompted for your approval to create, modify, or destroy resources, supply `yes`:

    ```plaintext
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

    Enter a value: yes
    ```

This command will deploy all of the resources that make up Mission LZ and could take up to 45 minutes.

## Terraform destroy

Once you're happy with the deployment output and want to modify Mission LZ or just want to tear it down to save on costs, you can use `terraform destroy`.

Here's the docs on `terraform destroy`: <https://www.terraform.io/docs/cli/commands/destroy.html>

1. From the directoy in which you executed `terraform init` and `terraform apply` execute `terraform destroy`:

    ```bash
    terraform destroy
    ```

This command will attempt to remove all the resources that were deployed by `terraform apply` and could take up to 45 minutes.

## Deploying with a Service Principal

This is not required, in fact, the current Terraform modules are written as if you're executing them as a user.

But, if you're using a Service Principal to deploy Azure resources with Terraform check out this doc: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret/>

Using a Service Principal will require updating the resource providers for `mlz/main.tf`, also described in that doc: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform/>:

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

## Terraform Providers

The development container definition downloads the required Terraform plugin providers during the container build so that the container can be transported to an air-gapped network for use. The container also sets the `TF_PLUGIN_CACHE_DIR` environment variable, which Terraform uses as the search location for locally installed providers. If you are not using the container to deploy or if the `TF_PLUGIN_CACHE_DIR` environment variable is not set, Terraform will automatically attempt to download the provider from the internet when you execute the `terraform init` command.

See the development container [README](/.devcontainer/README.md) for more details on building and running the container.

## Terraform Backends

The default templates write a state file directly to disk locally to where you are executing terraform from.  If you wish to change the output directory you can set the path directly in the terraform backend block located in the main.tf file via the path variable in the backend configuration block.

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

## Deploying to Other Clouds

The `azurerm` Terraform provider provides a mechanism for changing the Azure cloud in which to deploy Terraform modules.

When specifying your provider, pass in the correct value for `environment` and `metadata_host` for the cloud you're targeting:

```terraform
provider "azurerm" {
  features {}
  
  environment     = var.tf_environment # e.g. 'public' or 'usgovernment'
  metadata_host   = var.mlz_metadatahost # e.g. 'management.azure.com' or 'management.usgovcloudapi.net'
}
```

For the supported `environment` values, see this doc: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#environment/>

For the supported `metadata_host` values, see this doc: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#metadata_host/>

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>
