param Location string
param UserAssignedIdentityClientId string
param VirtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: VirtualMachineName
}

resource removeVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  parent: virtualMachine
  name: 'RunCommand'
  location: Location
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: true
    parameters: [
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
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
        value: UserAssignedIdentityClientId
      }
      {
        name: 'VirtualMachineName'
        value: VirtualMachineName
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
        Start-Sleep -Seconds 30
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId
        Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -NoWait -Force
      '''
    }
  }
}
