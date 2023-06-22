# workflows

These are the automated workflows we use for ensuring a quality working product.

For more on GitHub Actions: <https://docs.github.com/en/actions/>

For more on workflows: <https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions/>

## Contents

- apply-and-destroy-terraform.yml

    This workflow assumes some pre-requisites have been set-up. See: [Configuration Prerequisites](#configuration-prerequisites)

    1. Checks out the .devcontainer from a private container registry for common tools

    1. Authenticates against a pre-configured KeyVault that contains
        - values for authenticating against a storage account
        - values for deploying terraform

    1. Pulls known good MLZ and Terraform configuration variables from that storage account

    1. Applies terraform anew from that configuration (see [build/README.md](../../build/README.md) for how this works)

    1. Destroys terraform from that configuration (see [build/README.md](../../build/README.md) for how this works)

- validate-terraform.yml

    1. Checks out the .devcontainer from a private container registry for common tools

    1. Recursively validates and lints all the terraform referenced at src/terraform

## Configuration Prerequisites

1. Configuration store

    When applying terraform locally or from this automation, an MLZ Configuration file (commonly mlz.config) and Terraform-specific variables files (commonly *.tfvars) are required.

    You should end up with a container with these files:

    File Name | Value
    ------------ | -------------
    mlz.config | An MLZ Configuration file that comes from create_required_resources.sh
    mlz.tfvars | MLZ terraform values

    Running this from your local machine, you can provide these files yourself, but, today, for automation these files are stored in an Azure Storage Account and retrieved at workflow execution time. See [build/get_vars.sh](../../build/get_vars.sh) to see how we retrieve

    ```plaintext
    ./build/get_vars.sh

    # pulls down these files:
    vars/mlz.config
    vars/mlz.tfvars
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
