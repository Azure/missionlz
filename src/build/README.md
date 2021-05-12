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

Then, to apply and destroy pass those files as arguments to the relevant script.

There's an [optional argument to display terraform output](#Optionally-display-Terraform-output).

```shell
usage() {
  echo "apply_tf.sh: Automation that calls apply terraform given a MLZ configuration and some tfvars"
  error_log "usage: apply_tf.sh <mlz config> <globals.tfvars> <saca.tfvars> <tier0.tfvars> <tier1.tfvars> <tier2.tfvars> <display terraform output (y/n)>"
}
```

```shell
# assuming src/scripts/config/create_mlz_configuration_resources.sh has been run before...
./apply_tf.sh \
  ./path-to/mlz.config \
  ./path-to/globals.tfvars \
  ./path-to/saca-hub.tfvars \
  ./path-to/tier-0.tfvars \
  ./path-to/tier-1.tfvars \
  ./path-to/tier-2.tfvars \
  y
```

```shell
# assuming src/scripts/config/create_mlz_configuration_resources.sh has been run before...
./destroy_tf.sh \
  ./path-to/mlz.config \
  ./path-to/globals.tfvars \
  ./path-to/saca-hub.tfvars \
  ./path-to/tier-0.tfvars \
  ./path-to/tier-1.tfvars \
  ./path-to/tier-2.tfvars \
  y
```

### Optionally display Terraform output

There's an optional argument at the end to specify whether or not to display terraform's output. Set it to 'y' if you want to see things as they happen.

By default, if you do not set this argument, terraform output will be sent to /dev/null (to support clean logs in a CI/CD environment) and your logs will look like:

```plaintext
Applying saca-hub (1/5)...
Finished applying saca-hub!
Applying tier-0 (1/5)...
Finished applying tier-0!
Applying tier-1 (1/5)...
Finished applying tier-1!
Applying tier-2 (1/5)...
Finished applying tier-2!
```

## Gotchas

There's wonky behavior with how Log Analytics Workspaces and Azure Monitor diagnostic log settings are deleted at the Azure Resource Manager level.

For example, if you deployed your environment with Terraform, then deleted it with Azure CLI or the Portal, you can end up with orphan/ghost resources that will be deleted at some other unknown time.

To ensure you're able to deploy on-top of existing resources over and over again, __use Terraform to apply and destroy your environment.__
