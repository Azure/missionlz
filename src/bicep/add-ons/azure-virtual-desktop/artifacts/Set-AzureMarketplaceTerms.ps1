param (
    [string]$ImageOffer,
    [string]$ImagePublisher,
    [string]$ImageSku,
    [string]$ResourceManagerUri
)

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

# Use the access token to get the marketplace agreement
$Terms = Invoke-RestMethod `
    -Headers $AzureManagementHeader `
    -Method 'GET' `
    -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/providers/Microsoft.MarketplaceOrdering/agreements/' + $ImagePublisher + '/offers/' + $ImageOffer + '/plans/' + $ImageSku + '?api-version=2021-01-01')

# Use the access token to set the marketplace agreement
if($Terms.error)
{
    Invoke-RestMethod `
        -Headers $AzureManagementHeader `
        -Method 'POST' `
        -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/providers/Microsoft.MarketplaceOrdering/agreements/' + $ImagePublisher + '/offers/' + $ImageOffer + '/plans/' + $ImageSku + '/sign?api-version=2021-01-01') | Out-Null
}