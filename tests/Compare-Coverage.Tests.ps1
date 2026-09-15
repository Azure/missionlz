<#
    Contract tests for tests/Compare-Coverage.ps1 (the ratchet gate CLI).

    The gate script exits with process codes, so each case is exercised by invoking
    it in a child pwsh process and asserting on $LASTEXITCODE — this tests the real
    CLI contract without `exit` terminating the Pester host. All fixtures are small
    JaCoCo XML files written under $TestDrive; no network, no real coverage run.

    Covers every row of contracts/ratchet-cli.md.
#>

BeforeAll {
    $script:ComparePath = Join-Path $PSScriptRoot 'Compare-Coverage.ps1'

    function New-JaCoCoReport {
        param([int]$Covered, [int]$Missed, [string]$Path)
        # Report-level LINE counter is what the gate parses.
        $xml = '<?xml version="1.0"?><report name="t">' +
               '<counter type="INSTRUCTION" missed="0" covered="0"/>' +
               "<counter type=`"LINE`" missed=`"$Missed`" covered=`"$Covered`"/>" +
               '</report>'
        Set-Content -Path $Path -Value $xml -NoNewline
    }

    function New-Baseline {
        param([double]$Percent, [string]$Path)
        $obj = [ordered]@{ coveragePercent = $Percent; scope = 'src/artifacts/*.ps1'; updated = '2026-01-01' }
        Set-Content -Path $Path -Value ($obj | ConvertTo-Json)
    }

    function Invoke-Gate {
        param([string]$Report, [string]$Baseline, [switch]$UpdateBaseline, [string]$Note)
        $a = @('-NoProfile', '-File', $ComparePath, '-CoverageReport', $Report, '-BaselinePath', $Baseline)
        if ($UpdateBaseline) { $a += '-UpdateBaseline' }
        if ($Note) { $a += @('-Note', $Note) }
        & pwsh @a *> $null
        return $LASTEXITCODE
    }
}

Describe 'Compare-Coverage ratchet gate' {

    Context 'gate mode' {
        It 'passes (exit 0) when measured coverage is above the baseline' {
            $report = Join-Path $TestDrive 'above.xml';  New-JaCoCoReport -Covered 80 -Missed 20 -Path $report
            $baseline = Join-Path $TestDrive 'b-above.json'; New-Baseline -Percent 50 -Path $baseline
            Invoke-Gate -Report $report -Baseline $baseline | Should -Be 0
        }

        It 'passes (exit 0) when measured coverage exactly equals the baseline (equal is a pass)' {
            $report = Join-Path $TestDrive 'equal.xml';  New-JaCoCoReport -Covered 80 -Missed 20 -Path $report
            $baseline = Join-Path $TestDrive 'b-equal.json'; New-Baseline -Percent 80 -Path $baseline
            Invoke-Gate -Report $report -Baseline $baseline | Should -Be 0
        }

        It 'fails (exit 1) when measured coverage is below the baseline (regression)' {
            $report = Join-Path $TestDrive 'below.xml';  New-JaCoCoReport -Covered 80 -Missed 20 -Path $report
            $baseline = Join-Path $TestDrive 'b-below.json'; New-Baseline -Percent 90 -Path $baseline
            Invoke-Gate -Report $report -Baseline $baseline | Should -Be 1
        }
    }

    Context 'no coverage data (distinct from a 0% pass)' {
        It 'fails (exit 1) when the report has zero measurable lines' {
            $report = Join-Path $TestDrive 'zero.xml';  New-JaCoCoReport -Covered 0 -Missed 0 -Path $report
            $baseline = Join-Path $TestDrive 'b-zero.json'; New-Baseline -Percent 50 -Path $baseline
            Invoke-Gate -Report $report -Baseline $baseline | Should -Be 1
        }

        It 'fails (exit 1) when the report file is missing' {
            $baseline = Join-Path $TestDrive 'b-missing.json'; New-Baseline -Percent 50 -Path $baseline
            Invoke-Gate -Report (Join-Path $TestDrive 'does-not-exist.xml') -Baseline $baseline | Should -Be 1
        }

        It 'fails (exit 1) when the report is unparseable' {
            $report = Join-Path $TestDrive 'bad.xml'; Set-Content -Path $report -Value 'not xml at all'
            $baseline = Join-Path $TestDrive 'b-bad.json'; New-Baseline -Percent 50 -Path $baseline
            Invoke-Gate -Report $report -Baseline $baseline | Should -Be 1
        }
    }

    Context 'first run (no baseline yet)' {
        It 'initializes the baseline from the measured value and passes (exit 0)' {
            $report = Join-Path $TestDrive 'init.xml';  New-JaCoCoReport -Covered 80 -Missed 20 -Path $report
            $baseline = Join-Path $TestDrive 'b-init.json'   # does not exist yet
            $code = Invoke-Gate -Report $report -Baseline $baseline
            $code | Should -Be 0
            Test-Path $baseline | Should -BeTrue
            (Get-Content $baseline -Raw | ConvertFrom-Json).coveragePercent | Should -Be 80
        }
    }

    Context 'ratchet mode (-UpdateBaseline)' {
        It 'raises the baseline and passes (exit 0) when measured is above the baseline' {
            $report = Join-Path $TestDrive 'ratchet.xml'; New-JaCoCoReport -Covered 80 -Missed 20 -Path $report
            $baseline = Join-Path $TestDrive 'b-ratchet.json'; New-Baseline -Percent 50 -Path $baseline
            $code = Invoke-Gate -Report $report -Baseline $baseline -UpdateBaseline -Note 'raise'
            $code | Should -Be 0
            (Get-Content $baseline -Raw | ConvertFrom-Json).coveragePercent | Should -Be 80
        }

        It 'refuses (exit 1) and does not lower the baseline when measured is at or below it' {
            $report = Join-Path $TestDrive 'norais.xml'; New-JaCoCoReport -Covered 80 -Missed 20 -Path $report
            $baseline = Join-Path $TestDrive 'b-norais.json'; New-Baseline -Percent 90 -Path $baseline
            $code = Invoke-Gate -Report $report -Baseline $baseline -UpdateBaseline
            $code | Should -Be 1
            (Get-Content $baseline -Raw | ConvertFrom-Json).coveragePercent | Should -Be 90
        }
    }

    Context 'non-bypassable (SC-005): tests passing but coverage lowered still fails' {
        It 'fails (exit 1) on a lower percentage regardless of test outcome' {
            $report = Join-Path $TestDrive 'drop.xml'; New-JaCoCoReport -Covered 70 -Missed 30 -Path $report
            $baseline = Join-Path $TestDrive 'b-drop.json'; New-Baseline -Percent 80 -Path $baseline
            Invoke-Gate -Report $report -Baseline $baseline | Should -Be 1
        }
    }
}
