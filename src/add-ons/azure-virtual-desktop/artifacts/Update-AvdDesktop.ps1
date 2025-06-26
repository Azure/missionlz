Param(
    [string]$ApplicationGroupName,
    [string]$FriendlyName,
    [string]$ResourceGroupName,
    [string]$ResourceManagerUri,
    [string]$SubscriptionId,
    [string]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Wait for role assignment propagation
Start-Sleep -Seconds 30

# Fix the resource manager URI since only AzureCloud contains a trailing slash
$ResourceManagerUriFixed = if ($ResourceManagerUri[-1] -eq '/') {$ResourceManagerUri} else {$ResourceManagerUri + '/'}

# Get an access token for Azure resources
$AzureManagementAccessToken = (Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

# Set header for Azure Management API
$AzureManagementHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $AzureManagementAccessToken
}

# Update the friendly name on the session desktop
Invoke-RestMethod `
    -Body (@{properties = @{friendlyName = $FriendlyName.Replace('"', '')}} | ConvertTo-Json) `
    -Headers $AzureManagementHeader `
    -Method 'PATCH' `
    -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.DesktopVirtualization/applicationGroups/' + $ApplicationGroupName + '/desktops/SessionDesktop?api-version=2023-09-05') | Out-Null