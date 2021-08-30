# Authentication for Terraform

## Methods

### User Azure Account

The Primary and recommended method for logging into to perform actions with Terraform, is to use the azure bash cli with the 'az login' command.  This requires the account being used to login to have at a minimum contributor roles to all of the subscriptions that are configured in Terraform.  With this method, all providers will be invoked with the user currently logged into the azure cli. For further information and reading please consult the following Terraform documentation:  [Authenticating using the Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

### Service Principals

For more advanced setups in which you are deploying to multiple subscriptions or tenants and those subscriptions have different service principals, you will need to explicitly define your service principals/subscriptions/tenants in the azurerm provider blocks in the terraform packages.  The fields you will need to use can be found at following Terraform Documentation: [AzureRM Documentation: Client_ID](https://www.terraform.io/docs/language/settings/backends/azurerm.html#client_id-1)

Additionally you can review advanced methods of setting up service principal authentication following the Terraform Documentation: [Authenticating to Azure using a Service Principal and a Client Certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_certificate) and [Authenticating to Azure using a Service Principal and a Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
