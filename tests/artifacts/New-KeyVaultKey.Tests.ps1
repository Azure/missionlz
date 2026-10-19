<#
    Behavioral tests for src/artifacts/New-KeyVaultKey.ps1

    The production script is invoked as-is (via &) under mocked Invoke-RestMethod;
    no edits are made to the script. IMDS / ARM are never contacted.
#>

BeforeAll {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    $script:ScriptPath = Join-Path $RepoRoot 'src' 'artifacts' 'New-KeyVaultKey.ps1'

    $script:CommonArgs = @{
        DiskEncryptionSetName        = 'des-test'
        KeyExpirationInDays          = 30
        KeyName                      = 'key-test'
        KeyVaultResourceId           = '/subscriptions/sub/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv'
        KeyVaultServiceUri           = 'https://vault.azure.net'
        KeyVaultUri                  = 'https://kv.vault.azure.net/'
        Location                     = 'eastus'
        ResourceGroupName            = 'rg'
        ResourceManagerUri           = 'https://management.azure.com/'
        SubscriptionId               = 'sub'
        UserAssignedIdentityClientId = '00000000-0000-0000-0000-000000000000'
    }
}

Describe 'New-KeyVaultKey' {

    It 'creates the key with a rotation policy derived from KeyExpirationInDays' {
        Mock Invoke-RestMethod {
            [pscustomobject]@{
                access_token = 'fake-token'
                key          = [pscustomobject]@{ kid = 'https://kv.vault.azure.net/keys/key-test/abc123' }
            }
        }

        & $ScriptPath @CommonArgs -Type 'storageAccount'

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and
            ($Body | ConvertFrom-Json).rotationPolicy.attributes.expiryTime -eq 'P30D' -and
            (($Body | ConvertFrom-Json).rotationPolicy.lifetimeActions |
                Where-Object { $_.action.type -eq 'Rotate' }).trigger.timeAfterCreate -eq 'P23D'
        }
    }

    It 'does not create a disk encryption set for non-virtualMachine types' {
        Mock Invoke-RestMethod {
            [pscustomobject]@{
                access_token = 'fake-token'
                key          = [pscustomobject]@{ kid = 'https://kv.vault.azure.net/keys/key-test/abc123' }
            }
        }

        & $ScriptPath @CommonArgs -Type 'storageAccount'

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'creates a disk encryption set with a normalized (no double-slash) ARM URI when Type is virtualMachine' {
        Mock Invoke-RestMethod {
            [pscustomobject]@{
                access_token = 'fake-token'
                key          = [pscustomobject]@{ kid = 'https://kv.vault.azure.net/keys/key-test/abc123' }
            }
        }

        & $ScriptPath @CommonArgs -Type 'virtualMachine'

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'PUT' -and
            $Uri -eq 'https://management.azure.com/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Compute/diskEncryptionSets/des-test?api-version=2025-01-02'
        }
    }
}
