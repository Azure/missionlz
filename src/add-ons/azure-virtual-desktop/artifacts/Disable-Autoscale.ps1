Param(
    [string]$HostPoolResourceId,
    [string]$ResourceGroupName,
    [string]$ResourceManagerUri,
    [string]$ScalingPlanName,
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

# Check if the scaling plan exists: https://learn.microsoft.com/rest/api/desktopvirtualization/scaling-plans/list-by-resource-group
$ScalingPlanExists = (Invoke-RestMethod `
    -Headers $AzureManagementHeader `
    -Method 'GET' `
    -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.DesktopVirtualization/scalingPlans?api-version=2023-09-05')).value | Where-Object {$_.name -eq $ScalingPlanName}

# Disable autoscale for the host pool: https://learn.microsoft.com/rest/api/desktopvirtualization/scaling-plans/update
if ($ScalingPlanExists)
{
    Invoke-RestMethod `
        -Body (@{properties = @{hostPoolReferences = @(@{hostPoolArmPath = $HostPoolResourceId; scalingPlanEnabled = $false})}} | ConvertTo-Json -Depth 3) `
        -Headers $AzureManagementHeader `
        -Method 'PATCH' `
        -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.DesktopVirtualization/scalingPlans/' + $ScalingPlanName + '?api-version=2023-09-05') | Out-Null
}