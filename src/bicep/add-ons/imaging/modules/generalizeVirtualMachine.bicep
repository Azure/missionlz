/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param imageVirtualMachineName string
param resourceGroupName string
param location string = resourceGroup().location
param mlzTags object
param tags object
param userAssignedIdentityClientId string
param virtualMachineName string

resource imageVirtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: imageVirtualMachineName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource generalizeVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  parent: virtualMachine
  name: 'generalizeVirtualMachine'
  location: location
  tags: union(
    contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
    mlzTags
  )
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'ResourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
      {
        name: 'TenantId'
        value: tenant().tenantId
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'VirtualMachineName'
        value: imageVirtualMachine.name
      }
    ]
    source: {
      script: '''
        param(
          [string]$Environment,
          [string]$ResourceGroupName,
          [string]$SubscriptionId,
          [string]$TenantId,
          [string]$UserAssignedIdentityClientId,
          [string]$VirtualMachineName
        )
        $ErrorActionPreference = 'Stop'
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
        $PowerStatus = ''
        while ($PowerStatus -ne 'VM stopped') 
        {
            Start-Sleep -Seconds 5
            $PowerStatus = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Status).Statuses[1].DisplayStatus
        }
        Set-AzVm -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Generalized
        Start-Sleep -Seconds 30
      '''
    }
  }
}
