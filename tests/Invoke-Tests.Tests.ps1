BeforeAll {
    $script:RunnerPath = Join-Path $PSScriptRoot 'Invoke-Tests.ps1'
    $script:CoverageHelperPath = Join-Path $PSScriptRoot 'Get-CoveragePercent.ps1'
}

Describe 'Invoke-Tests process result' {
    It 'exits <ExpectedExit> for <Name>' -TestCases @(
        @{ Name = 'a passing suite'; ExpectedExit = 0; FailureScript = $null }
        @{
            Name = 'a discovery failure alongside passing tests'
            ExpectedExit = 1
            FailureScript = "throw 'Intentional discovery failure'"
        }
        @{
            Name = 'a setup failure alongside passing tests'
            ExpectedExit = 1
            FailureScript = @'
Describe 'Broken setup' {
    BeforeAll { throw 'Intentional setup failure' }
    It 'does not run' { $true | Should -BeTrue }
}
'@
        }
    ) {
        param($Name, $ExpectedExit, $FailureScript)

        $root = Join-Path $TestDrive $Name
        $tests = Join-Path $root 'tests'
        $artifacts = Join-Path $root 'src' 'artifacts'
        New-Item -ItemType Directory -Path $tests, $artifacts -Force | Out-Null
        Copy-Item -Path $script:RunnerPath, $script:CoverageHelperPath -Destination $tests
        Set-Content -Path (Join-Path $artifacts 'Fixture.ps1') -Value "'covered'"
        Set-Content -Path (Join-Path $tests 'Fixture.Tests.ps1') -Value @'
BeforeAll {
    $script:ArtifactPath = Join-Path $PSScriptRoot '..' 'src' 'artifacts' 'Fixture.ps1'
}
Describe 'Fixture artifact' {
    It 'runs the covered script' {
        & $script:ArtifactPath | Should -Be 'covered'
    }
}
'@
        if ($FailureScript) {
            Set-Content -Path (Join-Path $tests 'Failure.Tests.ps1') -Value $FailureScript
        }

        $summaryPath = $env:GITHUB_STEP_SUMMARY
        try {
            $env:GITHUB_STEP_SUMMARY = $null
            & pwsh -NoProfile -File (Join-Path $tests 'Invoke-Tests.ps1') *> $null
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:GITHUB_STEP_SUMMARY = $summaryPath
        }

        [xml]$report = Get-Content -Path (Join-Path $root 'coverage.xml') -Raw
        $lineCounter = $report.report.counter | Where-Object { $_.type -eq 'LINE' }
        [int]$lineCounter.covered | Should -BeGreaterThan 0
        $exitCode | Should -Be $ExpectedExit
    }
}
