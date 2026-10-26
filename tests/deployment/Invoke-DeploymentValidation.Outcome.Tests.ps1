# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    function az { throw 'An Azure CLI call escaped the test mock.' }
}

Describe 'Deployment validation outcomes' {
    BeforeEach {
        Reset-DeploymentValidationTestState -ReportOutputPath (Join-Path $TestDrive 'report.json')
        Mock az { Invoke-DeploymentValidationAzDouble @args }
    }

    AfterAll {
        Remove-DeploymentValidationTestState
        Remove-Item function:az -ErrorAction SilentlyContinue
    }

    It 'keeps deployment, test, and cleanup outcomes distinct after success' {
        $report = Invoke-DeploymentValidationUnderTest
        $report.DeploymentStatus | Should -Be 'Succeeded'
        $report.TestStatus | Should -Be 'Skipped'
        $report.CleanupStatus | Should -Be 'Succeeded'
        $report.OverallStatus | Should -Be 'Succeeded'
        (Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw | ConvertFrom-Json).OverallStatus | Should -Be 'Succeeded'
    }

    It 'retains a deployment failure and withholds private diagnostics' {
        $global:MLZValidationTestState.DeploymentFails = $true
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*deployment*'
        $report = Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw | ConvertFrom-Json
        $report.DeploymentStatus | Should -Be 'Failed'
        $report.TestStatus | Should -Be 'Skipped'
        $report.CleanupStatus | Should -Be 'Succeeded'
        $report.OverallStatus | Should -Be 'Failed'
        (Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw) | Should -Not -Match 'credential|do-not-publish'
    }

    It 'fails the run when cleanup fails after a successful deployment' {
        $global:MLZValidationTestState.CleanupFails = 'group'
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*cleanup*'
        $report = Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw | ConvertFrom-Json
        $report.DeploymentStatus | Should -Be 'Succeeded'
        $report.CleanupStatus | Should -Be 'Failed'
        $report.OverallStatus | Should -Be 'Failed'
    }

    It 'retains both the original deployment error and subsequent cleanup errors' {
        $global:MLZValidationTestState.DeploymentFails = $true
        $global:MLZValidationTestState.CleanupFails = 'group'
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*deployment*cleanup*'
        $report = Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw | ConvertFrom-Json
        $report.DeploymentStatus | Should -Be 'Failed'
        $report.DeploymentError | Should -Not -BeNullOrEmpty
        $report.CleanupStatus | Should -Be 'Failed'
        $report.OverallStatus | Should -Be 'Failed'
    }
}
