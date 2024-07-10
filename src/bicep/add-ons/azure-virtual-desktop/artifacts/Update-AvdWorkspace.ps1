param(
    [string]$ApplicationGroupReferences,
    [string]$ResourceManagerUri,
    [string]$UserAssignedIdentityClientId,
    [string]$WorkspaceResourceId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Fix the resource manager URI since only AzureCloud contains a trailing slash
$ResourceManagerUriFixed = if($ResourceManagerUri[-1] -eq '/'){$ResourceManagerUri.Substring(0,$ResourceManagerUri.Length - 1)} else {$ResourceManagerUri}

# Get an access token for Azure resources
$AzureManagementAccessToken = (Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

# Set header for Azure Management API
$AzureManagementHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $AzureManagementAccessToken
}

# Use the access token to get the app group references on the workspace
$OldAppGroupReferences = (Invoke-RestMethod `
    -Headers $AzureManagementHeader `
    -Method 'GET' `
    -Uri $($ResourceManagerUriFixed + $WorkspaceResourceId + '?api-version=2022-02-10-preview')).properties.applicationGroupReferences

[array]$NewAppGroupReferences = $ApplicationGroupReferences.Replace("'",'"') | ConvertFrom-Json
$OldAppGroupReferences = $OldAppGroupReferences -ne $NewAppGroupReferences
$CombinedApplicationGroupReferences = $OldAppGroupReferences + $NewAppGroupReferences

# Use the access token to update the app group references on the workspace
Invoke-RestMethod `
    -Body (@{properties = @{applicationGroupReferences = $CombinedApplicationGroupReferences}} | ConvertTo-Json) `
    -Headers $AzureManagementHeader `
    -Method 'PATCH' `
    -Uri $($ResourceManagerUriFixed + $WorkspaceResourceId + '?api-version=2022-02-10-preview') | Out-Null