# ArcGIS Pro Add-On

## Prerequistes

### User Assigned Managed Identity with Microsoft Graph API permissions

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