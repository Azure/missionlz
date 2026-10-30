# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    . $script:DeploymentValidationTestGuard
}

Describe 'Deployment validation baseline' {
    BeforeEach { . $script:DeploymentValidationTestSetup }
    AfterAll { . $script:DeploymentValidationTestCleanup }

    It 'refuses an identifier already used by a baseline resource group before deployment' {
        $global:MLZValidationTestState.Groups += @{ name = 'rg-wk123-existing'; tags = @{} }
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*identifier*'
        @($global:MLZValidationTestState.Calls | Where-Object { $_[0] -eq 'deployment' }).Count | Should -Be 0
        @($global:MLZValidationTestState.Groups.name) | Should -Contain 'rg-wk123-existing'
    }

    It 'does not deploy or delete anything when baseline capture fails' {
        $global:MLZValidationTestState.BaselineFails = $true
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*baseline*'
        @($global:MLZValidationTestState.Calls | Where-Object { $_ -contains 'create' -or $_ -contains 'delete' }).Count | Should -Be 0
    }
}
