param artifactsUri string
param automationAccountName string
param beginPeakTime string
param endPeakTime string
param hostPoolName string
param hostPoolResourceGroupName string
param hybridRunbookWorkerGroupName string
param limitSecondsToForceLogOffUser string
param location string
param managementVirtualMachineName string
param minimumNumberOfRdsh string
param resourceGroupControlPlane string
param resourceGroupHosts string
param sessionThresholdPerCPU string
param tags object
param timeDifference string
param time string = utcNow('u')
param timestamp string
param timeZone string
param userAssignedIdentityClientId string

var roleAssignments = [
  resourceGroupControlPlane
  resourceGroupHosts
]
var runbookFileName = 'Set-HostPoolScaling.ps1'
var scriptFileName = 'Set-AutomationRunbook.ps1'

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: automationAccountName
}

module runbook '../common/customScriptExtensions.bicep' = {
  name: 'Runbook_${timestamp}'
  params: {
    fileUris: [
      '${artifactsUri}${runbookFileName}'
      '${artifactsUri}${scriptFileName}'
    ]
    location: location
    parameters: '-AutomationAccountName ${automationAccountName} -Environment ${environment().name} -ResourceGroupName ${resourceGroup().name} -RunbookFileName ${runbookFileName} -SubscriptionId ${subscription().subscriptionId} -TenantId ${tenant().tenantId} -UserAssignedIdentityClientId ${userAssignedIdentityClientId}'
    scriptFileName: scriptFileName
    tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
}

resource schedules 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  name: '${hostPoolName}_${(i + 1) * 15}min'
  properties: {
    advancedSchedule: {}
    description: null
    expiryTime: null
    frequency: 'Hour'
    interval: 1
    startTime: dateTimeAdd(time, 'PT${(i + 1) * 15}M')
    timeZone: timeZone
  }
}]

resource jobSchedules 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: guid(time, runbookFileName, hostPoolName, string(i))
  properties: {
    parameters: {
      beginPeakTime: beginPeakTime
      endPeakTime: endPeakTime
      EnvironmentName: environment().name
      hostPoolName: hostPoolName
      limitSecondsToForceLogOffUser: limitSecondsToForceLogOffUser
      LogOffMessageBody: 'Your session will be logged off. Please save and close everything.'
      LogOffMessageTitle: 'Machine is about to shutdown.'
      MaintenanceTagName: 'Maintenance'
      minimumNumberOfRdsh: minimumNumberOfRdsh
      ResourceGroupName: hostPoolResourceGroupName
      sessionThresholdPerCPU: sessionThresholdPerCPU
      SubscriptionId: subscription().subscriptionId
      TenantId: subscription().tenantId
      timeDifference: timeDifference
    }
    runbook: {
      name: replace(runbookFileName, '.ps1', '')
    }
    runOn: hybridRunbookWorkerGroupName
    schedule: {
      name: schedules[i].name
    }
  }
  dependsOn: [
    runbook
  ]
}]

// Gives the Automation Account the "Desktop Virtualization Power On Off Contributor" role on the resource groups containing the hosts and host pool
module roleAssignment '../common/roleAssignment.bicep' = [for i in range(0, length(roleAssignments)): {
  name: 'RoleAssignment_${i}_${roleAssignments[i]}'
  scope: resourceGroup(roleAssignments[i])
  params: {
    PrincipalId: automationAccount.identity.principalId
    PrincipalType: 'ServicePrincipal'
    RoleDefinitionId: '40c5ff49-9181-41f8-ae61-143b0e78555e' // Desktop Virtualization Power On Off Contributor
  }
}]
