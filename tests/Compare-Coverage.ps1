<#
.SYNOPSIS
    Ratchet gate: compare measured coverage against the committed baseline and
    fail on regression. Optionally ratchet the baseline upward.

.DESCRIPTION
    Implements the contract in
    specs/001-test-coverage-ratchet/contracts/ratchet-cli.md.

    Gate mode (default): exit 0 when measured >= baseline (equal is a pass), exit 1
    on regression. If no baseline exists yet, it is initialized from the measured
    value (exit 0). "No coverage data" (missing/unparseable report or zero lines)
    exits 1 and is never treated as a 0% pass.

    Ratchet mode (-UpdateBaseline): raise the baseline to the measured value when
    measured > baseline (exit 0); refuse and exit 1 when measured <= baseline. The
    baseline is never lowered by this script — lowering requires a deliberate,
    reviewable edit to the committed JSON file.

.EXAMPLE
    ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml
.EXAMPLE
    ./tests/Compare-Coverage.ps1 -CoverageReport ./coverage.xml -UpdateBaseline -Note 'ratchet after adding tests'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$CoverageReport,

    [string]$BaselinePath = (Join-Path $PSScriptRoot 'coverage-baseline.json'),

    [switch]$UpdateBaseline,

    [string]$Note = ''
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Get-CoveragePercent.ps1')

$Scope = 'src/artifacts/*.ps1'
$SchemaRef = '../specs/001-test-coverage-ratchet/contracts/coverage-baseline.schema.json'

function Write-Summary([string]$Line) {
    Write-Host $Line
    if ($env:GITHUB_STEP_SUMMARY) {
        "- $Line" | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append
    }
}

function Write-Baseline([double]$Percent, [string]$NoteText) {
    $obj = [ordered]@{
        '$schema'       = $SchemaRef
        coveragePercent = $Percent
        scope           = $Scope
        updated         = (Get-Date).ToString('yyyy-MM-dd')
    }
    if ($NoteText) { $obj['note'] = $NoteText }
    $obj | ConvertTo-Json | Set-Content -Path $BaselinePath
}

# --- Measure -------------------------------------------------------------------
$measured = Get-CoveragePercent -CoverageReport $CoverageReport
if ($null -eq $measured) {
    Write-Summary "FAIL (no data): coverage report missing, unparseable, or zero measurable lines: $CoverageReport"
    exit 1
}

# --- First run: no baseline yet ------------------------------------------------
if (-not (Test-Path -Path $BaselinePath)) {
    $noteText = if ($Note) { $Note } else { 'initial baseline' }
    Write-Baseline -Percent $measured -NoteText $noteText
    Write-Summary "BASELINE-INITIALIZED: wrote $measured% to $BaselinePath"
    exit 0
}

$baseline = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
$baselinePercent = [math]::Round([double]$baseline.coveragePercent, 2)

# --- Ratchet mode --------------------------------------------------------------
if ($UpdateBaseline) {
    if ($measured -gt $baselinePercent) {
        $noteText = if ($Note) { $Note } elseif ($baseline.PSObject.Properties.Name -contains 'note') { $baseline.note } else { '' }
        Write-Baseline -Percent $measured -NoteText $noteText
        Write-Summary "RATCHETED: baseline raised $baselinePercent% -> $measured%"
        exit 0
    }
    Write-Summary "REFUSED: measured $measured% is not above baseline $baselinePercent%; baseline not lowered"
    exit 1
}

# --- Gate mode -----------------------------------------------------------------
if ($measured -ge $baselinePercent) {
    Write-Summary "PASS: coverage $measured% >= baseline $baselinePercent% (scope: $Scope)"
    exit 0
}

Write-Summary "FAIL (regression): coverage $measured% < baseline $baselinePercent%. Add tests to restore coverage."
exit 1
