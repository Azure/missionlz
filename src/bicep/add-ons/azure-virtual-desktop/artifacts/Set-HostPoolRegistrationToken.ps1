[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]$HostPoolName,

    [parameter(Mandatory)]
    [string]$HostPoolResourceGroupName,

    [parameter(Mandatory)]
    [string]$KeyVaultUri,
    
    [parameter(Mandatory)]
    [string]$SubscriptionId
)

##############################################################
#  Functions
##############################################################
function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}


##############################################################
#  Preferences
##############################################################
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'


##############################################################
#  Create Key Vault Secret with Host Pool Registration Token
##############################################################
try 
{
    # Get an access token for Azure resources
    $AzureManagementAccessToken = (Invoke-RestMethod `
        -Headers @{Metadata="true"} `
        -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F').access_token
    Write-Log -Type 'INFO' -Message 'Successfully retrieved access token for Azure Management API'

    # Set header for Azure Management API
    $AzureManagementHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $AzureManagementAccessToken
    }
    Write-Log -Type 'INFO' -Message 'Successfully set header for Azure Management API'

    # Use the access token to update the host pool registration token
    Invoke-RestMethod `
        -Body (@{properties = @{registrationInfo = @{expirationTime = $(Get-Date).AddMinutes(90); registrationTokenOperation = "Update" }}} | ConvertTo-Json) `
        -Headers $AzureManagementHeader `
        -Method 'PATCH' `
        -Uri $('https://management.azure.com/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '?api-version=2022-02-10-preview') | Out-Null
    Write-Log -Type 'INFO' -Message 'Successfully updated host pool registration token'

    # Use the access token to get the host pool registration token
    $HostPoolRegistrationToken = (Invoke-RestMethod `
        -Headers $AzureManagementHeader `
        -Method 'POST' `
        -Uri $('https://management.azure.com/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/retrieveRegistrationToken?api-version=2022-02-10-preview')).token
    Write-Log -Type 'INFO' -Message 'Successfully retrieved host pool registration token'

    # Get an access token for the Azure key vault
    $KeyVaultAccessToken = (Invoke-RestMethod `
        -Headers @{Metadata="true"} `
        -Method 'GET' `
        -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net').access_token
    Write-Log -Type 'INFO' -Message 'Successfully retrieved access token for Azure Key Vault API'

    # Set header for Azure Key Vault API
    $KeyVaultHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $KeyVaultAccessToken
    }
    write-Log -Type 'INFO' -Message 'Successfully set header for Azure Key Vault API'

    # Create a key vault secret with the host pool registration token
    Invoke-RestMethod `
        -Body (@{value = $HostPoolRegistrationToken} | ConvertTo-Json) `
        -Headers $KeyVaultHeader `
        -Method 'PUT' `
        -Uri $($KeyVaultUri + '/secrets/avdHostPoolRegistrationToken?api-version=7.4') | Out-Null
    Write-Log -Type 'INFO' -Message 'Successfully created or updated the key vault secret with host pool registration token'

    $Output = [pscustomobject][ordered]@{
        hostPoolName = $HostPoolName
    }
    $JsonOutput = $Output | ConvertTo-Json
    return $JsonOutput
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}