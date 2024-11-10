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


resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2023-09-05' = {
  name: scalingPlanName
  location: location
  tags: tags
  properties: {
    timeZone: timeZone
    hostPoolType: hostPoolType
    exclusionTag: 'Maintenance'
    schedules: hostPoolType == 'Pooled' ? [
      {
        name: 'Weekdays'
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
        name: 'Weekends'
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
        name: 'Weekdays'
        daysOfWeek: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
        ]
        rampUpStartTime: {
          hour: int(split(weekdaysPeakStartTime, ':')[0]) - 1
          minute: split(weekdaysPeakStartTime, ':')[1]
        }
        peakStartTime: {
          hour: split(weekdaysPeakStartTime, ':')[0]
          minute: split(weekdaysPeakStartTime, ':')[1]
        }
        peakMinutesToWaitOnDisconnect: 0
        peakActionOnDisconnect: 'None'
        peakMinutesToWaitOnLogoff: 0
        peakActionOnLogoff: 'Deallocate'
        peakStartVMOnConnect: 'Enable'
        rampDownStartTime: {
          hour: int(split(weekdaysOffPeakStartTime, ':')[0]) - 1
          minute: split(weekdaysOffPeakStartTime, ':')[1]
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
          hour: split(weekdaysOffPeakStartTime, ':')[0]
          minute: split(weekdaysOffPeakStartTime, ':')[1]
        }
        offPeakMinutesToWaitOnDisconnect: 0
        offPeakActionOnDisconnect: 'None'
        offPeakMinutesToWaitOnLogoff: 0
        offPeakActionOnLogoff: 'Deallocate'
        offPeakStartVMOnConnect: 'Enable'
      }
      {
        name: 'Weekends'
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
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPoolResourceId
        scalingPlanEnabled: true
      }
    ]
  }
}

resource scalingPlan_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableAvdInsights && contains(supportedClouds, environment().name)) {
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
}
