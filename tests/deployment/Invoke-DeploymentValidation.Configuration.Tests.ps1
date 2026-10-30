# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    . $script:DeploymentValidationTestGuard
}

Describe 'Deployment validation configuration' {
    BeforeEach { . $script:DeploymentValidationTestSetup }
    AfterAll { . $script:DeploymentValidationTestCleanup }

    It 'rejects the wrong Azure cloud without provisioning' {
        $global:MLZValidationTestState.AccountCloud = 'AzureCloud'
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*cloud*'
        @($global:MLZValidationTestState.Calls | Where-Object { $_[0] -eq 'deployment' }).Count | Should -Be 0
    }

    It 'rejects invalid <Parameter> before making Azure calls' -TestCases @(
        @{ Parameter = 'Identifier'; Value = 'too-long' }
        @{ Parameter = 'SubscriptionId'; Value = 'not-a-guid' }
        @{ Parameter = 'Location'; Value = 'usgovvirginia' }
        @{ Parameter = 'DeployDefender'; Value = $false }
    ) {
        param($Parameter, $Value)
        $global:MLZValidationTestState.Arguments[$Parameter] = $Value
        { Invoke-DeploymentValidationUnderTest } | Should -Throw
        $global:MLZValidationTestState.Calls.Count | Should -Be 0
    }
}
