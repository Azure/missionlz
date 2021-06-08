# Workload Deployment (Tier 3)

Mission LZ supports deploying multiple workload tiers that are connected to the hub. We call these tier 3s, or T3s, for convenience. Each tier 3 is intended to support a single workload or single team that needs isolation from the other teams and network connectivity via the hub.

## Command Line Step-by-step

1. Log in using the Azure CLI

    ```BASH
    az login
    ```

1. [Quickstart](#Quickstart)
1. [Advanced Deployment](#Advanced-Deployment)

### Quickstart

#### Quickstart Deploy

In tandem with the quickstart found in [QuickStart Deploying MLZ](command-line-deployment.md#Quickstart) you can quickly get up and running and deploy a single workload instance to your configuration.  Note: This should be run using the -tier3-sub-id flag in order to create the fast config files to deploy this network resource.

After you have deployed the core MLZ resources,  you can use the following (The generated-configuration item artifacts come from the base deployment and can be reused)

```bash
./deploy_t3.sh ../generated-configurations/{mlz_env_name}.mlzconfig ../generated-configurations/{mlz_env_name}.tfvars  ../generated-configurations/{mlz_env_name}.tfvars y
```

> **CONSIDERATIONS** This script should not be run unless the instructions for setting up the core MLZ deployment have been followed.  It will deploy a single workload with default configurations for testing/demonstration purposes.

### Advanced Deployment

A production usage of tier 3 workloads will require a more advanced setup than allowed through a quick start.   In order to perform these deployments you will have to modify three configuration files, and use the deployment script with the resulting files.

> **NOTE** These steps will need to be repeated for each workload tier you wish to add.
<!-- markdownlint-disable MD028 -->
> **NOTE** Like the other Mission LZ tiers, each tier 3 workload can be deployed into its own subscription or they can be deployed into a single subscription. For production deployments we recommend that each tier 3 is deployed into its own subscription to simplify managing security and access.
<!-- markdownlint-enable MD028 -->

1. First, modify the MLZ Configuration file `mlz.config` file using the `mlz.config.sample` as a template,  this file should be a copy of the file used to deploy MLZ.  You will need to modify the following to include the actual subscription number:

    ```plaintext
    mlz_tier3_subid="{MLZ_TIER3_SUBID}" # Optional if not currently deploying a tier 3
    ```

2. You will need to source the global terraform configuration you used for your primarily deployment. This is typically located at [src/core/globals.tfvars.sample](/src/core/globals.tfvars.sample)),  if you used quickstart you may find it in the src/generated-configurations directory. Make note of the location, you will not need to modify this file.

3. You will have to modify the *.tfvars.sample variables for [src/core/tier-3/tier-3.tfvars.sample](/src/core/tier-3/tier-3.tfvars.sample).  If deploying multiple workloads it's especially important to change the 'TIER3_VNETSPACE' variable,  and the matching 'TIER3_SUBNETVM_ADDRESSPREFIXLIST' variable.   These variables represent the networking address space, and they must be different than other tier/workload spaces or the deployment will fail.

4. Once you have collected all of these artifacts you can deploy your workload tier with.  The folder names are examples, these files can be placed anywhere.

  ```bash
    src/scripts/deploy_t3.sh \
    src/mlz.config
    src/core/globals.tfvars \
    src/core/tier-3/tier-3.tfvars
  ```

After completing these steps, the workload tier will be deployed and you can add whatever services you need to the tier.
