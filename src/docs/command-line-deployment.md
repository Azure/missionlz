# Command-Line Deployment

The steps in this article assume the following pre-requisites for command-line deployments:

* Follow the Mission LZ [Getting Started](https://github.com/Azure/missionlz/blob/main/src/docs/getting-started.md#pre-requisites) steps.
* **(Highly recommend)** Use the [the Mission LZ `.devcontainer`](https://github.com/Azure/missionlz/blob/main/src/docs/getting-started.md#use-the-development-container-for-command-line-deployments) provided in the Mission LZ project and perform the deployment steps below within this context. This container image provides a controlled environment that includes all the pre-requisite tools for Mission LZ deployments and should lead to an overall better user experience.

  > As an alternative, it is possible to deploy Mission LZ via BASH running from the local workstation, but requires the following additional requirements:
  >
  > * The current version of Azure CLI (try `az version` or see <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli/>)
  > * Terraform CLI version > v0.13.4 (try `terraform -v` or see <https://learn.hashicorp.com/tutorials/terraform/install-cli/>)

## Step-by-step

1. Follow the [steps to open the `.devcontainer`](../../.devcontainer/README.md) as the recommended option (or start a local BASH shell with the additional requirements installed as the alternate option)

   > `vscode@missionlz-dev:/workspaces/missionlz$` is the root working directory for the BASH shell in the `.devcontainer`

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

   > *(Optional)* If you needed to deploy into another cloud such as Azure Government, set the cloud name before logging in:

     ```BASH
     az cloud set -n AzureUSGovernment
     az login
     ```

1. Quickstart
   1. [Deploy](#quickstart-deploy)
   1. [Clean](#quickstart-clean)
   1. [Arguments](#quickstart-arguments)
1. Advanced path (*optional*)
   1. [Setup Mission LZ Resources](#setup-mission-lz-resources)
   1. [Set Terraform Configuration Variables](#set-terraform-configuration-variables)
   1. [Deploy Terraform Configuration](#deploy-terraform-configuration)
   1. [Clean up Mission LZ Resources](#clean-up-mission-lz-resources)

## Quickstart

### Quickstart Deploy

Interested in just getting started and seeing what this does? Login to Azure CLI and try this command to deploy Mission LZ with some default configuration:

```bash
src/scripts/deploy.sh -s {your_subscription_id}
```

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

### Quickstart Clean

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

### Quickstart Arguments

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
      --tier3-sub-id -3 [OPTIONAL] subscription ID for tier 3 network and resources (defaults to the value provided for -s --subscription-id), input is used in conjunction with deploy_t3.sh
      --write-output -w [OPTIONAL] Tier 3 Deployment requires Terraform output, use this flag to write terraform output
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

## Setup Mission LZ Resources

Deployment of MLZ happens through use of a single Service Principal whose credentials are stored in a central "config" Key Vault.

MLZ uses this Service Principal and its credentials from the Key Vault to deploy the resources described in Terraform at `src/terraform` and stores Terraform state for each component into separate storage accounts.

1. First, create the MLZ Configuration file `mlz.config` file using the `mlz.config.sample` as a template.

    The information in the `mlz.config` file, will be used by `create_required_resources.sh` to create and populate a `config.vars` file for each tier and saved inside the deployment folder for each tier (example: \src\core\tier-0\config.vars).

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

1. Then, run `create_required_resources.sh` at [src/scripts/config/create_required_resources.sh](/src/scripts/config/create_required_resources.sh) to create:

    * A Service Principal to execute terraform commands
    * A config Resource Group to store the Key Vault
    * A config Key Vault to store the Service Principal's client ID and client secret
    * A terraform state Resource Groups for each tier
    * A terraform state Storage Account for each tier
    * A terraform state Storage Container for each tier
    * Backend config file (config.vars) for the deployment

    ```bash
    src/scripts/config/create_required_resources.sh src/mlz.config
    ```

## Set Terraform Configuration Variables

First, clone the *.tfvars.sample file ([src/terraform/mlz/mlz.tfvars.sample](/src/terraform/mlz/mlz.tfvars.sample)) and substitute placeholders marked by curly braces "{" and "}" with the values of your choosing.

For example:

```plaintext
location="{MLZ_LOCATION}" # the templated value in src/terraform/mlz/mlz.tfvars.sample
```

Would become:

```plaintext
location="eastus" # the value used by Terraform in src/terraform/mlz/mlz.tfvars.sample
```

## Deploy Terraform Configuration

You can use `apply_terraform.sh` at [src/scripts/terraform/apply_terraform.sh](/src/scripts/terraform/apply_terraform.sh) to both initialize Terraform and apply a Terraform configuration based on the backend environment variables and Terraform variables you've setup in previous steps.

The script `destroy_terraform.sh` at [src/scripts/terraform/destroy_terraform.sh](/src/scripts/terraform/destroy_terraform.sh) is helpful during testing. This script is exactly like the
`apply_terraform.sh` except it destroys resources defined in the target state file

`apply_terraform.sh` and `destroy_terraform.sh` take two arguments:

  1. The directory that contains the main.tf to apply
  1. The path to the .tfvars variables file to apply

For example, run the following command to apply the MLZ terraform configuration repository.

```bash
  src/scripts/terraform/apply_terraform.sh \
  src/terraform/mlz \
  src/terraform/mlz.tfvars
```
Use `init_terraform.sh` at [src/scripts/terraform/init_terraform.sh](/src/scripts/terraform/init_terraform.sh) to perform just an initialization of the Terraform environment:

```bash
src/scripts/terraform/init_terraform.sh \
  src/terraform/mlz
```

## Clean up Mission LZ Resources

After you've deployed your environments with Terraform, it is no longer mandatory to keep Mission LZ Resources like the Service Principal, Key Vault, nor the Terraform state files (though you can re-use these resources and stored Terraform state for updating the deployed environment incrementally using `terraform apply` or destroying them from terraform with `terraform destroy`).

If you no longer have the need for a Service Principal with Contributor rights, the Key Vault that stores this Service Principal's credentials, nor the Terraform state, you can clean up these Mission LZ Resources with the [config_clean.sh](/src/scripts/config/config_clean.sh) script passing in the MLZ Configuration file you created earlier:

```bash
src/scripts/config/config_clean.sh src/mlz.config
```

## Terraform Providers

The development container definition downloads the required Terraform plugin providers during the container build so that the container can be transported to an air-gapped network for use. The container also sets the `TF_PLUGIN_CACHE_DIR` environment variable, which Terraform uses as the search location for locally installed providers. If you are not using the container to deploy or if the `TF_PLUGIN_CACHE_DIR` environment variable is not set, Terraform will automatically attempt to download the provider from the internet when you execute the `terraform init` command.

See the development container [README](/.devcontainer/README.md) for more details on building and running the container.

## Helpful Links

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>
