param automationAccountName string
param environment string
param fslogixContainerType string
param resourceGroupName string
param runbookName string
param storageAccountName string
param subscriptionId string
param timestamp string = utcNow('yyyyMMddHHmmss')

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' existing = {
  name: automationAccountName
}

resource jobSchedules_ProfileContainers 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = [for i in range(0, 4): {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: guid(timestamp, runbookName, storageAccountName, 'ProfileContainers', string(i))
  properties: {
    parameters: {
      environment: environment
      FileShareName: 'profile-containers'
      resourceGroupName: resourceGroupName
      storageAccountName: storageAccountName
      subscriptionId: subscriptionId
    }
    runbook: {
      name: runbookName
    }
    runOn: null
    schedule: {
      name: '${storageAccountName}_ProfileContainers_${(i + 1) * 15}min'
    }
  }
}]

resource jobSchedules_OfficeContainers 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = [for i in range(0, 4): if (contains(fslogixContainerType, 'Office')) {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: guid(timestamp, runbookName, storageAccountName, 'OfficeContainers', string(i))
  properties: {
    parameters: {
      environment: environment
      FileShareName: 'office-containers'
      resourceGroupName: resourceGroupName
      storageAccountName: storageAccountName
      subscriptionId: subscriptionId
    }
    runbook: {
      name: runbookName
    }
    runOn: null
    schedule: {
      name: '${storageAccountName}_OfficeContainers_${(i + 1) * 15}min'
    }
  }
}]
