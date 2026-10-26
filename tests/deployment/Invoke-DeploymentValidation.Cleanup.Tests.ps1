# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    function az { throw 'An Azure CLI call escaped the test mock.' }
}

Describe 'Deployment validation cleanup' {
    BeforeEach {
        Reset-DeploymentValidationTestState -ReportOutputPath (Join-Path $TestDrive 'report.json')
        Mock az { Invoke-DeploymentValidationAzDouble @args }
    }

    AfterAll {
        Remove-DeploymentValidationTestState
        Remove-Item function:az -ErrorAction SilentlyContinue
    }

    It 'removes only run-owned resources and resets only Defender plans the run changed' {
        $report = Invoke-DeploymentValidationUnderTest
        $report.CleanupStatus | Should -Be 'Succeeded'
        @($global:MLZValidationTestState.Groups.name) | Should -Be @('bootstrap', 'someone-elses-group')
        @($global:MLZValidationTestState.Policies.name) | Should -Be @('bootstrap-policy', 'unrelated-new-policy')
        @($global:MLZValidationTestState.Contacts.name) | Should -Be @('bootstrap-contact')
        $global:MLZValidationTestState.Pricings[0].properties.pricingTier | Should -Be 'Free'
        $global:MLZValidationTestState.Pricings[1].properties.pricingTier | Should -Be 'Standard'
        $global:MLZValidationTestState.Pricings[1].properties.subPlan | Should -Be 'DefenderForStorageV2'
    }

    It 'removes partial run-owned resources after a deployment failure' {
        $global:MLZValidationTestState.DeploymentFails = $true
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*deployment*'
        @($global:MLZValidationTestState.Groups.name) | Should -Be @('bootstrap', 'someone-elses-group')
    }

    It 'continues cleanup and records a <Kind> cleanup failure' -TestCases @(
        @{ Kind = 'group' }
        @{ Kind = 'policy' }
        @{ Kind = 'contact' }
        @{ Kind = 'pricing' }
    ) {
        param($Kind)
        $global:MLZValidationTestState.CleanupFails = $Kind
        { Invoke-DeploymentValidationUnderTest } | Should -Throw '*cleanup*'
        $report = Get-Content $global:MLZValidationTestState.Arguments.ReportOutputPath -Raw | ConvertFrom-Json
        $report.CleanupStatus | Should -Be 'Failed'
        $report.CleanupSummary.Errors.Count | Should -BeGreaterThan 0
        if ($Kind -ne 'pricing') { $global:MLZValidationTestState.Pricings[0].properties.pricingTier | Should -Be 'Free' }
    }

    It 'restores pre-existing security configuration rather than deleting or downgrading it' {
        $state = $global:MLZValidationTestState
        $state.Policies += @{
            id = "$($state.Scope)/providers/Microsoft.Authorization/policyAssignments/$($state.PolicyName)"
            name = $state.PolicyName
            properties = @{ displayName = 'Existing benchmark'; enforcementMode = 'Default' }
        }
        $state.Pricings[0].properties = @{ pricingTier = 'Standard'; subPlan = 'P2' }
        $report = Invoke-DeploymentValidationUnderTest
        ($state.Policies | Where-Object name -EQ $state.PolicyName).properties.displayName | Should -Be 'Existing benchmark'
        ($state.Policies | Where-Object name -EQ $state.PolicyName).properties.enforcementMode | Should -Be 'Default'
        $state.Pricings[0].properties.pricingTier | Should -Be 'Standard'
        $state.Pricings[0].properties.subPlan | Should -Be 'P2'
        $report.CleanupSummary.DeletedPolicyAssignments | Should -Not -Contain $state.PolicyName
        $report.CleanupSummary.ResetDefenderPlans | Should -Not -Contain 'VirtualMachines'
    }
}
