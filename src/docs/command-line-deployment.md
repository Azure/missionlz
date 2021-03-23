# Command-Line Deployment

## Step-by-step

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

1. [Configure the Terraform Backend](#Configure-the-Terraform-Backend)
1. [Set Terraform Configuration Variables](#Set-Terraform-Configuration-Variables)
1. [Deploy Terraform Configuration](#Deploy-Terraform-Configuration)

### Configure the Terraform Backend

The MLZ deployment architecture uses a single Service Principal whose credentials are stored in a central "config" Key Vault. Terraform state storage is distributed into a separate storage account for each tier. When deploying the MLZ architecture, all tiers can be deployed into a single subscription or each tier can be deployed into its own subscription.

1. Create the `mlz_tf_cfg.var` file using the `mlz_tf_cfg.var.sample` as a template.

    The information in the `mlz_tf_cfg.var` file, will be used by `mlz_tf_setup.sh` to create and populate a `config.vars` file for each tier and saved inside the deployment folder for each tier (example: \src\core\tier-0\config.vars).

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

1. Run `mlz_tf_setup.sh` at [src/scripts/mlz_tf_setup.sh](/src/scripts/mlz_tf_setup.sh) to create:

    - A config Resource Group to store the Key Vault
    - Resource Groups for each tier to store the Terraform state Storage Account
    - A Service Principal to execute terraform commands
    - An Azure Key Vault to store the Service Principal's client ID and client secret
    - A Storage Account and Container for each tier to store tier Terraform state files
    - Tier specific Terraform backend config files

    ```bash
    # usage mlz_tf_setup.sh: <mlz_tf_cfg.var path>

    chmod u+x src/scripts/mlz_tf_setup.sh

    src/scripts/mlz_tf_setup.sh src/core/mlz_tf_cfg.var
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

You can use `apply_terraform.sh` at [src/scripts/apply_terraform.sh](/src/scripts/apply_terraform.sh) to both initialize Terraform and apply a Terraform configuration based on the backend environment variables and Terraform variables you've setup in previous steps.

The script `destroy_terraform.sh` at [src/scripts/destroy_terraform.sh](/src/scripts/destroy_terraform.sh) is helpful during testing. This script is exactly like the
`apply_terraform.sh` except it destroys resources defined in the target state file

`apply_terraform.sh` and `destroy_terraform.sh` take two arguments:

  1. The Global variables file
  1. The directory that contains the main.tf and *.tfvars variables file of the configuration to apply

For example, from the root of this repository, you could apply Tier 0 with a command like:

```bash
src/scripts/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/tier-0
```

To apply Tier 1, you could then change the target directory:

```bash
src/scripts/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/tier-1
```

Repeating this same pattern, for whatever configuration you wanted to apply and reuse in some automated pipeline.

Use `init_terraform.sh` at [src/scripts/init_terraform.sh](/src/scripts/init_terraform.sh) to perform just an initialization of the Terraform environment

To initialize Terraform for Tier 1, you could then change the target directory:

```bash
src/scripts/init_terraform.sh \
  src/core/tier-1
```

### Terraform Providers

The development container definition downloads the required Terraform plugin providers during the container build so that the container can be transported to an air-gapped network for use. The container also sets the `TF_PLUGIN_CACHE_DIR` environment variable, which Terraform uses as the search location for locally installed providers. If you are not using the container to deploy or if the `TF_PLUGIN_CACHE_DIR` environment variable is not set, Terraform will automatically attempt to download the provider from the internet when you execute the `terraform init` command.

See the development container [README](/.devcontainer/README.md) for more details on building and running the container.

## Helpful Links

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>
