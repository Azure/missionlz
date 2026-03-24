targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param logAnalyticsWorkspaceResourceId string
param mlzTags object
param tags object
param tier object
param tokens object

var azureActivityWorkbookName = 'Azure Activity'
var azureServiceHealthWorkbookName = 'Azure Service Health Workbook'
var deployAnalyticRules = true
var enableAzureActivityDataConnector = true
var enableEntraIdDataConnector = true
var entraAuditWorkbookName = 'Microsoft Entra ID Audit logs'
var entraSigninWorkbookName = 'Microsoft Entra ID Sign-in logs'
var logAnalyticsWorkspaceName = split(logAnalyticsWorkspaceResourceId, '/')[8]
var purpose = 'sentinel'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: replace(tier.namingConvention.resourceGroup, tokens.purpose, purpose)
  location: location
  tags: union(tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

module sentinelSettings 'sentinel-settings.bicep' = {
  name: 'configure-sentinel-settings-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    workspaceName: logAnalyticsWorkspaceName
  }
}

module sentinelConnectors 'sentinel-connectors.bicep' = {
  name: 'configure-sentinel-connectors-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    enableAzureActivityConnector: enableAzureActivityDataConnector
    enableEntraIdConnector: enableEntraIdDataConnector
    workspaceName: logAnalyticsWorkspaceName
  }
  dependsOn: [
    sentinelSettings
  ]
}

module sentinelAnalyticRules 'sentinel-analytic-rules.bicep' = if (deployAnalyticRules) {
  name: 'deploy-sentinel-analytic-rules-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
  }
  dependsOn: [
    sentinelSettings
  ]
}

module sentinelContent 'sentinel-content.bicep' = {
  name: 'deploy-sentinel-content-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    azureActivityWorkbookName: azureActivityWorkbookName
    azureServiceHealthWorkbookName: azureServiceHealthWorkbookName
    entraAuditWorkbookName: entraAuditWorkbookName
    entraSigninWorkbookName: entraSigninWorkbookName
  }
}

module sentinelWorkbooks 'sentinel-workbooks.bicep' = {
  name: 'deploy-sentinel-workbooks-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    azureActivityWorkbookName: azureActivityWorkbookName
    azureServiceHealthWorkbookName: azureServiceHealthWorkbookName
    entraAuditWorkbookName: entraAuditWorkbookName
    entraSigninWorkbookName: entraSigninWorkbookName
  }
  dependsOn: [
    sentinelContent
  ]
}
