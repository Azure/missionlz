@description('Required. Principal ID of the user assigned identity.')
param deploymentUserAssignedIdentityPrincipalId string

@description('Optional. Enable AVD Insights.')
param enableAvdInsights bool = true

@description('Required. Host pool resource ID for the Scaling Plan.')
param hostPoolResourceId string

@description('Required. Location of the Scaling Plan. The location must match the location of the host pool.')
param location string

@description('Optional. Resource ID of the Log Analytics workspace for the Scaling Plan.')
param logAnalyticsWorkspaceResourceId string = ''

@allowed([
  'Personal'
  'Pooled'
])
@description('Required. Host pool type of the Scaling Plan.')
param hostPoolType string

@description('Required. Name of the diagnostic setting for the Scaling Plan.')
param scalingPlanDiagnosticSettingName string

@description('Required. Name of the Scaling Plan.')
param scalingPlanName string

@description('Optional. Supported clouds.')
param supportedClouds array = [
  'AzureCloud'
  'AzureUSGovernment'
]

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Time zone of the Scaling Plan. Defaults to UTC.')
param timeZone string = 'UTC'

@description('Required. Off peak start time for weekdays in HH:mm format.')
param weekdaysOffPeakStartTime string

@description('Required. Off peak start time for weekends in HH:mm format.')
param weekendsOffPeakStartTime string

@description('Required. Peak start time for weekdays in HH:mm format.')
param weekdaysPeakStartTime string

@description('Required. Peak start time for weekends in HH:mm format.')
param weekendsPeakStartTime string

var schedules = hostPoolType == 'Pooled' ? [
  {
    daysOfWeek: [
      'Monday'
      'Tuesday'
      'Wednesday'
      'Thursday'
      'Friday'
    ]
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
    offPeakStartTime: {
      hour: split(weekdaysOffPeakStartTime, ':')[0]
      minute: split(weekdaysOffPeakStartTime, ':')[1]
    }
    peakLoadBalancingAlgorithm: 'BreadthFirst'
    peakStartTime: {
      hour: split(weekdaysPeakStartTime, ':')[0]
      minute: split(weekdaysPeakStartTime, ':')[1]
    }
    rampDownCapacityThresholdPct: 90
    rampDownForceLogoffUsers: false
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 0
    rampDownNotificationMessage: 'Ramping down the AVD session hosts to support low demand.'
    rampDownStartTime: {
      hour: int(split(weekdaysOffPeakStartTime, ':')[0]) - 1
      minute: split(weekdaysOffPeakStartTime, ':')[1]
    }
    rampDownStopHostsWhen: 'ZeroSessions'
    rampDownWaitTimeMinutes: 0
    rampUpCapacityThresholdPct: 70
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 25
    rampUpStartTime: {
      hour: int(split(weekdaysPeakStartTime, ':')[0]) - 1
      minute: split(weekdaysPeakStartTime, ':')[1]
    }
  }
  {
    daysOfWeek: [
      'Saturday'
      'Sunday'
    ]
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
    offPeakStartTime: {
      hour: split(weekendsOffPeakStartTime, ':')[0]
      minute: split(weekendsOffPeakStartTime, ':')[1]
    }
    peakLoadBalancingAlgorithm: 'BreadthFirst'
    peakStartTime: {
      hour: split(weekendsPeakStartTime, ':')[0]
      minute: split(weekendsPeakStartTime, ':')[1]
    }
    rampDownCapacityThresholdPct: 90
    rampDownForceLogoffUsers: false
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 0
    rampDownNotificationMessage: 'Ramping down the AVD session hosts to support low demand.'
    rampDownStartTime: {
      hour: int(split(weekendsOffPeakStartTime, ':')[0]) - 1
      minute: split(weekendsOffPeakStartTime, ':')[1]
    }
    rampDownStopHostsWhen: 'ZeroSessions'
    rampDownWaitTimeMinutes: 0
    rampUpCapacityThresholdPct: 90
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 25
    rampUpStartTime: {
      hour: int(split(weekendsPeakStartTime, ':')[0]) - 1
      minute: split(weekendsPeakStartTime, ':')[1]
    }
  }
] : [
  {
    daysOfWeek: [
      'Monday'
      'Tuesday'
      'Wednesday'
      'Thursday'
      'Friday'
    ]
    offPeakActionOnDisconnect: 'None'
    offPeakActionOnLogoff: 'Deallocate'
    offPeakMinutesToWaitOnDisconnect: 0
    offPeakMinutesToWaitOnLogoff: 0
    offPeakStartTime: {
      hour: split(weekdaysOffPeakStartTime, ':')[0]
      minute: split(weekdaysOffPeakStartTime, ':')[1]
    }
    offPeakStartVMOnConnect: 'Enable'
    peakActionOnDisconnect: 'None'
    peakActionOnLogoff: 'Deallocate'
    peakMinutesToWaitOnDisconnect: 0
    peakMinutesToWaitOnLogoff: 0
    peakStartTime: {
      hour: split(weekdaysPeakStartTime, ':')[0]
      minute: split(weekdaysPeakStartTime, ':')[1]
    }
    peakStartVMOnConnect: 'Enable'
    rampDownActionOnDisconnect: 'None'
    rampDownActionOnLogoff: 'Deallocate'
    rampDownMinutesToWaitOnDisconnect: 0
    rampDownMinutesToWaitOnLogoff: 0
    rampDownStartTime: {
      hour: int(split(weekdaysOffPeakStartTime, ':')[0]) - 1
      minute: split(weekdaysOffPeakStartTime, ':')[1]
    }
    rampDownStartVMOnConnect: 'Enable'
    rampUpActionOnDisconnect: 'None'
    rampUpActionOnLogoff: 'None'
    rampUpAutoStartHosts: 'WithAssignedUser'
    rampUpMinutesToWaitOnDisconnect: 0
    rampUpMinutesToWaitOnLogoff: 0
    rampUpStartTime: {
      hour: int(split(weekdaysPeakStartTime, ':')[0]) - 1
      minute: split(weekdaysPeakStartTime, ':')[1]
    }
    rampUpStartVMOnConnect: 'Enable'
  }
  {
    daysOfWeek: [
      'Saturday'
      'Sunday'
    ]
    rampUpStartTime: {
      hour: int(split(weekendsPeakStartTime, ':')[0]) - 1
      minute: split(weekendsPeakStartTime, ':')[1]
    }
    peakStartTime: {
      hour: split(weekendsPeakStartTime, ':')[0]
      minute: split(weekendsPeakStartTime, ':')[1]
    }
    peakMinutesToWaitOnDisconnect: 0
    peakActionOnDisconnect: 'None'
    peakMinutesToWaitOnLogoff: 0
    peakActionOnLogoff: 'Deallocate'
    peakStartVMOnConnect: 'Enable'
    rampDownStartTime: {
      hour: int(split(weekendsOffPeakStartTime, ':')[0]) - 1
      minute: split(weekendsOffPeakStartTime, ':')[1]
    }
    rampDownMinutesToWaitOnDisconnect: 0
    rampDownActionOnDisconnect: 'None'
    rampDownMinutesToWaitOnLogoff: 0
    rampDownActionOnLogoff: 'Deallocate'
    rampDownStartVMOnConnect: 'Enable'
    rampUpAutoStartHosts: 'WithAssignedUser'
    rampUpStartVMOnConnect: 'Enable'
    rampUpMinutesToWaitOnDisconnect: 0
    rampUpActionOnDisconnect: 'None'
    rampUpMinutesToWaitOnLogoff: 0
    rampUpActionOnLogoff: 'None'
    offPeakStartTime: {
      hour: split(weekendsOffPeakStartTime, ':')[0]
      minute: split(weekendsOffPeakStartTime, ':')[1]
    }
    offPeakMinutesToWaitOnDisconnect: 0
    offPeakActionOnDisconnect: 'None'
    offPeakMinutesToWaitOnLogoff: 0
    offPeakActionOnLogoff: 'Deallocate'
    offPeakStartVMOnConnect: 'Enable'
  }
]

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2023-09-05' = {
  name: scalingPlanName
  location: location
  tags: tags
  properties: {
    timeZone: timeZone
    hostPoolType: hostPoolType
    exclusionTag: 'excludeFromAutoscale'
    schedules: []
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPoolResourceId
        scalingPlanEnabled: true
      }
    ]
  }
}

resource schedules_Pooled 'Microsoft.DesktopVirtualization/scalingPlans/pooledSchedules@2023-09-05' = [for i in range(0, length(schedules)): if (hostPoolType == 'Pooled') {
  name: i == 0 ? 'Weekdays' : 'Weekends'
  parent: scalingPlan
  properties: schedules[i]
}]

resource schedule_Personal 'Microsoft.DesktopVirtualization/scalingPlans/personalSchedules@2023-09-05' = [for i in range(0, length(schedules)): if (hostPoolType == 'Personal') {
  name: i == 0 ? 'Weekdays' : 'Weekends'
  parent: scalingPlan
  properties: schedules[i]
}]

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(deploymentUserAssignedIdentityPrincipalId, '082f0a83-3be5-4ba1-904c-961cca79b387', scalingPlan.id)
  scope: scalingPlan
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '082f0a83-3be5-4ba1-904c-961cca79b387') // Desktop Virtualization Contributor (Purpose: disable scaling plan when adding new hosts)
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    schedule_Personal
    schedules_Pooled
  ]
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableAvdInsights && contains(supportedClouds, environment().name)) {
  name: scalingPlanDiagnosticSettingName
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ] 
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: scalingPlan
  dependsOn: [
    roleAssignment
  ]
}
