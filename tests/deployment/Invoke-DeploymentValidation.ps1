# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

<#
.SYNOPSIS
    Deploys core MLZ, optionally tests it, and cleans up run-owned resources.
.DESCRIPTION
    Requires an authenticated Azure CLI session and explicit authorization to
    provision the target subscription. Raw CLI and test-hook output is withheld
    from public logs; the report records sanitized phase outcomes.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,
    [string]$HubSubscriptionId = $SubscriptionId,
    [string]$IdentitySubscriptionId = $SubscriptionId,
    [string]$OperationsSubscriptionId = $SubscriptionId,
    [string]$SharedServicesSubscriptionId = $SubscriptionId,
    [ValidateSet('AzureUSGovernment', 'AzureCloud')]
    [string]$CloudEnvironment = 'AzureUSGovernment',
    [ValidateScript({
        if ([string]::IsNullOrWhiteSpace($_) -or $_ -eq 'usgovvirginia') {
            throw 'AllInOne requires an approved region other than usgovvirginia.'
        }
        $true
    })]
    [string]$Location = 'usgovarizona',
    [ValidatePattern('^[a-z0-9]{1,5}$')]
    [string]$Identifier = ('wk' + [guid]::NewGuid().ToString('N').Substring(0, 3)),
    [ValidateSet('dev', 'prod', 'test')]
    [string]$EnvironmentAbbreviation = 'dev',
    [string]$TemplatePath = (Join-Path $PSScriptRoot '..' '..' 'src' 'mlz.bicep'),
    [bool]$DeployIdentity = $true,
    [ValidateScript({ if (-not $_) { throw 'deployDefender must remain enabled.' }; $true })]
    [bool]$DeployDefender = $true,
    [string]$TestScriptPath = '',
    [string]$ReportOutputPath = '',
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-ValidationAzureCli {
    param([string[]]$Arguments, [string]$Operation, [switch]$DiscardOutput)

    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI $Operation failed (exit $LASTEXITCODE)."
    }
    if (-not $DiscardOutput) {
        try {
            ($output -join "`n") | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        }
        catch {
            throw "Azure CLI $Operation returned invalid JSON."
        }
    }
}

function Get-ValidationSecurityResources {
    param([string]$TargetSubscription, [string]$ResourceType, [string]$ApiVersion)

    $url = "/subscriptions/$TargetSubscription/providers/${ResourceType}?api-version=$ApiVersion"
    while ($url) {
        $page = Invoke-ValidationAzureCli -Operation 'security inventory' -Arguments @(
            'rest', '--method', 'get', '--url', $url, '--subscription', $TargetSubscription
        )
        if ($null -eq $page -or -not $page.Contains('value') -or $null -eq $page.value) {
            throw 'Azure CLI security inventory returned an invalid collection.'
        }
        $page.value
        $url = $page.nextLink
    }
}

function Test-ValidationGroupOwnership {
    param($Group)
    $Group.name -like "rg-$Identifier-*" -or $Group.tags.identifier -eq $Identifier
}

function Invoke-ValidationCleanupAction {
    param([scriptblock]$Action, [string]$FailureMessage)
    try { & $Action }
    catch { $report.CleanupSummary.Errors += $FailureMessage }
}

function Invoke-ValidationGroupCleanup {
    param([string]$TargetSubscription, $Baseline)

    Invoke-ValidationCleanupAction -FailureMessage 'Resource-group inventory or cleanup failed.' -Action {
        $groups = @(Invoke-ValidationAzureCli -Operation 'cleanup resource-group inventory' -Arguments @(
            'group', 'list', '--subscription', $TargetSubscription
        ))
        foreach ($group in $groups) {
            if ($group.name -in $Baseline.ResourceGroupNames) {
                $report.CleanupSummary.PreservedPreExistingItems += $group.name
            }
            elseif (Test-ValidationGroupOwnership $group) {
                Invoke-ValidationCleanupAction -FailureMessage 'A run-owned resource-group deletion failed.' -Action {
                    Invoke-ValidationAzureCli -Operation 'resource-group deletion' -DiscardOutput -Arguments @(
                        'group', 'delete', '--name', $group.name, '--yes', '--subscription', $TargetSubscription
                    )
                    $report.CleanupSummary.DeletedResourceGroups += $group.name
                }
            }
        }
    }
}

function Update-ValidationOwnedSecurityResource {
    param([string]$TargetSubscription, $Type, $Resource, $Original)

    if ($Original) {
        $before = $Original.properties | ConvertTo-Json -Depth 100 -Compress
        $after = $Resource.properties | ConvertTo-Json -Depth 100 -Compress
        if ($before -ne $after -and
            -not ($Type.Kind -eq 'Pricings' -and $Original.properties.pricingTier -eq 'Free')) {
            Restore-ValidationSecurityResource $TargetSubscription $Type.Type $Type.Version $Original
        }
        $report.CleanupSummary.PreservedPreExistingItems += $Original.name
    }
    elseif ($Type.Kind -eq 'Policies') {
        Invoke-ValidationAzureCli -Operation 'policy deletion' -DiscardOutput -Arguments @(
            'policy', 'assignment', 'delete', '--name', $Resource.name,
            '--scope', "/subscriptions/$TargetSubscription", '--subscription', $TargetSubscription
        )
        $report.CleanupSummary.DeletedPolicyAssignments += $Resource.name
    }
    elseif ($Type.Kind -eq 'Contacts') {
        Invoke-ValidationAzureCli -Operation 'security-contact deletion' -DiscardOutput -Arguments @(
            'security', 'contact', 'delete', '--name', $Resource.name, '--yes', '--subscription', $TargetSubscription
        )
        $report.CleanupSummary.DeletedSecurityContacts += $Resource.name
    }
    if ($Type.Kind -eq 'Pricings' -and $Resource.properties.pricingTier -ne 'Free' -and
        (-not $Original -or $Original.properties.pricingTier -eq 'Free')) {
        Invoke-ValidationAzureCli -Operation 'Defender Free reset' -DiscardOutput -Arguments @(
            'security', 'pricing', 'create', '--name', $Resource.name,
            '--tier', 'Free', '--subscription', $TargetSubscription
        )
        $report.CleanupSummary.ResetDefenderPlans += $Resource.name
    }
}

function Invoke-ValidationSecurityCleanup {
    param([string]$TargetSubscription, $Baseline)

    foreach ($type in $securityTypes) {
        Invoke-ValidationCleanupAction -FailureMessage "$($type.Kind) inventory or cleanup failed." -Action {
            $current = @(Get-ValidationSecurityResources $TargetSubscription $type.Type $type.Version)
            foreach ($resource in @($current | Where-Object name -EQ $type.Name)) {
                $original = $Baseline[$type.Kind] | Where-Object name -EQ $resource.name
                Invoke-ValidationCleanupAction -FailureMessage "$($type.Kind) cleanup failed." -Action {
                    Update-ValidationOwnedSecurityResource $TargetSubscription $type $resource $original
                }
            }
        }
    }
}

function Restore-ValidationSecurityResource {
    param([string]$TargetSubscription, [string]$ResourceType, [string]$ApiVersion, $Resource)

    $properties = @{}
    foreach ($key in $Resource.properties.Keys) {
        if ($key -ne 'scope') { $properties[$key] = $Resource.properties[$key] }
    }
    $body = @{ properties = $properties }
    if ($Resource.Contains('location')) { $body.location = $Resource.location }
    if ($Resource.Contains('identity')) {
        $body.identity = @{ type = $Resource.identity.type }
        if ($Resource.identity.userAssignedIdentities) {
            $body.identity.userAssignedIdentities = @{}
            foreach ($id in $Resource.identity.userAssignedIdentities.Keys) {
                $body.identity.userAssignedIdentities[$id] = @{}
            }
        }
    }
    $name = [uri]::EscapeDataString($Resource.name)
    Invoke-ValidationAzureCli -Operation 'baseline security restoration' -DiscardOutput -Arguments @(
        'rest', '--method', 'put',
        '--url', "/subscriptions/$TargetSubscription/providers/$ResourceType/${name}?api-version=$ApiVersion",
        '--body', ($body | ConvertTo-Json -Depth 100 -Compress),
        '--subscription', $TargetSubscription
    )
}

$subscriptions = [ordered]@{
    hub = $HubSubscriptionId
    identity = $IdentitySubscriptionId
    operations = $OperationsSubscriptionId
    sharedServices = $SharedServicesSubscriptionId
}
$report = [ordered]@{
    RunId = "mlz-val-$Identifier-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
    Identifier = $Identifier
    CloudEnvironment = $CloudEnvironment
    Location = $Location
    Subscriptions = $subscriptions
    StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    CompletedAtUtc = $null
    DeploymentStatus = 'NotStarted'
    DeploymentError = $null
    TestStatus = 'Skipped'
    TestError = $null
    CleanupStatus = 'NotRun'
    CleanupSummary = @{
        DeletedResourceGroups = @()
        DeletedPolicyAssignments = @()
        DeletedSecurityContacts = @()
        ResetDefenderPlans = @()
        PreservedPreExistingItems = @()
        Errors = @()
    }
    OverallStatus = 'Failed'
}
$baselines = @{}
$deploymentStarted = $false
$failures = [System.Collections.Generic.List[string]]::new()
$policyName = 'Microsoft Cloud Security Benchmark'
$securityTypes = @(
    @{ Kind = 'Policies'; Type = 'Microsoft.Authorization/policyAssignments'; Version = '2022-06-01'; Name = $policyName }
    @{ Kind = 'Contacts'; Type = 'Microsoft.Security/securityContacts'; Version = '2020-01-01-preview'; Name = 'default' }
    @{ Kind = 'Pricings'; Type = 'Microsoft.Security/pricings'; Version = '2023-01-01'; Name = 'VirtualMachines' }
)

try {
    if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) {
        throw 'The requested Bicep template is missing.'
    }
    $targets = @($SubscriptionId, $HubSubscriptionId, $OperationsSubscriptionId, $SharedServicesSubscriptionId)
    if ($DeployIdentity) { $targets += $IdentitySubscriptionId }
    $targets = @($targets | Sort-Object -Unique)
    foreach ($target in $targets) {
        $parsedId = [guid]::Empty
        if (-not [guid]::TryParse($target, [ref]$parsedId)) {
            throw 'Every enabled tier requires a valid subscription ID.'
        }
        $account = Invoke-ValidationAzureCli -Operation 'account verification' -Arguments @(
            'account', 'show', '--subscription', $target
        )
        if ($account.id -ne $target -or $account.environmentName -ne $CloudEnvironment -or $account.state -ne 'Enabled') {
            throw 'The target account or cloud does not match the approved configuration.'
        }
        $groups = @(Invoke-ValidationAzureCli -Operation 'baseline resource-group inventory' -Arguments @(
            'group', 'list', '--subscription', $target
        ))
        if (@($groups | Where-Object { Test-ValidationGroupOwnership $_ }).Count -gt 0) {
            throw 'The identifier is already used by a pre-existing resource group.'
        }
        $snapshot = @{
            SubscriptionId = $target
            CapturedAtUtc = [DateTime]::UtcNow.ToString('o')
            ResourceGroupNames = @($groups.name)
            PolicyAssignmentNames = @()
            SecurityContactNames = @()
            DefenderPricingTiers = @{}
        }
        foreach ($type in $securityTypes) {
            $items = @(Get-ValidationSecurityResources $target $type.Type $type.Version)
            if ($type.Kind -eq 'Policies') {
                $items = @($items | Where-Object {
                    $_.id -eq "/subscriptions/$target/providers/$($type.Type)/$($_.name)"
                })
            }
            $snapshot[$type.Kind] = $items
        }
        $snapshot.PolicyAssignmentNames = @($snapshot.Policies.name)
        $snapshot.SecurityContactNames = @($snapshot.Contacts.name)
        foreach ($plan in $snapshot.Pricings) {
            $snapshot.DefenderPricingTiers[$plan.name] = $plan.properties.pricingTier
        }
        $baselines[$target] = $snapshot
    }

    $deploymentStarted = $true
    try {
        Invoke-ValidationAzureCli -Operation 'deployment' -DiscardOutput -Arguments @(
            'deployment', 'sub', 'create', '--name', $report.RunId,
            '--location', $Location, '--subscription', $SubscriptionId,
            '--template-file', $TemplatePath, '--parameters',
            "identifier=$Identifier", "location=$Location",
            "environmentAbbreviation=$EnvironmentAbbreviation",
            "hubSubscriptionId=$HubSubscriptionId", "identitySubscriptionId=$IdentitySubscriptionId",
            "operationsSubscriptionId=$OperationsSubscriptionId", "sharedServicesSubscriptionId=$SharedServicesSubscriptionId",
            "deployIdentity=$($DeployIdentity.ToString().ToLowerInvariant())", 'deployDefender=true'
        )
        $report.DeploymentStatus = 'Succeeded'
    }
    catch {
        $report.DeploymentStatus = 'Failed'
        $report.DeploymentError = 'Core MLZ provisioning failed; consult restricted Azure deployment history.'
        $failures.Add('deployment')
    }

    if ($report.DeploymentStatus -eq 'Succeeded' -and $TestScriptPath) {
        $report.TestStatus = 'Failed'
        if (-not (Test-Path -LiteralPath $TestScriptPath -PathType Leaf)) {
            $report.TestError = 'The explicitly requested test script is missing.'
        }
        else {
            $hookArguments = @{
                SubscriptionId = $SubscriptionId
                HubSubscriptionId = $HubSubscriptionId
                IdentitySubscriptionId = $IdentitySubscriptionId
                OperationsSubscriptionId = $OperationsSubscriptionId
                SharedServicesSubscriptionId = $SharedServicesSubscriptionId
                Location = $Location
                Identifier = $Identifier
                EnvironmentAbbreviation = $EnvironmentAbbreviation
            }
            $null = & pwsh -NoLogo -NoProfile -NonInteractive -File $TestScriptPath @hookArguments 2>&1
            if ($LASTEXITCODE -eq 0) { $report.TestStatus = 'Passed' }
            else { $report.TestError = "The test process failed (exit $LASTEXITCODE)." }
        }
        if ($report.TestStatus -eq 'Failed') { $failures.Add('test') }
    }
}
catch {
    # Preflight messages contain no raw Azure output or resource configuration.
    $failures.Add("baseline/configuration: $($_.Exception.Message)")
}
finally {
    if ($deploymentStarted) {
        foreach ($target in $baselines.Keys) {
            Invoke-ValidationGroupCleanup $target $baselines[$target]
            Invoke-ValidationSecurityCleanup $target $baselines[$target]
        }
        $report.CleanupStatus = if ($report.CleanupSummary.Errors.Count) { 'Failed' } else { 'Succeeded' }
        if ($report.CleanupStatus -eq 'Failed') { $failures.Add('cleanup') }
    }
    $report.CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    if ($report.DeploymentStatus -eq 'Succeeded' -and $report.CleanupStatus -eq 'Succeeded' -and
        $report.TestStatus -in @('Passed', 'Skipped') -and $failures.Count -eq 0) {
        $report.OverallStatus = 'Succeeded'
    }
    if ($ReportOutputPath) {
        $report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ReportOutputPath -Encoding utf8
    }
    if ($env:GITHUB_STEP_SUMMARY) {
        @(
            '### MLZ AllInOne validation'
            ''
            "| Phase | Outcome |", '|---|---|'
            "| Deployment | $($report.DeploymentStatus) |"
            "| Tests | $($report.TestStatus) |"
            "| Cleanup | $($report.CleanupStatus) |"
            "| Overall | $($report.OverallStatus) |"
        ) | Out-File -LiteralPath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
    }
}

if ($PassThru) { [pscustomobject]$report }
if ($report.OverallStatus -ne 'Succeeded') {
    throw "Validation failed: $($failures -join '; ')."
}
