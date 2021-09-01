param workspaceName  string
param workspaceId string
param location string = resourceGroup().location
param tags object = {}

resource azurerm_log_analytics_solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview'={
  name: 'SecurityInsights(${workspaceName})'
  location: location
  tags:tags
  
  properties: {
    workspaceResourceId: workspaceId
  }
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}
