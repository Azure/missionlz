# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    $workflowPath = Join-Path $PSScriptRoot '..' '..' '.github' 'workflows' 'deployment-validation.yml'
    $script:Workflow = Get-Content -LiteralPath $workflowPath -Raw -ErrorAction Stop
    $script:WorkflowStep = [regex]::Match(
        $script:Workflow,
        '(?m)^        run: \|\r?\n(?<body>(?:^          .*(?:\r?\n|$)|^\r?\n)+)'
    ).Groups['body'].Value -replace '(?m)^          ', ''
}

Describe 'Deployment validation workflow' {
    It 'schedules weekly validation and allows independent manual execution against main' {
        $script:Workflow | Should -Match "(?m)^    - cron: '0 9 \* \* 1'$"
        $script:Workflow | Should -Match '(?m)^  workflow_dispatch:'
        $script:Workflow | Should -Match '(?m)^          ref: main$'
        $script:Workflow | Should -Match '(?m)^  cancel-in-progress: false$'
        $script:Workflow | Should -Match '(?m)^  group: mlz-allinone-deployment-validation$'
    }

    It 'uses environment-scoped OIDC authentication for Azure Government' {
        $script:Workflow | Should -Match '(?m)^  contents: read$'
        $script:Workflow | Should -Match '(?m)^  id-token: write$'
        $script:Workflow | Should -Match '(?m)^    environment: AllInOne$'
        $script:Workflow | Should -Match 'uses: azure/login@[a-f0-9]{40}'
        $script:Workflow | Should -Match '(?m)^          environment: AzureUSGovernment$'
        $script:Workflow | Should -Match '(?m)^          audience: api://AzureADTokenExchangeUSGov$'
        foreach ($name in @('CLIENT', 'TENANT', 'SUBSCRIPTION')) {
            $script:Workflow | Should -Match "\$\{\{ secrets\.AZURE_${name}_ID \}\}"
        }
        $script:Workflow | Should -Not -Match '(?m)^\s+creds:'
    }

    It 'publishes the sanitized report even when validation fails' {
        $script:Workflow | Should -Match '(?m)^        if: always\(\)$'
        $script:Workflow | Should -Match 'uses: actions/upload-artifact@[a-f0-9]{40}'
        $script:Workflow | Should -Match 'path: \$\{\{ runner.temp \}\}/validation-report.json'
        $script:Workflow | Should -Not -Match '(?m)^\s+continue-on-error:'
    }

    It 'binds dispatch values through environment variables rather than executable expressions' {
        foreach ($name in @('location', 'environment_abbreviation', 'identifier', 'test_script_path')) {
            $script:Workflow | Should -Match "inputs\.$name"
        }
        $script:WorkflowStep | Should -Not -BeNullOrEmpty
        $script:WorkflowStep | Should -Match 'git rev-parse HEAD'
        $script:WorkflowStep | Should -Not -Match '\$\{\{'
    }

    It 'executes the actual workflow step for <Name>' -TestCases @(
        @{ Name = 'scheduled defaults'; Identifier = ''; Hook = ''; Environment = 'dev'; Fail = $false }
        @{ Name = 'manual inputs'; Identifier = 'wk123'; Hook = 'tests/custom hook.ps1'; Environment = 'test'; Fail = $false }
        @{ Name = 'a failing lifecycle'; Identifier = ''; Hook = ''; Environment = 'dev'; Fail = $true }
    ) {
        param($Name, $Identifier, $Hook, $Environment, $Fail)

        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $deploymentPath = Join-Path $root 'tests' 'deployment'
        New-Item -ItemType Directory -Path $deploymentPath -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $deploymentPath 'Invoke-DeploymentValidation.ps1') -Value @'
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$CloudEnvironment,
    [string]$Location,
    [string]$EnvironmentAbbreviation,
    [string]$Identifier,
    [string]$TestScriptPath,
    [string]$ReportOutputPath
)
$PSBoundParameters | ConvertTo-Json | Set-Content -LiteralPath $env:MLZ_WORKFLOW_CAPTURE
if ($env:MLZ_WORKFLOW_FAIL -eq 'true') { throw 'Intentional lifecycle failure' }
'{"OverallStatus":"Succeeded"}' | Set-Content -LiteralPath $ReportOutputPath
'@
        $stepPath = Join-Path $root 'step.ps1'
        Set-Content -LiteralPath $stepPath -Value (
            "function git { `$global:LASTEXITCODE = 0; 'fixture-source-revision' }`n" + $script:WorkflowStep
        )
        $capturePath = Join-Path $root 'parameters.json'
        $summaryPath = Join-Path $root 'summary.md'
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = (Get-Process -Id $PID).Path
        $startInfo.WorkingDirectory = $root
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $stepPath)) {
            $startInfo.ArgumentList.Add($argument)
        }
        $environmentValues = @{
            AZURE_SUBSCRIPTION_ID = '11111111-1111-1111-1111-111111111111'
            MLZ_LOCATION = 'usgovarizona'
            MLZ_ENVIRONMENT_ABBREVIATION = $Environment
            MLZ_IDENTIFIER = $Identifier
            MLZ_TEST_SCRIPT_PATH = $Hook
            MLZ_WORKFLOW_CAPTURE = $capturePath
            MLZ_WORKFLOW_FAIL = $Fail.ToString().ToLowerInvariant()
            RUNNER_TEMP = $root
            GITHUB_STEP_SUMMARY = $summaryPath
        }
        foreach ($entry in $environmentValues.GetEnumerator()) {
            $startInfo.Environment[$entry.Key] = $entry.Value
        }
        $process = [System.Diagnostics.Process]::new()
        try {
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null
            $output = $process.StandardOutput.ReadToEndAsync()
            $errorOutput = $process.StandardError.ReadToEndAsync()
            $process.WaitForExit()
            $output.GetAwaiter().GetResult() | Out-Null
            $errors = $errorOutput.GetAwaiter().GetResult()
            $process.ExitCode | Should -Be $(if ($Fail) { 1 } else { 0 }) -Because $errors
        }
        finally {
            $process.Dispose()
        }

        $parameters = Get-Content -LiteralPath $capturePath -Raw | ConvertFrom-Json -AsHashtable
        $parameters.SubscriptionId | Should -Be $environmentValues.AZURE_SUBSCRIPTION_ID
        $parameters.CloudEnvironment | Should -Be 'AzureUSGovernment'
        $parameters.Location | Should -Be 'usgovarizona'
        $parameters.EnvironmentAbbreviation | Should -Be $Environment
        $parameters.ReportOutputPath | Should -Be (Join-Path $root 'validation-report.json')
        $parameters.ContainsKey('Identifier') | Should -Be ([bool]$Identifier)
        $parameters.ContainsKey('TestScriptPath') | Should -Be ([bool]$Hook)
        if ($Identifier) { $parameters.Identifier | Should -Be $Identifier }
        if ($Hook) { $parameters.TestScriptPath | Should -Be $Hook }
        Get-Content -LiteralPath $summaryPath -Raw | Should -Match 'fixture-source-revision'
    }
}
