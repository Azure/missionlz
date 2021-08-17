# MLZ MarketPlace Offering

The contents of this folder are used to package the marketplace offering of MLZ.
mainTemplate.json is the post build ARM templates from the bicep output
createUiDefinition.json is the semi manually created bladed template to allow users to enter variables for the UI configuration

## Testing

Test URLs for deployment

#### AzureCloud
[![Deploy To Azure](../docs/imgs/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FEnterprise-Scale%2Fmain%2FeslzArm%2FeslzArm.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FEnterprise-Scale%2Fmain%2FeslzArm%2Feslz-portal.json)

#### AzureUSGovernment
[![Deploy To Azure US Gov](../docs/imgs/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fglennmusa%2Fmissionlz%2Fglennmusa%2Fbicep%2Fsrc%2Fbicep%2Fmlz.json)
