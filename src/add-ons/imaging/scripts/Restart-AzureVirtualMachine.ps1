param(
    [string]$ResourceManagerUri,
    [string]$UserAssignedIdentityClientId,
    [string]$VmResourceId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
    
# Restart the VM
Invoke-RestMethod -Headers $AzureManagementHeader -Method 'Post' -Uri $($ResourceManagerUriFixed + $VmResourceId + '/restart?api-version=2024-03-01') | Out-Null

# Wait until VM is running again
$VmStatus = Invoke-RestMethod -Headers $AzureManagementHeader -Method 'Get' -Uri $($ResourceManagerUriFixed + $VmResourceId + '/instanceView?api-version=2024-03-01')
$provisioningState = ($VMStatus.statuses | Where-Object {$_.code -like 'PowerState*'}).code
While ($provisioningState -ne "PowerState/running") {
    Start-Sleep -Seconds 5
    $VmStatus = Invoke-RestMethod -Headers $AzureManagementHeader -Method 'Get' -Uri $($ResourceManagerUriFixed + $VmResourceId + '/instanceView?api-version=2024-03-01')
    $provisioningState = ($VMStatus.statuses | Where-Object {$_.code -like 'PowerState*'}).code
}