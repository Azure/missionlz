param svcPlanName string
param svcPlanNameID string
param location string

@description('The minimum capacity.  Autoscale engine will ensure the instance count is at least this value.')
param minimumCapacity int = 2

@description('The maximum capacity.  Autoscale engine will ensure the instance count is not greater than this value.')
param maximumCapacity int = 10

@description('The default capacity.  Autoscale engine will preventively set the instance count to be this value if it can not find any metric data.')
param defaultCapacity int = 2

@description('The metric name.')
param metricName string = 'CpuPercentage'

@description('The metric upper threshold.  If the metric value is above this threshold then autoscale engine will initiate scale out action.')
param metricThresholdToScaleOut int = 70

@description('The metric lower threshold.  If the metric value is below this threshold then autoscale engine will initiate scale in action.')
param metricThresholdToScaleIn int = 30

@description('The percentage to increase the instance count when autoscale engine is initiating scale out action.')
param changePercentScaleOut int = 20

@description('The percentage to decrease the instance count when autoscale engine is initiating scale in action.')
param changePercentScaleIn int = 10

@description('A boolean to indicate whether the autoscale policy is enabled or disabled.')
param autoscaleEnabled bool = true

var settingName_var = '${toLower(svcPlanName)}-setting'
var targetResourceId = svcPlanNameID

resource settingName 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: settingName_var
  location: location
  properties: {
    profiles: [
      {
        name: 'DefaultAutoscaleProfile'
        capacity: {
          minimum: string(minimumCapacity)
          maximum: string(maximumCapacity)
          default: string(defaultCapacity)
        }
        rules: [
          {
            metricTrigger: {
              metricName: metricName
              metricResourceUri: targetResourceId
              timeGrain: 'PT5M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: metricThresholdToScaleOut
            }
            scaleAction: {
              direction: 'Increase'
              type: 'PercentChangeCount'
              value: string(changePercentScaleOut)
              cooldown: 'PT20M'
            }
          }
          {
            metricTrigger: {
              metricName: metricName
              metricResourceUri: targetResourceId
              timeGrain: 'PT5M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: metricThresholdToScaleIn
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'PercentChangeCount'
              value: string(changePercentScaleIn)
              cooldown: 'PT20M'
            }
          }
        ]
      }
    ]
    enabled: autoscaleEnabled
    targetResourceUri: targetResourceId
  }
}
