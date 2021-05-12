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

    1. Applies terraform anew from that configuration (see [build/README.md](../../build/README.md) for how this works)

    1. Destroys terraform from that configuration (see [build/README.md](../../build/README.md) for how this works)

- validate-terraform.yml

    1. Checks out the .devcontainer from a private container registry for common tools

    1. Recursively validates and lints all the terraform referenced at src/core

## Configuration Prerequisites

1. MLZ Setup

    To apply terraform at all, locally, or from this automation, `src/scripts/config/create_mlz_configuration_resources.sh` must be run to create the storage accounts to store Terraform state and create the Service Principal with authorization to deploy resources into the configured subscription(s).

    See the root README's [Configure the Terraform Backend](#../..//README.md/#Configure-the-Terraform-Backend) on how to do this.

1. Configuration store

    When applying terraform locally or from this automation, an MLZ Configuration file (commonly mlz.config) and Terraform-specific variables files (commonly *.tfvars) are required.

    You should end up with a container with these files:

    File Name | Value
    ------------ | -------------
    mlz.config | An MLZ Configuration file that comes from create_mlz_configuration_resources.sh
    globals.tfvars | Global MLZ terraform values
    saca-hub.tfvars | SACA Hub MLZ terraform values
    tier-0.tfvars | Tier 0 MLZ terraform values
    tier-1.tfvars | Tier 1 MLZ terraform values
    tier-2.tfvars | Tier 2 MLZ terraform values

    Running this from your local machine, you can provide these files yourself, but, today, for automation these files are stored in an Azure Storage Account and retrieved at workflow execution time. See [build/get_vars.sh](../../build/get_vars.sh) to see how we retrieve

    ```plaintext
    ./build/get_vars.sh

    # pulls down these files:
    vars/mlz.config
    vars/globals.tfvars
    vars/saca-hub.tfvars
    vars/tier-0.tfvars
    vars/tier-1.tfvars
    vars/tier-2.tfvars
    ```

1. Secret store and minimally scoped Service Principal

    See [glennmusa/keyvault-for-actions](https://github.com/glennmusa/keyvault-for-actions) to create a minimally scoped Service Principal to pull sensitive values from an Azure Key Vault.

    Supply that Key Vault the values for:

    Secret Name | Value
    ------------ | -------------
    MLZTENANTID | The Tenant to deploy MLZ into
    MLZCLIENTID | The Service Principal Authorized to deploy resources into MLZ Terraform Subscriptions
    MLZCLIENTSECRET | The credential for the Service Principal above
    STORAGEACCOUNT | The Azure Storage Account for the files in the previous step
    STORAGECONTAINER | The container contianing the files in the previous step
    STORAGETOKEN | A token to access the storage account (we used a Container SAS)

    For more on creating a minimally scoped token to access storage see: <https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview/>
