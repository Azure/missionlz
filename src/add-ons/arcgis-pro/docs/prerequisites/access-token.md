# ArcGIS Pro Add-On

## Prerequistes

### Azure Active Directory Graph Access Token

The script below requires Azure CLI. There is no PowerShell equivalent. The command will output the access token necessary to install the Entra Cloud Sync provisioing agent without interaction. Currently, the command is only supported in Azure Cloud / Commercial.

```azurecli
az login

az account get-access-token --resource-type 'aad-graph' --scope 'https://proxy.cloudwebappproxy.net/registerapp/user_impersonation' --query accessToken -o tsv
```
