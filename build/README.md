# build

This folder contains scripts that would be used by some automation tool to apply/destroy terraform in the repo.

This is a work in progress. Future work will be done to integrate this into a GitHub Actions workflow.

## Why

Provide an unattended way to ensure things are deployable in the repo.

## What you need

- Terraform CLI
- Azure CLI
- Deployed MLZ Config resources (Service Principal for deployment, Key Vault)
- A MLZ Config file
- A global.tfvars
- .tfvars for saca-hub, tier-0, tier-1, tier-2

## How

See the root [README's "Configure the Terraform Backend"](../README.md#Configure-the-Terraform-Backend) on how to get the MLZ Config resources deployed and a MLZ Config file.

Today, the global.tfvars file and the .tfvars for saca-hub, tier0-2, are well known and stored elsewhere. Reach out to the team if you need them.

Then, to apply and destroy pass those six arguments to the relevant script:

```shell
# applies terraform in the repo
./apply_tf.sh \
  ../src/core/mlz_tf_cfg.var \
  ./path_to_vars/globals.tfvars \
  ./path_to_vars/saca-hub.tfvars \
  ./path_to_vars/tier-0.tfvars \
  ./path_to_vars/tier-1.tfvars \
  ./path_to_vars/tier-2.tfvars
```

```shell
# destroys terraform in the repo
./destroy_tf.sh \
  ../src/core/mlz_tf_cfg.var \
  ./path_to_vars/globals.tfvars \
  ./path_to_vars/saca-hub.tfvars \
  ./path_to_vars/tier-0.tfvars \
  ./path_to_vars/tier-1.tfvars \
  ./path_to_vars/tier-2.tfvars
```
