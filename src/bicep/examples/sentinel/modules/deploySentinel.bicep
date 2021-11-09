
param sentinelSolutionName string 
param logAnalyticsWorkspaceResourceId string


var product = 'OMSGallery/SecurityInsights'
var publisher = 'Microsoft'


resource MicrosoftSentinelSolutionName 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: sentinelSolutionName
  location: resourceGroup().location
  plan: {
    name: sentinelSolutionName
    promotionCode: ''
    product: product
    publisher: publisher
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

