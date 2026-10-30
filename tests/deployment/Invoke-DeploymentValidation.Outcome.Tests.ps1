# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    . $script:DeploymentValidationTestGuard
}

Describe 'Deployment validation outcomes' {
    BeforeEach { . $script:DeploymentValidationTestSetup }
    AfterAll { . $script:DeploymentValidationTestCleanup }

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

    It 'does not append fixture validation blocks to an inherited step summary' {
        $summary = Join-Path $TestDrive 'job-summary.md'
        Set-Content -Path $summary -Value 'real-run'
        $before = Get-Content -Path $summary -Raw
        $saved = $env:GITHUB_STEP_SUMMARY
        try {
            $env:GITHUB_STEP_SUMMARY = $summary
            Invoke-DeploymentValidationUnderTest | Out-Null
        }
        finally {
            $env:GITHUB_STEP_SUMMARY = $saved
        }
        Get-Content -Path $summary -Raw | Should -Be $before
    }

    It 'still appends the validation block when the step summary is set for that invocation' {
        $summary = Join-Path $TestDrive 'direct-summary.md'
        $saved = $env:GITHUB_STEP_SUMMARY
        try {
            $env:GITHUB_STEP_SUMMARY = $summary
            $arguments = $global:MLZValidationTestState.Arguments
            & $global:MLZValidationTestState.LifecyclePath @arguments | Out-Null
        }
        finally {
            $env:GITHUB_STEP_SUMMARY = $saved
        }
        Get-Content -Path $summary -Raw | Should -Match 'MLZ AllInOne validation'
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
