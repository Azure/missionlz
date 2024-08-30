Param(
    [string]$HostPoolName,
    [string]$HostPoolResourceGroupName,
    [string]$KeyVaultUri,
    [string]$ResourceManagerUri,
    [string]$SubscriptionId,
    [string]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Fix the resource manager URI since only AzureCloud contains a trailing slash
$ResourceManagerUriFixed = if($ResourceManagerUri[-1] -eq '/'){$ResourceManagerUri} else {$ResourceManagerUri + '/'}

# Get an access token for Azure resources
$AzureManagementAccessToken = (Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

# Set header for Azure Management API
$AzureManagementHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $AzureManagementAccessToken
}

# Use the access token to update the host pool registration token
Invoke-RestMethod `
    -Body (@{properties = @{registrationInfo = @{expirationTime = $(Get-Date).AddMinutes(90); registrationTokenOperation = "Update" }}} | ConvertTo-Json) `
    -Headers $AzureManagementHeader `
    -Method 'PATCH' `
    -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '?api-version=2022-02-10-preview') | Out-Null

# Use the access token to get the host pool registration token
$HostPoolRegistrationToken = (Invoke-RestMethod `
    -Headers $AzureManagementHeader `
    -Method 'POST' `
    -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/retrieveRegistrationToken?api-version=2022-02-10-preview')).token

# Get an access token for the Azure key vault
$KeyVaultAccessToken = (Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Method 'GET' `
    -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $KeyVaultUri + '&client_id=' + $UserAssignedIdentityClientId)).access_token

# Set header for Azure Key Vault API
$KeyVaultHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $KeyVaultAccessToken
}

# Create a key vault secret with the host pool registration token
Invoke-RestMethod `
    -Body (@{value = $HostPoolRegistrationToken} | ConvertTo-Json) `
    -Headers $KeyVaultHeader `
    -Method 'PUT' `
    -Uri $($KeyVaultUri + '/secrets/avdHostPoolRegistrationToken?api-version=7.4') | Out-Null