param imageVirtualMachineName string
param resourceGroupName string
param location string
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

resource restartVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'restartVirtualMachine'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: virtualMachine
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
        Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName
        $AgentStatus = $Null
        while ($Null -eq $AgentStatus) 
        {
            Start-Sleep -Seconds 5
            $AgentStatus = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Status).VMAgent
        }
      '''
    }
  }
}
