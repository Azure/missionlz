@description('Optional. Enable AVD Insights.')
param enableAvdInsights bool = true

@description('Optional. Exclusion tag to be used for exclusion of VMs from Scaling Plan.')
param exclusionTag string = ''

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

@description('Required. Boolean value indicating whether the host pool is pooled.')
param pooledHostPool bool

@description('Required. Scaling begin peak time in HH:mm format.')
param scalingBeginPeakTime string

@description('Required. Scaling end peak time in HH:mm format.')
param scalingEndPeakTime string

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

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2023-09-05' = {
  name: scalingPlanName
  location: location
  tags: tags
  properties: {
    timeZone: timeZone
    hostPoolType: hostPoolType
    exclusionTag: exclusionTag
    schedules: pooledHostPool ? [
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
          hour: split(scalingEndPeakTime, ':')[0]
          minute: split(scalingEndPeakTime, ':')[1]
        }
        peakLoadBalancingAlgorithm: 'BreadthFirst'
        peakStartTime: {
          hour: split(scalingBeginPeakTime, ':')[0]
          minute: split(scalingBeginPeakTime, ':')[1]
        }
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: false
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 0
        rampDownNotificationMessage: 'Ramping down the AVD session hosts to support low demand.'
        rampDownStartTime: {
          hour: int(split(scalingEndPeakTime, ':')[0]) - 1
          minute: split(scalingEndPeakTime, ':')[1]
        }
        rampDownStopHostsWhen: 'string'
        rampDownWaitTimeMinutes: 0
        rampUpCapacityThresholdPct: 70
        rampUpLoadBalancingAlgorithm: 'BreadthFirst'
        rampUpMinimumHostsPct: 25
        rampUpStartTime: {
          hour: int(split(scalingBeginPeakTime, ':')[0]) - 1
          minute: split(scalingBeginPeakTime, ':')[1]
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
          hour: split(scalingEndPeakTime, ':')[0]
          minute: split(scalingEndPeakTime, ':')[1]
        }
        peakLoadBalancingAlgorithm: 'BreadthFirst'
        peakStartTime: {
          hour: split(scalingBeginPeakTime, ':')[0]
          minute: split(scalingBeginPeakTime, ':')[1]
        }
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: false
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 0
        rampDownNotificationMessage: 'Ramping down the AVD session hosts to support low demand.'
        rampDownStartTime: {
          hour: int(split(scalingEndPeakTime, ':')[0]) - 1
          minute: split(scalingEndPeakTime, ':')[1]
        }
        rampDownStopHostsWhen: 'string'
        rampDownWaitTimeMinutes: 0
        rampUpCapacityThresholdPct: 90
        rampUpLoadBalancingAlgorithm: 'string'
        rampUpMinimumHostsPct: 0
        rampUpStartTime: {
          hour: int(split(scalingBeginPeakTime, ':')[0]) - 1
          minute: split(scalingBeginPeakTime, ':')[1]
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
          hour: int(split(scalingBeginPeakTime, ':')[0]) - 1
          minute: split(scalingBeginPeakTime, ':')[1]
        }
        peakStartTime: {
          hour: split(scalingBeginPeakTime, ':')[0]
          minute: split(scalingBeginPeakTime, ':')[1]
        }
        peakMinutesToWaitOnDisconnect: 0
        peakActionOnDisconnect: 'None'
        peakMinutesToWaitOnLogoff: 0
        peakActionOnLogoff: 'Deallocate'
        peakStartVMOnConnect: 'Enable'
        rampDownStartTime: {
          hour: int(split(scalingEndPeakTime, ':')[0]) - 1
          minute: split(scalingEndPeakTime, ':')[1]
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
          hour: split(scalingEndPeakTime, ':')[0]
          minute: split(scalingEndPeakTime, ':')[1]
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
          hour: int(split(scalingBeginPeakTime, ':')[0]) - 1
          minute: split(scalingBeginPeakTime, ':')[1]
        }
        peakStartTime: {
          hour: split(scalingBeginPeakTime, ':')[0]
          minute: split(scalingBeginPeakTime, ':')[1]
        }
        peakMinutesToWaitOnDisconnect: 0
        peakActionOnDisconnect: 'None'
        peakMinutesToWaitOnLogoff: 0
        peakActionOnLogoff: 'Deallocate'
        peakStartVMOnConnect: 'Enable'
        rampDownStartTime: {
          hour: int(split(scalingEndPeakTime, ':')[0]) - 1
          minute: split(scalingEndPeakTime, ':')[1]
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
          hour: split(scalingEndPeakTime, ':')[0]
          minute: split(scalingEndPeakTime, ':')[1]
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
