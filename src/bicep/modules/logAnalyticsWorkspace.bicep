param name string
param location string
param tags object = {}
param retentionInDays int = 30
param skuName string = 'PerGB2018'
param workspaceCappingDailyQuotaGb int = -1

@description('Whether or not to deploy Sentinel solution to workspace.')
param deploySentinel bool = false

// Solutions to add to workspace
var solutions = [
  {
    deploy: true
    name: 'AzureActivity'
    product: 'OMSGallery/AzureActivity'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: deploySentinel
    name: 'SecurityInsights'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'VMInsights'
    product: 'OMSGallery/VMInsights'
    publisher: 'Microsoft'
    promotionCode: '' 
  }
  {
    deploy: true
    name: 'Security'
    product: 'OMSGallery/Security'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'ServiceMap'
    publisher: 'Microsoft'
    product: 'OMSGallery/ServiceMap'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'ContainerInsights'
    publisher: 'Microsoft'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'KeyVaultAnalytics'
    publisher: 'Microsoft'
    product: 'OMSGallery/KeyVaultAnalytics'
    promotionCode: ''
  }
]

@description('Enable lock to prevent accidental deletion')
param enableDeleteLock bool = false

var lockName = '${logAnalyticsWorkspace.name}-lock'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku:{
      name: skuName
    }
    workspaceCapping: {
      dailyQuotaGb: workspaceCappingDailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource logAnalyticsSolutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in solutions: if(solution.deploy) {
  name: '${solution.name}(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: '${solution.name}(${logAnalyticsWorkspace.name})'
    product: solution.product
    publisher: solution.publisher
    promotionCode: solution.promotionCode
  }
}]

resource lock 'Microsoft.Authorization/locks@2016-09-01' = if (enableDeleteLock) {
  scope: logAnalyticsWorkspace

  name: lockName
  properties: {
    level: 'CanNotDelete'
  }
}

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
output resourceGroupName string = resourceGroup().name
