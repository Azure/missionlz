# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    . (Join-Path $PSScriptRoot 'Initialize-DeploymentValidationTest.ps1')
    . $script:DeploymentValidationTestGuard
}

Describe 'Deployment validation provisioning' {
    BeforeEach { . $script:DeploymentValidationTestSetup }
    AfterAll { . $script:DeploymentValidationTestCleanup }

    It 'provisions every enabled tier only after capturing ownership' {
        $report = Invoke-DeploymentValidationUnderTest
        $report.DeploymentStatus | Should -Be 'Succeeded'

        $deploymentIndex = 0
        while (($global:MLZValidationTestState.Calls[$deploymentIndex] | Select-Object -First 3) -join ' ' -ne 'deployment sub create') {
            $deploymentIndex++
        }
        $deploymentIndex | Should -BeGreaterThan 4
        $deployment = $global:MLZValidationTestState.Calls[$deploymentIndex]
        $deployment | Should -Contain 'deployDefender=true'
        $deployment | Should -Contain 'deployIdentity=true'
        $deployment | Should -Contain 'location=usgovarizona'
        foreach ($tier in 'hub', 'identity', 'operations', 'sharedServices') {
            $deployment | Should -Contain "${tier}SubscriptionId=$($global:MLZValidationTestState.SubscriptionId)"
        }
        $deployment | Should -Contain '--template-file'
        $deployment | Should -Not -Contain '--no-wait'
        foreach ($call in $global:MLZValidationTestState.Calls) {
            $call | Should -Contain '--subscription'
            (Get-DeploymentValidationTestFlag $call '--subscription') | Should -Be $global:MLZValidationTestState.SubscriptionId
        }
    }
}
