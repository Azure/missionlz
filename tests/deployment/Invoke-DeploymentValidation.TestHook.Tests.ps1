# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    . $script:DeploymentValidationTestGuard
}

Describe 'Deployment validation test hook' {
    BeforeEach { . $script:DeploymentValidationTestSetup }
    AfterAll { . $script:DeploymentValidationTestCleanup }

    It 'runs the requested test hook with the deployment configuration before cleanup' {
        $hook = Join-Path $TestDrive 'Hook.ps1'
        $marker = Join-Path $TestDrive 'hook-config.json'
        @'
param($SubscriptionId, $HubSubscriptionId, $IdentitySubscriptionId, $OperationsSubscriptionId,
    $SharedServicesSubscriptionId, $Location, $Identifier, $EnvironmentAbbreviation)
$PSBoundParameters | ConvertTo-Json | Set-Content $env:MLZ_TEST_MARKER
'private hook output: credential=do-not-publish'
'@ | Set-Content $hook
        $env:MLZ_TEST_MARKER = $marker
        try {
            $global:MLZValidationTestState.Arguments.TestScriptPath = $hook
            $report = Invoke-DeploymentValidationUnderTest
            $report.TestStatus | Should -Be 'Passed'
            $config = Get-Content $marker -Raw | ConvertFrom-Json
            $config.SubscriptionId | Should -Be $global:MLZValidationTestState.SubscriptionId
            $config.HubSubscriptionId | Should -Be $global:MLZValidationTestState.SubscriptionId
            $config.IdentitySubscriptionId | Should -Be $global:MLZValidationTestState.SubscriptionId
            $config.OperationsSubscriptionId | Should -Be $global:MLZValidationTestState.SubscriptionId
            $config.SharedServicesSubscriptionId | Should -Be $global:MLZValidationTestState.SubscriptionId
            $config.Identifier | Should -Be 'wk123'
            $config.Location | Should -Be 'usgovarizona'
            (Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw) | Should -Not -Match 'credential|do-not-publish'
        }
        finally {
            Remove-Item Env:MLZ_TEST_MARKER -ErrorAction SilentlyContinue
        }
    }

    It 'fails a <Kind> hook and still removes run-owned resources' -TestCases @(
        @{ Kind = 'missing'; Source = $null }
        @{ Kind = 'nonzero'; Source = 'exit 23' }
        @{ Kind = 'throwing'; Source = "throw 'private test failure'" }
    ) {
        param($Kind, $Source)
        $global:MLZValidationTestState.Arguments.TestScriptPath = Join-Path $TestDrive "$Kind.ps1"
        if ($null -ne $Source) { Set-Content $global:MLZValidationTestState.Arguments.TestScriptPath $Source }
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*test*'
        $report = Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw | ConvertFrom-Json
        $report.TestStatus | Should -Be 'Failed'
        $report.CleanupStatus | Should -Be 'Succeeded'
        @($global:MLZValidationTestState.Groups.name) | Should -Be @('bootstrap', 'someone-elses-group')
    }
}
