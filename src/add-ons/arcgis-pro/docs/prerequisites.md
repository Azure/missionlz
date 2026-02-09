# ArcGIS Pro Add-On

## Prerequistes

There are two required steps before the deployment of the ArcGIS Pro add-on. First, a managed identity must be setup in Azure with Microsoft Graph API permissions. Second, an access token to deploy the provisioning agent must be acquired and provided to the "accessToken" param before deployment.

### Step 1 - User Assigned Managed Identity with Microsoft Graph API permissions

The script below assumes you have the Azure and Microsoft Graph PowerShell modules installed. The variables at the top of the script must have values before executing the script.

```powershell
$SubscriptionId = ""
$ResourceGroupName = ""
$IdentityName = ""
$Location = ""

# Connect to Azure
Connect-AzAccount
Set-AzContext -SubscriptionId $SubscriptionId

# Create resource group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# Create the User Assigned Managed Identity
$Identity = New-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $IdentityName -Location $Location

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All"

$ServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($Identity.ClientId)'"
$GraphServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

# List of required permissions
$Permissions = @(
    "Application.ReadWrite.All"
    # "Directory.ReadWrite.All" # This permission is used for directory discovery which currently throws 500 errors
    "Organization.ReadWrite.All"
    "Synchronization.ReadWrite.All"
)

foreach ($Permission in $Permissions) {
    $ApplicationRole = $GraphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $Permission -and $_.AllowedMemberTypes -contains "Application" }
    
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -PrincipalId $ServicePrincipal.Id -ResourceId $GraphServicePrincipal.Id -AppRoleId $ApplicationRole.Id
}
```

### Step 2 - AAD Graph Access Token

The script below requires Azure CLI. There is no PowerShell equivalent.

```azurecli
az login

az account get-access-token --resource-type 'aad-graph' --scope 'https://proxy.cloudwebappproxy.net/registerapp/user_impersonation' --query accessToken -o tsv
```
