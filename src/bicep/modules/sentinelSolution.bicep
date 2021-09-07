param workspaceName string
param workspaceLocation string
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: workspaceName
}

resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview'= {
  name: 'SecurityInsights(${workspace.name})'
  location: workspaceLocation
  tags:tags
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'SecurityInsights(${workspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}
