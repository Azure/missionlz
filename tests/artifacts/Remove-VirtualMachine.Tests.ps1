<#
    Behavioral tests for src/artifacts/Remove-VirtualMachine.ps1

    The production script is invoked as-is (via &) under mocked Invoke-RestMethod
    and Start-Sleep; no edits are made to the script and it runs fully offline.
#>

BeforeAll {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    $script:ScriptPath = Join-Path $RepoRoot 'src' 'artifacts' 'Remove-VirtualMachine.ps1'
}

Describe 'Remove-VirtualMachine' {

    It 'deletes the VM with forceDeletion against a normalized (no double-slash) ARM URI' {
        Mock Invoke-RestMethod { [pscustomobject]@{ access_token = 'fake-token' } }
        Mock Start-Sleep { }

        & $ScriptPath `
            -ResourceGroupName 'rg' `
            -ResourceManagerUri 'https://management.azure.com/' `
            -UserAssignedIdentityClientId '00000000-0000-0000-0000-000000000000' `
            -VirtualMachineResourceId '/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm'

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Delete' -and
            $Uri -eq 'https://management.azure.com/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm?forceDeletion=true&api-version=2024-07-01'
        }
    }

    It 'does not block on a real wait (Start-Sleep is invoked, not slept)' {
        Mock Invoke-RestMethod { [pscustomobject]@{ access_token = 'fake-token' } }
        Mock Start-Sleep { }

        & $ScriptPath `
            -ResourceGroupName 'rg' `
            -ResourceManagerUri 'https://management.azure.com/' `
            -UserAssignedIdentityClientId '00000000-0000-0000-0000-000000000000' `
            -VirtualMachineResourceId '/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm'

        Should -Invoke Start-Sleep -Times 1 -Exactly
    }
}
