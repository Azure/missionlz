# Command-Line Deployment

## Step-by-step

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

1. [Quickstart](#Quickstart)
1. [Setup Mission LZ Resources](#Setup-Mission-LZ-Resources)
1. [Set Terraform Configuration Variables](#Set-Terraform-Configuration-Variables)
1. [Deploy Terraform Configuration](#Deploy-Terraform-Configuration)
1. [Clean up Mission LZ Resources](#Clean-up-Mission-LZ-Resources)

### Quickstart

#### Quickstart Deploy

Interested in just getting started and seeing what this does? Login to Azure CLI and try this command to deploy Mission LZ with some default configuration:

```bash
src/scripts/deploy.sh -s {your_subscription_id}
```

> **NOTE** This implies some software pre-requisites. We highly [recommend using the .devcontainer](https://github.com/Azure/missionlz/blob/main/src/docs/getting-started.md#use-the-development-container-for-command-line-deployments) described in this repository to make thing easier. However, deploying Mission LZ via BASH shell is possible with these minimum requirements:
>
> - An Azure Subscription where you have ['Owner' RBAC permissions](<https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/>)
> - The current version of Azure CLI (try `az cli -v` or see <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli/>)
> - Terraform CLI version > v0.13.4 (try `terraform -v` or see <https://learn.hashicorp.com/tutorials/terraform/install-cli/>)

The `deploy.sh` command deploys all of the MLZ and Terraform resources, and by default, into a single subscription in Azure Commercial EastUS with a timestamped name.

If you needed to deploy into another cloud, say Azure Government, you would [override the default region](https://azure.microsoft.com/en-us/global-infrastructure/geographies/#overview) and [default azurerm terraform environment](https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment) like:

```bash
az cloud set -n AzureUSGovernment
az login
src/scripts/deploy.sh -s {your_subscription_id} \
  --location usgovvirginia \
  --tf-environment usgovernment
```

For a complete list of arguments see [Quickstart Arguments](#Quickstart-Arguments).

#### Quickstart Clean

Once the deployment is complete, you'll be presented with a command that will clean up all of the resources that were deployed:

```plaintext
INFO: Complete!
INFO: All finished? Want to clean up?
INFO: Try this command:
INFO: src/scripts/clean.sh -z mymlzenv
```

Which you can then execute like:

```bash
src/scripts/clean.sh -z mymlzenv
```

The `clean.sh` command will call Terraform destroy for all the resources Terraform created and delete the MLZ resources and service principal.

#### Quickstart Arguments

If you don't wish to use those defaults, you can customize this command to target multiple subscriptions, different regions, and using different Terraform environments and azurerm configurations with the full set of arguments:

```plaintext
deploy.sh: create all the configuration and deploy Terraform resources with minimal input
            argument    description
   --subscription-id -s Subscription ID for MissionLZ resources
          --location -l [OPTIONAL] The location that you're deploying to (defaults to 'eastus')
    --tf-environment -e [OPTIONAL] Terraform azurerm environment (defaults to 'public') see: https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment
      --mlz-env-name -z [OPTIONAL] Unique name for MLZ environment (defaults to 'mlz' + UNIX timestamp)
        --hub-sub-id -u [OPTIONAL] subscription ID for the hub network and resources (defaults to the value provided for -s --subscription-id)
      --tier0-sub-id -0 [OPTIONAL] subscription ID for tier 0 network and resources (defaults to the value provided for -s --subscription-id)
      --tier1-sub-id -1 [OPTIONAL] subscription ID for tier 1 network and resources (defaults to the value provided for -s --subscription-id)
      --tier2-sub-id -2 [OPTIONAL] subscription ID for tier 2 network and resources (defaults to the value provided for -s --subscription-id)
        --no-bastion    [OPTIONAL] when present, do not create a Bastion Host and Jumpbox VM
              --help -h Print this message
```

For example, if I wanted to deploy into four subscriptions (one for each network) and provide my own name for created resources, I could do so like:

```bash
src/scripts/deploy.sh -s {my_mlz_configuration_subscription_id} \
  -u {my_hub_network_subscription_id} \
  -0 {my_identity_network_subscription_id} \
  -1 {my_operations_network_subscription_id} \
  -2 {my_shared_services_network_subscription_id} \
  -z {my_mlz_environment_name}
```

Need further customization? The rest of this documentation covers in detail how to customize this deployment to your needs.

### Setup Mission LZ Resources

Deployment of MLZ happens through use of a single Service Principal whose credentials are stored in a central "config" Key Vault.

MLZ uses this Service Principal and its credentials from the Key Vault to deploy the resources described in Terraform at `src/core` and stores Terraform state for each component into separate storage accounts.

1. First, create the MLZ Configuration file `mlz.config` file using the `mlz.config.sample` as a template.

    The information in the `mlz.config` file, will be used by `create_mlz_configuration_resources.sh` to create and populate a `config.vars` file for each tier and saved inside the deployment folder for each tier (example: \src\core\tier-0\config.vars).

    For example:

    ```plaintext
    mlz_env_name="{MLZ_ENV_NAME}"
    mlz_config_location="{MLZ_CONFIG_LOCATION}"
    ```

    Would become:

    ```plaintext
    mlz_env_name="dev"
    mlz_config_location="eastus"
    ```

1. Then, run `create_mlz_configuration_resources.sh` at [src/scripts/config/create_mlz_configuration_resources.sh](/src/scripts/config/create_mlz_configuration_resources.sh) to create:

    - A config Resource Group to store the Key Vault
    - Resource Groups for each tier to store the Terraform state Storage Account
    - A Service Principal to execute terraform commands
    - An Azure Key Vault to store the Service Principal's client ID and client secret
    - A Storage Account and Container for each tier to store tier Terraform state files
    - Tier specific Terraform backend config files

    ```bash
    src/scripts/config/create_mlz_configuration_resources.sh src/mlz.config
    ```

### Set Terraform Configuration Variables

First, clone the *.tfvars.sample file for the global Terraform configuration (e.g. [src/core/globals.tfvars.sample](/src/core/globals.tfvars.sample)) and substitute placeholders marked by curly braces "{" and "}" with the values of your choosing.

Then, repeat this process, cloning the *.tfvars.sample file for the Terraform configuration(s) you are deploying and substitute placeholders marked by curly braces "{" and "}" with the values of your choosing.

For example:

```plaintext
location="{MLZ_LOCATION}" # the templated value in src/core/globals.tfvars.sample
```

Would become:

```plaintext
location="eastus" # the value used by Terraform in src/core/globals.tfvars
```

### Deploy Terraform Configuration

You can use `apply_terraform.sh` at [src/scripts/terraform/apply_terraform.sh](/src/scripts/terraform/apply_terraform.sh) to both initialize Terraform and apply a Terraform configuration based on the backend environment variables and Terraform variables you've setup in previous steps.

The script `destroy_terraform.sh` at [src/scripts/terraform/destroy_terraform.sh](/src/scripts/terraform/destroy_terraform.sh) is helpful during testing. This script is exactly like the
`apply_terraform.sh` except it destroys resources defined in the target state file

`apply_terraform.sh` and `destroy_terraform.sh` take two arguments:

  1. The Global variables file
  1. The directory that contains the main.tf and *.tfvars variables file of the configuration to apply

The hub network must be deployed first. See [Networking](https://github.com/Azure/missionlz#networking) for a description of the hub and spoke and what each network is used for.

For saca-hub, run the following command to apply the terraform configuration from the root of this repository.

```bash
  src/scripts/terraform/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/saca-hub saca-hub.tfvars
```

You could apply Tier 0 (Identity and Authorization) with a command below:

```bash
src/scripts/terraform/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/tier-0 tier-0.tfvars
```

To apply Tier 1 (Infrastructure Operations), you could then change the target directory:

```bash
src/scripts/terraform/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/tier-1 tier-1.tfvars
```

Repeating this same pattern, for whatever configuration you wanted to apply and reuse in some automated pipeline.

Use `init_terraform.sh` at [src/scripts/terraform/init_terraform.sh](/src/scripts/terraform/init_terraform.sh) to perform just an initialization of the Terraform environment

To initialize Terraform for Tier 1 (Infrastructure Operations), you could then change the target directory:

```bash
src/scripts/terraform/init_terraform.sh \
  src/core/tier-1
```

### Clean up Mission LZ Resources

After you've deployed your environments with Terraform, it is no longer mandatory to keep Mission LZ Resources like the Service Principal, Key Vault, nor the Terraform state files (though you can re-use these resources and stored Terraform state for updating the deployed environment incrementally using `terraform apply` or destroying them from terraform with `terraform destroy`).

If you no longer have the need for a Service Principal with Contributor rights, the Key Vault that stores this Service Principal's credentials, nor the Terraform state, you can clean up these Mission LZ Resources with the [config_clean.sh](/src/scripts/config/config_clean.sh) script passing in the MLZ Configuration file you created earlier:

```bash
src/scripts/config/config_clean.sh src/mlz.config
```

### Terraform Providers

The development container definition downloads the required Terraform plugin providers during the container build so that the container can be transported to an air-gapped network for use. The container also sets the `TF_PLUGIN_CACHE_DIR` environment variable, which Terraform uses as the search location for locally installed providers. If you are not using the container to deploy or if the `TF_PLUGIN_CACHE_DIR` environment variable is not set, Terraform will automatically attempt to download the provider from the internet when you execute the `terraform init` command.

See the development container [README](/.devcontainer/README.md) for more details on building and running the container.

## Helpful Links

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>
