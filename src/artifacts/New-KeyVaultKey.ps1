Param(
    [int]$KeyExpirationInDays,
    [string]$KeyName,
    [string]$KeyVaultServiceUri,
    [string]$KeyVaultUri,
    [string]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Get an access token for Azure resources
$AccessToken = (Invoke-RestMethod `
        -Headers @{Metadata = "true" } `
        -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $KeyVaultServiceUri + '&client_id=' + $UserAssignedIdentityClientId)).access_token

# Set header for Azure Management API
$Headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $AccessToken
}

$Body = [PSCustomObject]@{
    kty            = 'RSA-HSM'
    key_size       = 4096
    attributes     = @{
        enabled = $true
    }
    rotationPolicy = @{
        attributes      = @{
            expiryTime = $('P' + $KeyExpirationInDays + 'D')
        }
        lifetimeActions = @(
            @{
                action = @{
                    type = 'Notify'
                }
                trigger = @{
                    timeBeforeExpiry = 'P10D'
                }
            },
            @{
                action = @{
                    type = 'Rotate'
                }
                trigger = @{
                    timeAfterCreate = $('P' + ($KeyExpirationInDays - 7) + 'D')
                }
            }
        )
    }
}

# Create key vault key
Invoke-RestMethod `
    -Body ($Body | ConvertTo-Json -Depth 4) `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($KeyVaultUri + 'keys/' + $KeyName + '?api-version=2025-07-01') | Out-Null