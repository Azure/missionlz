# workflows

These are the automated workflows we use for ensuring a quality working product.

For more on GitHub Actions: <https://docs.github.com/en/actions/>

For more on workflows: <https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions/>

## Contents

- apply-terraform.yml

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
