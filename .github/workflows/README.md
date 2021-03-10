# workflows

These are the automated workflows we use for ensuring a quality working product.

For more on GitHub Actions: <https://docs.github.com/en/actions/>

For more on workflows: <https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions/>

## Contents

- apply-and-destroy-terraform.yml

    This workflow assumes some pre-requisites have been set-up. See: [Configuration Prerequisites](#Configuration-Prerequisites)

    1. Checks out the .devcontainer from a private container registry for common tools

    1. Authenticates against a pre-configured KeyVault that contains
        - values for authenticating against a storage account
        - values for deploying terraform

    1. Pulls known good MLZ and Terraform configuration variables from that storage account

    1. Applies terraform anew from that configuration

    1. Destroys terraform from that configuration

- validate-terraform.yml

    1. Checks out the .devcontainer from a private container registry for common tools

    1. Recursively validates and lints all the terraform referenced at src/core

## Configuration Prerequisites

1. MLZ Setup

    To apply terraform at all, locally, or from this automation, `scripts/mlz_tf_setup.sh` must be run to create the storage accounts to store Terraform state and create the Service Principal with authorization to deploy resources into the configured subscription(s).

    See the root README's [Configure the Terraform Backend](#../..//README.md/#Configure-the-Terraform-Backend) on how to do this.

1. Configuration store

    When applying terraform locally or from this automation, an MLZ Configuration file (commonly mlz_tf_cfg.var) and Terraform-specific variables files (commonly *.tfvars) are required.

    Running this from your local machine, you can provide these files yourself, but, today, for automation these files are stored in an Azure Storage Account and retrieved at workflow execution time. See [build/get_vars.sh](../../build/get_vars.sh) to see how we retrieve

    ```plaintext
    ./build/get_vars.sh

    # pulls down these files:
    mlz_tf_cfg.var
    globals.tfvars
    saca-hub.tfvars
    tier-0.tfvars
    tier-1.tfvars
    tier-2.tfvars
    ```

1. Secret store and minimally scoped Service Principal

    See [glennmusa/keyvault-for-actions](https://github.com/glennmusa/keyvault-for-actions) to create a minimally scoped Service Principal to pull sensitive values from an Azure Key Vault.

    You'll need to grant the Service Principal from [glennmusa/keyvault-for-actions](https://github.com/glennmusa/keyvault-for-actions) 'Reader' RBAC permissions and 'get list' secret policies from the KeyVault that comes out of [Configure the Terraform Backend](#../..//README.md/#Configure-the-Terraform-Backend):

      - "Reader" RBAC permissions from the Key Vault's "Access control (IAM)" blade
      - "get list" policies from the Key Vault's "Access policies" blade

    Some of the automation in these workflows also rely on Azure Key Vault as a provider to populate sensitive environment variables.

    We use this Azure Key Vault to:

      - retireve the Storage account, container, and minimally privileged SAS token to retrieve configuration files

    We use the Service Principal generated to:

      - get and list secrets from the Key Vault created above
      - get and list secrets from the Key Vault created by [Configure the Terraform Backend](#../..//README.md/#Configure-the-Terraform-Backend)
