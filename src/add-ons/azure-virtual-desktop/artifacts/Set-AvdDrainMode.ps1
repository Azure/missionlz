Param(
    [string]$Environment,
    [string]$HostPoolName,
    [string]$HostPoolResourceGroupName,
    [string]$ResourceManagerUri,
    [int]$SessionHostCount,
    [int]$SessionHostIndex,
    [string]$SubscriptionId,
    [string]$TenantId,
    [string]$UserAssignedIdentityClientId,
    [string]$VirtualMachineNamePrefix
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

# Get the AVD session hosts
$SessionHosts = (Invoke-RestMethod `
    -Headers $AzureManagementHeader `
    -Method 'GET' `
    -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts?api-version=2023-09-05')).value.name

# Enable drain mode for the AVD session hosts
for($i = $SessionHostIndex; $i -lt $($SessionHostIndex + $SessionHostCount); $i++)
{
    $VmNameFull = $VirtualMachineNamePrefix + $i.ToString().PadLeft(4,'0')
    $SessionHostName = ($SessionHosts | Where-Object {$_ -like "*$VmNameFull*"}).Replace("$HostPoolName/", '')
    Invoke-RestMethod `
        -Body (@{properties = @{allowNewSession = $false}} | ConvertTo-Json) `
        -Headers $AzureManagementHeader `
        -Method 'PATCH' `
        -Uri $($ResourceManagerUriFixed + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts/' + $SessionHostName + '?api-version=2023-09-05') | Out-Null
}
