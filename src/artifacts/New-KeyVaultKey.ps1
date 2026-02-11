Param(
    [string]$DiskEncryptionSetName,
    [int]$KeyExpirationInDays,
    [string]$KeyName,
    [string]$KeyVaultResourceId,
    [string]$KeyVaultServiceUri,
    [string]$KeyVaultUri,
    [string]$ResourceGroupName,
    [string]$ResourceManagerUri,
    [string]$SubscriptionId,
    [string]$Type,
    [string]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Fix the resource manager URI since only AzureCloud contains a trailing slash
$ResourceManagerUriFixed = if ($ResourceManagerUri[-1] -eq '/') { $ResourceManagerUri.Substring(0, $ResourceManagerUri.Length - 1) } else { $ResourceManagerUri }

# Get an access token for Azure resources
$KeyVaultAccessToken = (Invoke-RestMethod `
        -Headers @{Metadata = "true" } `
        -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $KeyVaultServiceUri + '&client_id=' + $UserAssignedIdentityClientId)).access_token

# Set header for Azure Management API
$KeyVaultHeaders = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $KeyVaultAccessToken
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
                action  = @{
                    type = 'Notify'
                }
                trigger = @{
                    timeBeforeExpiry = 'P10D'
                }
            },
            @{
                action  = @{
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
$KeyUriWithVersion = (Invoke-RestMethod `
        -Body ($Body | ConvertTo-Json -Depth 4) `
        -Headers $KeyVaultHeaders `
        -Method 'POST' `
        -Uri $($KeyVaultUri + 'keys/' + $KeyName + '/create?api-version=2025-07-01')).key.kid

if ($Type -eq 'VirtualMachine') {

    # Get an access token for Azure resources
    $ResourceManagerAccessToken = (Invoke-RestMethod `
            -Headers @{Metadata = "true" } `
            -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

    # Set header for Azure Management API
    $ResourceManagerHeaders = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $ResourceManagerAccessToken
    }

    $DiskEncryptionSetBody = @{
        location   = "West US"
        identity   = @{
            type = "SystemAssigned"
        }
        properties = @{
            activeKey                         = @{
                sourceVault = @{
                    id = $KeyVaultResourceId
                }
                keyUrl = $KeyUriWithVersion
            }
            encryptionType                    = 'EncryptionAtRestWithPlatformAndCustomerKeys'
            rotationToLatestKeyVersionEnabled = $true
        }
    }

    Invoke-RestMethod `
        -Body ($DiskEncryptionSetBody | ConvertTo-Json -Depth 4) `
        -Headers $ResourceManagerHeaders `
        -Method 'PUT' `
        -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.Compute/diskEncryptionSets/' + $DiskEncryptionSetName + '?api-version=2025-01-02')
}