# Inheriting Tags

This example adds a policy to a given resource group that forces a specific tag to be inherited by all of its child components.  This example is useful for those trying to create a charging model or provide tracking for resource consumption based on resources in a specific resource group or scope.  You can use this to apply a custom tag of your choosing.

## What this example does

### Deploys Inherit Tag Policy to a Resource

Deploys an assignment resource that will assign a tag of the users choosing to be applied to a resource group' s child resources.

Please pay special attention to the fact that this policy applies to new or updated resources within the group, you will need to trigger an update or remediation.  Remediation can be kicked off via the Azure Portal in the Policy Section.  
For guidance in creating a remediation with the appropriate permissions and applying to all existing resources please see:  [Remediate non-compliant resources with Azure Policy](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources)

For further reading please consult the following documentation:

[Bicep Quickstart Create a Policy Assignment](https://docs.microsoft.com/en-us/azure/governance/policy/assign-policy-bicep?tabs=azure-powershell)

[Inherit a tag from a Resource group policy](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fcd3aa116-8754-49c9-a813-ad46512ece54)

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)70
2. The output from your deployment, or previously retrieved resource group names as well as which tag you would like to be inherited by all of the resource groups items. (Note: The assumption is that you've already added your tag to the resource group)

## Deploy the example

After you've retrieved the required values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment group create` command in the Azure CLI:

```bash
cd examples/inheritTags

tagInherit="yourTaghere"

az deployment group create \
  --name "InheritTagExample" \
  --template-file "./inherit-tags.bicep" \
  --resource-group "resourceGroupName" \
  --parameters \
  tagNameInherit=$tagInherit
```
