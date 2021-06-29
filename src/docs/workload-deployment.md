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

In tandem with the quickstart found in [QuickStart Deploying MLZ](command-line-deployment.md#Quickstart) you can quickly get up and running and deploy a single workload instance to your configuration.  

> NOTE: This should be run using the `--tier3-sub-id` flag and `--write-output` flag if you wish to specify the subscription ID for the tier 3. Be sure to use the "-w" flag to ensure that the output required for deployment is generated.

After you have deployed the core MLZ resources, you can use this command (the generated-configuration item artifacts come from the base deployment and can be reused), substituting `{mlz_env_name}` with the appropriate value.

```bash
./deploy_t3.sh ../generated-configurations/{mlz_env_name}.mlzconfig ../generated-configurations/{mlz_env_name}.tfvars ../generated-configurations/output.tfvars.json y
```

> **CONSIDERATIONS** This script should not be run unless the instructions for setting up the core MLZ deployment have been followed. It will deploy a single workload with default configurations for testing/demonstration purposes.

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

2. You will need to source the global terraform configuration you used for your primarily deployment. This is typically located at [src/terraform/mlz/mlz.tfvars.sample](/src/terraform/mlz/mlz.tfvars.sample)),  if you used quickstart you may find it in the src/generated-configurations directory. Make note of the location.  To specify the changes to the custom Tier 3 you will be making, scroll to the tier 3 variables located in the file and change the values to what you need.

    > **NOTE** If you will be deploying multiple T3's the subnet network addresses and subscriptions will be the most important values that need your attention as they will conflict otherwise.
  
3. The deployment of a Tier 3 relies on an already completed deployment of MLZ and a resulting output json file containing 3 variables:

    ```json
      {
        "firewall_private_ip": {
          "sensitive": false,
          "type": "string",
          "value": "{value}"
        },
        "laws_name": {
          "sensitive": false,
          "type": "string",
          "value": "{value}"
        },
        "laws_rgname": {
          "sensitive": false,
          "type": "string",
          "value": "{value}"
        }
      }
    ```

    ```plaintext
      Values:
      laws_name:  The Log Analytic workspace name
      laws_rgname: The resource group you've deployed LAWS to.
      firewall_private_ip: The Ip address of the firewall that the tier 3 will be connecting to.
    ```

    You can manually provide these in an output.tfvars.json file if needed.

4. Once you have collected all of these artifacts you can deploy your workload tier with.  The folder names are examples, these files can be placed anywhere.

  ```bash
    src/scripts/deploy_t3.sh \
    src/mlz.config
    src/terraform/output.tfvars.json
    src/terraform/tier-3/tier-3.tfvars
  ```

After completing these steps, the workload tier will be deployed and you can add whatever services you need to the tier.
