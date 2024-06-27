[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]$HostPoolName,
    
    [parameter(Mandatory)]
    [string]$ResourceGroupName,
    
    [parameter(Mandatory)]
    [string]$SubscriptionId
)

# Get an access token for managed identities for Azure resources
$AccessToken = (Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F').access_token

$Header = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $AccessToken
}

# Use the access token to update the host pool registration token
Invoke-RestMethod `
    -Body (@{properties = @{registrationInfo = @{expirationTime = $(Get-Date).AddMinutes(90); registrationTokenOperation = "Update" }}} | ConvertTo-Json) `
    -Headers $Header `
    -Method 'PATCH' `
    -Uri $('https://management.azure.com/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '?api-version=2022-02-10-preview')

# Use the access token to get the host pool registration token
$RegistrationToken = (Invoke-RestMethod `
    -Headers $Header `
    -Method 'POST' `
    -Uri $('https://management.azure.com/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/retrieveRegistrationToken?api-version=2022-02-10-preview')).token

