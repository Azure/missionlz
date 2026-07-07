<#
.SYNOPSIS
    Local/CI entry point that runs the Pester test suite for Mission Landing Zone
    and measures code coverage over the PowerShell artifacts.

.DESCRIPTION
    Builds a Pester configuration that runs the tests under tests/artifacts and
    measures line coverage over src/artifacts/*.ps1, emitting a JaCoCo XML report
    (coverage.xml at the repository root) and printing a single line-coverage
    percentage. In CI the percentage is also appended to the GitHub step summary.

    Pinned tool versions (must match .github/workflows and docs/testing.md for
    local/CI parity):
      - Pester           6.0.0   (JaCoCo is the default coverage format in v6)
      - PSRule.Rules.Azure 1.x   (used by the separate PSRule workflow, not here)

    Install locally with:
      Install-Module Pester -RequiredVersion 6.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
#>

[CmdletBinding()]
param(
    # Path where the JaCoCo coverage report is written (repo-root coverage.xml by default).
    [string]$CoverageOutputPath
)

# NOTE: deliberately do NOT Set-StrictMode here. The harness invokes the artifact
# scripts as-is (via &), and strict mode would leak into them and change their
# runtime behavior (e.g. property access on an empty pipeline result), producing
# false failures for scripts that were never written to run under strict mode.
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$TestsPath = Join-Path $PSScriptRoot 'artifacts'
$CoverageScope = Join-Path $RepoRoot 'src' 'artifacts' '*.ps1'
if (-not $CoverageOutputPath) {
    $CoverageOutputPath = Join-Path $RepoRoot 'coverage.xml'
}

Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

$config = New-PesterConfiguration
$config.Run.Path = $TestsPath
$config.Run.PassThru = $true
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = $CoverageScope
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = $CoverageOutputPath
$config.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $config

$coveragePercent = if ($result.CodeCoverage) {
    [math]::Round([double]$result.CodeCoverage.CoveragePercent, 2)
} else {
    0
}

Write-Host ""
Write-Host "Coverage: $coveragePercent% (scope: src/artifacts/*.ps1)"
Write-Host "Report:   $CoverageOutputPath"

if ($env:GITHUB_STEP_SUMMARY) {
    "### PowerShell artifact coverage" | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
    "" | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
    "**$coveragePercent%** line coverage over ``src/artifacts/*.ps1`` ($($result.PassedCount) passed, $($result.FailedCount) failed)." |
        Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
}

if ($result.FailedCount -gt 0) {
    exit 1
}
