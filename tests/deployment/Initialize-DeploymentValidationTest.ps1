# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function Get-DeploymentValidationTestFlag {
    param([object[]]$Arguments, [string]$Name)
    $index = [array]::IndexOf($Arguments, $Name)
    if ($index -lt 0) { throw "Missing CLI argument: $Name" }
    $Arguments[$index + 1]
}

function Reset-DeploymentValidationTestState {
    param([Parameter(Mandatory)][string]$ReportOutputPath)

    $subscriptionId = '11111111-1111-1111-1111-111111111111'
    $scope = "/subscriptions/$subscriptionId"
    $global:MLZValidationTestState = @{
        LifecyclePath = Join-Path $PSScriptRoot 'Invoke-DeploymentValidation.ps1'
        SubscriptionId = $subscriptionId
        Scope = $scope
        PolicyName = 'Microsoft Cloud Security Benchmark'
        Calls = [System.Collections.Generic.List[object]]::new()
        Groups = @(@{ name = 'bootstrap'; tags = @{} })
        Policies = @(@{
            id = "$scope/providers/Microsoft.Authorization/policyAssignments/bootstrap-policy"
            name = 'bootstrap-policy'
            properties = @{ displayName = 'Keep this policy' }
        })
        Contacts = @(@{ name = 'bootstrap-contact'; properties = @{ emails = 'bootstrap@example.invalid' } })
        Pricings = @(
            @{ name = 'VirtualMachines'; properties = @{ pricingTier = 'Free' } }
            @{ name = 'StorageAccounts'; properties = @{ pricingTier = 'Standard'; subPlan = 'DefenderForStorageV2' } }
        )
        DeploymentFails = $false
        CleanupFails = ''
        BaselineFails = $false
        AccountCloud = 'AzureUSGovernment'
        Arguments = @{
            SubscriptionId = $subscriptionId
            Identifier = 'wk123'
            ReportOutputPath = $ReportOutputPath
            PassThru = $true
        }
    }
}

function Invoke-DeploymentValidationUnderTest {
    $arguments = $global:MLZValidationTestState.Arguments
    & $global:MLZValidationTestState.LifecyclePath @arguments
}

function Invoke-DeploymentValidationAzDouble {
    $state = $global:MLZValidationTestState
    $command = @($args)
    $state.Calls.Add($command)
    $global:LASTEXITCODE = 0
    $verb = ($command | Select-Object -First 3) -join ' '

    if ($verb -like 'account show *') {
        return (@{
            id = Get-DeploymentValidationTestFlag $command '--subscription'
            environmentName = $state.AccountCloud
            state = 'Enabled'
        } | ConvertTo-Json -Depth 20)
    }
    if ($verb -like 'group list *') {
        if ($state.BaselineFails) {
            $global:LASTEXITCODE = 7
            return 'private diagnostic: credential=do-not-publish'
        }
        return ConvertTo-Json -InputObject @($state.Groups) -Depth 20
    }
    if ($verb -eq 'deployment sub create') {
        $state.Groups += @(
            @{ name = 'rg-wk123-hub'; tags = @{ identifier = 'wk123' } }
            @{ name = 'nonstandard-run-group'; tags = @{ identifier = 'wk123' } }
            @{ name = 'someone-elses-group'; tags = @{ identifier = 'other' } }
        )
        $state.Policies = @($state.Policies | Where-Object name -NE $state.PolicyName) + @(
            @{
                id = "$($state.Scope)/providers/Microsoft.Authorization/policyAssignments/$($state.PolicyName)"
                name = $state.PolicyName
                properties = @{ displayName = 'Defender Default' }
            }
            @{
                id = "$($state.Scope)/providers/Microsoft.Authorization/policyAssignments/unrelated-new-policy"
                name = 'unrelated-new-policy'
                properties = @{}
            }
        )
        $state.Contacts += @{ name = 'default'; properties = @{ emails = 'run@example.invalid' } }
        $state.Pricings[0].properties = @{ pricingTier = 'Standard'; subPlan = 'P1' }
        if ($state.DeploymentFails) {
            $global:LASTEXITCODE = 9
            return 'private deployment diagnostic: credential=do-not-publish'
        }
        return '{"properties":{"provisioningState":"Succeeded"}}'
    }
    if ($verb -like 'group delete *') {
        $name = Get-DeploymentValidationTestFlag $command '--name'
        if ($state.CleanupFails -eq 'group') {
            $global:LASTEXITCODE = 5
            return 'private group diagnostic'
        }
        $state.Groups = @($state.Groups | Where-Object name -NE $name)
        return
    }
    if ($verb -eq 'policy assignment delete') {
        if ($state.CleanupFails -eq 'policy') {
            $global:LASTEXITCODE = 5
            return 'private policy diagnostic'
        }
        $name = Get-DeploymentValidationTestFlag $command '--name'
        $state.Policies = @($state.Policies | Where-Object name -NE $name)
        return
    }
    if ($verb -eq 'security contact delete') {
        if ($state.CleanupFails -eq 'contact') {
            $global:LASTEXITCODE = 5
            return 'private contact diagnostic'
        }
        $name = Get-DeploymentValidationTestFlag $command '--name'
        $state.Contacts = @($state.Contacts | Where-Object name -NE $name)
        return
    }
    if ($verb -eq 'security pricing create') {
        if ($state.CleanupFails -eq 'pricing') {
            $global:LASTEXITCODE = 5
            return 'private pricing diagnostic'
        }
        $name = Get-DeploymentValidationTestFlag $command '--name'
        ($state.Pricings | Where-Object name -EQ $name).properties.pricingTier = Get-DeploymentValidationTestFlag $command '--tier'
        return '{}'
    }
    if ($verb -like 'rest --method *') {
        $method = Get-DeploymentValidationTestFlag $command '--method'
        $url = Get-DeploymentValidationTestFlag $command '--url'
        if ($url -like '*policyAssignments*') { $items = $state.Policies }
        elseif ($url -like '*securityContacts*') { $items = $state.Contacts }
        elseif ($url -like '*pricings*') { $items = $state.Pricings }
        else { throw "Unexpected REST URL: $url" }

        if ($method -eq 'get') {
            return ConvertTo-Json -InputObject @{ value = @($items) } -Depth 30
        }
        if ($method -eq 'put') {
            $body = (Get-DeploymentValidationTestFlag $command '--body') | ConvertFrom-Json -AsHashtable
            $item = $items | Where-Object { $url -like "*/$([uri]::EscapeDataString($_.name))`?*" }
            if (-not $item) { throw 'Restore did not identify a baseline resource.' }
            $item.properties = $body.properties
            return '{}'
        }
    }
    throw "Unexpected Azure CLI command: $($command -join ' ')"
}

function Remove-DeploymentValidationTestState {
    Remove-Variable MLZValidationTestState -Scope Global -ErrorAction SilentlyContinue
}

# Dot-source these from Pester hooks so Mock and the escaped-call guard stay in the test scope.
$script:DeploymentValidationTestGuard = {
    function az { throw 'An Azure CLI call escaped the test mock.' }
}

$script:DeploymentValidationTestSetup = {
    Reset-DeploymentValidationTestState -ReportOutputPath (Join-Path $TestDrive 'report.json')
    Mock az { Invoke-DeploymentValidationAzDouble @args }
}

$script:DeploymentValidationTestCleanup = {
    Remove-DeploymentValidationTestState
    Remove-Item function:az -ErrorAction SilentlyContinue
}
