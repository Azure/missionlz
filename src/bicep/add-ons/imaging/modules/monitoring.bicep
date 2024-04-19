/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param actionGroupName string
param automationAccountName string
param distributionGroup string
param location string
param logAnalyticsWorkspaceResourceId string
param mlzTags object
param tags object

var alerts = [
  {
    name: 'Zero Trust Image Build - Failure (${automationAccountName})'
    description: 'Sends an error alert when the runbook build fails.'
    severity: 0
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image build failed"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'Zero Trust Image Build - Success (${automationAccountName})'
    description: 'Sends an informational alert when the runbook build succeeds.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image build succeeded"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
]

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: automationAccountName
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  scope: automationAccount
  name: 'diag-${automationAccount.name}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' =
  if (!empty(actionGroupName) && !empty(distributionGroup)) {
    name: actionGroupName
    location: 'global'
    tags: union(
      contains(tags, 'Microsoft.Insights/actionGroups') ? tags['Microsoft.Insights/actionGroups'] : {},
      mlzTags
    )
    properties: {
      emailReceivers: [
        {
          emailAddress: distributionGroup
          name: distributionGroup
          useCommonAlertSchema: true
        }
      ]
      enabled: true
      groupShortName: 'Image Builds'
    }
  }

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = [
  for i in range(0, length(alerts)): if (!empty(actionGroupName) && !empty(logAnalyticsWorkspaceResourceId)) {
    name: alerts[i].name
    location: location
    tags: union(
      contains(tags, 'Microsoft.Insights/scheduledQueryRules') ? tags['Microsoft.Insights/scheduledQueryRules'] : {},
      mlzTags
    )
    kind: 'LogAlert'
    properties: {
      actions: {
        actionGroups: [
          actionGroup.id
        ]
      }
      autoMitigate: false
      skipQueryValidation: false
      criteria: alerts[i].criteria
      description: alerts[i].description
      displayName: alerts[i].name
      enabled: true
      evaluationFrequency: alerts[i].evaluationFrequency
      severity: alerts[i].severity
      windowSize: alerts[i].windowSize
      scopes: [
        logAnalyticsWorkspaceResourceId
      ]
    }
  }
]
