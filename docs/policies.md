# Mission Landing Zone - Regulatory Compliance - NIST Policies

[**Home**](../README.md) | [**Design**](./design.md) | [**Add-Ons**](../src/bicep/add-ons/README.md) | [**Resources**](./resources.md)

A goal of Mission Landing Zone (MLZ) is to ensure deployments have the tools and resources available that allow it to be compliant with most regulations across most industries.

This does not mean that workloads are compliant, but it does mean that the technologies in use can be compliant. This is caused by not only the varying number of compliance bodies involved and and the regulations they mandate but also caused by the decisions required by how and what controls are followed.

We created an example in the MLZ deployment that can be audited for current National Institute of Standards and Technology (NIST) controls and requirements using the [Azure Policies built in initiative for NIST 800-53](https://docs.microsoft.com/en-us/azure/governance/policy/samples/nist-sp-800-53-r4).

_Note: this is focused on NIST controls that have built in policies in Azure clouds._

![Policy and the MLZ deployment footprint](images/20210419_missionlz_as_of_Aug2021_Policy.png)

## Known Issues

There are a set of known issues with this approach:

1. The first and important detail is that these policies are based on built-in policies available in the different Azure environments.

There are some variances in policy availability between clouds. This will always happen when separate isolated environments have different deployment cycles but also can be based on preview testing versus generally available components in one cloud environment versus another.

2. A secondary issue comes from the method in which the assignment is deployed.

This results in 'out of band' requirements for customers.

In particular, the current built-in NIST initiative has a couple policies attached that modify and/or deploy if a resource doesn't exist. For example, VM extensions for guest policy configuration would be deployed if they don't exist in the VM.

These types of policies require a managed identity be created that the Policy engine can use to take these actions. This managed identity must have Contributor access to the resources but deploying as a Contributor and not owner limits the ability.

3. The final note is that these are audits based on NIST controls and recommendations that will require out of band work.

For example, storage account redundancy and encryption will require a decision process on what MLZ is using as temporary storage for logs versus requirements for the workloads.

For example, encryption can be accomplished with multiple key models, but which one is required for what category of data?

## Deploying

Deploying policy assignments for NIST along with a standard deployment of MLZ is simple and described below. This example will add a separate assignment of the built in NIST initiative per resource group in the deployment.

### Deploying with Bicep

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the parameter with one of the following, NISTRev4, NISTRev5, IL5 or CMMC. For example:

```plaintext
az deployment sub create \
  --location eastus \
  --template-file mlz.bicep \
  --parameters deployPolicy=true \
  --parameters policy=<one of 'CMMC', 'IL5', 'NISTRev4', or 'NISTRev5'>
```

Or, you can apply policy after deploying MLZ:

```plaintext
az deployment group create \
  --resource-group <Resource Group to assign> \
  --name <original deployment name + descriptor> \
  --template-file ./src/bicep/modules/policy-assignment.bicep \
  --parameters builtInAssignment=<one of 'CMMC', 'IL5', 'NISTRev4', or 'NISTRev5'> logAnalyticsWorkspaceName=<Log analytics workspace name> \
  --parameters logAnalyticsWorkspaceName=<Log Analytics Workspace Name> \
  --parameters logAnalyticsWorkspaceResourceGroupName=<Log Analytics Workspace Resource Group Name>
```

## Modifying

### Modifying with Bicep

The project stores well-known policies at [src/bicep/modules/policies](../src/bicep/modules/policies) where JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

## What's Next

While this is only a start, the NIST controls included in the built-in initiatives are a good start to understanding requirements on top of MLZ for compliance.

In the near future the hopes are for this to be expanded with additional built-in initiatives as well as offering an option to create your own initiative and custom policies. Potential additions will be server baselines, IL compliances, and custom policies.
