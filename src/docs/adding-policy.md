# Managing policies for Azure Subscriptions

The route we've deemed best for managing policy within MLZ is to apply templates of policy where appropriate. The included policy is a simple sample policy that is not relevant to the deployment of MLZ.  It stands as a place holder for future policy groupings.

## Adding Policy

The addition of a policy can be handled manually or by exporting an already created set of templates.  If you wish to export a set of blueprint templates, please follow the instructions at the end of the document.

Blueprint Templates must follow a detailed file folder format.  The description can be found at [Folder Structure](https://docs.microsoft.com/en-us/azure/governance/blueprints/how-to/import-export-ps#folder-structure-of-a-blueprint-definition)

The example blueprint in the repo at src/scripts/policy/blueprints/BluePrintSample is also a rudimentary example of how these blueprints must be setup.

Additionally, any new templates you would like to apply should be stored at ./src/scripts/policy/blueprints/<BLUEPRINT_NAME>

Finally a parameters file must be set and saved to the ./src/scripts/policy/blueprints/parameters/<BLUEPRINT_NAME>.json file so the system can find it.

This file should contain all of the parameters that are referenced in artifacts or within the blueprint definition file.  If no parameters are required an empty JSON file can be used, similar to the example.  For more information please reference the blueprint quickstart guide for sample file references.  [AZ CLI BluePrint Quickstart](https://docs.microsoft.com/en-us/azure/governance/blueprints/create-blueprint-azurecli)

Once stored you can apply the blueprint to your subscription via the apply_blueprint.sh script located in the src/scripts/policy/ directory via:

```bash
    ./apply_blueprint.sh <SUBSCRIPTION_ID> <LOCATION> <BLUEPRINT_NAME>
```

## BluePrint Template Export

In order to generate the templates that can be used with the above import instructions, you can use the following.  At the time of this writing both the PowerShell and Azure Bash CLI have experimental blueprint modules and they are not in complete parity.  In order to execute the following, it will have to be done using the powershell commands. 

You must login, and connect to your relevant subscription prior to running the template export functions

```powershell
Connect-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName "<YOUR_SUBSCRIPTION_NAME>" | Select-AzureRmSubscription
```

```powershell
$bpDefinition = Get-AzBlueprint -SubscriptionId '<YOUR_SUBSCRIPTION_ID>' -Name '<YOUR_BLUEPRINT_NAME>' -Version '<YOUR_BLUEPRINT_VERSION>'
Export-AzBlueprintWithArtifact -Blueprint $bpDefinition -OutputPath "./src/scripts/policy/blueprints/<BLUEPRINT_NAME>"
```
