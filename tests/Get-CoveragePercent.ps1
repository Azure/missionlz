<#
.SYNOPSIS
    Returns the line-coverage percentage from a Pester JaCoCo XML report.

.DESCRIPTION
    Single source of truth for "the coverage number" across Mission Landing Zone:
    both tests/Invoke-Tests.ps1 (display) and tests/Compare-Coverage.ps1 (the gate)
    dot-source this helper so the local display, the CI number, and the enforced
    baseline are always computed identically from the report-level JaCoCo LINE
    counter (covered / (covered + missed)).

    Returns $null to signal "no coverage data" (missing file, unparseable XML, no
    LINE counter, or zero measurable lines) so callers can treat it distinctly from
    a legitimate 0% (FR-017).
#>
function Get-CoveragePercent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CoverageReport
    )

    if (-not (Test-Path -Path $CoverageReport)) { return $null }

    try {
        [xml]$xml = Get-Content -Path $CoverageReport -Raw
    }
    catch {
        return $null
    }

    $lineCounter = @($xml.report.counter) | Where-Object { $_.type -eq 'LINE' } | Select-Object -First 1
    if (-not $lineCounter) { return $null }

    $covered = [int]$lineCounter.covered
    $missed = [int]$lineCounter.missed
    $total = $covered + $missed
    if ($total -le 0) { return $null }

    return [math]::Round(($covered / $total) * 100, 2)
}
