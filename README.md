# Mission LZ

Terraform resources to deploy Tier 0, 1, and 2, and the components of a [SACA hub](https://docs.microsoft.com/en-us/azure/azure-government/compliance/secure-azure-computing-architecture).

## Getting Started

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

1. [Prepare the Terraform provider cache](#Prepare-the-Terraform-provider-cache)
1. [Configure the Terraform Backend](#Configure-the-Terraform-Backend)
1. [Set Terraform Configuration Variables](#Set-Terraform-Configuration-Variables)
1. [Deploy Terraform Configuration](#Deploy-Terraform-Configuration)

### Prepare the Terraform provider cache

We source the terraform provider locally from this repository and circumvent the need to fetch it from the internet.

This below script will unzip the provider from the /src/provider_archive folder and place the provider in the /src/provider_cache folder and set execute permissions for the current user.

Execute `unzipprovider.sh`

```bash
chmod u+x src/provider_archive/unzipprovider.sh
src/provider_archive/unzipprovider.sh
```

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

1. Run `mlz_tf_setup.sh` at [scripts/mlz_tf_setup.sh](scripts/mlz_tf_setup.sh) to create:

    - A config Resource Group to store the Key Vault
    - Resource Groups for each tier to store the Terraform state Storage Account
    - A Service Principal to execute terraform commands
    - An Azure Key Vault to store the Service Principal's client ID and client secret
    - A Storage Account and Container for each tier to store tier Terraform state files
    - Tier specific Terraform backend config files

    ```bash
    # usage mlz_tf_setup.sh: <mlz_tf_cfg.var path>

    chmod u+x scripts/mlz_tf_setup.sh

    scripts/mlz_tf_setup.sh src/core/mlz_tf_cfg.var
    ```

### Set Terraform Configuration Variables

First, clone the *.tfvars.sample file for the global Terraform configuration (e.g. [src/core/globals.tfvars.sample](src/core/globals.tfvars.sample)) and substitute placeholders marked by curly braces "{" and "}" with the values of your choosing.

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

You can use `apply_terraform.sh` at [scripts/apply_terraform.sh](scripts/apply_terraform.sh) to both initialize Terraform and apply a Terraform configuration based on the backend environment variables and Terraform variables you've setup in previous steps.

The script `destroy_terraform.sh` at [scripts/destroy_terraform.sh](scripts/destroy_terraform.sh) is helpful during testing. This script is exactly like the
`apply_terraform.sh` except it destroys resources defined in the target state file

`apply_terraform.sh` and `destroy_terraform.sh` take two arguments:

  1. The Global variables file
  1. The directory that contains the main.tf and *.tfvars variables file of the configuration to apply

For example, from the root of this repository, you could apply Tier 0 with a command like:

```bash
scripts/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/tier-0
```

To apply Tier 1, you could then change the target directory:

```bash
scripts/apply_terraform.sh \
  src/core/globals.tfvars \
  src/core/tier-1
```

Repeating this same pattern, for whatever configuration you wanted to apply and reuse in some automated pipeline.

Use `init_terraform.sh` at [scripts/init_terraform.sh](scripts/init_terraform.sh) to perform just an initialization of the Terraform environment

To initialize Terraform for Tier 1, you could then change the target directory:

```bash
scripts/init_terraform.sh \
  src/core/tier-1
```

## Helpful Links

For more endpoint mappings between AzureCloud and AzureUsGovernment: <https://docs.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers/>

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com/>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
