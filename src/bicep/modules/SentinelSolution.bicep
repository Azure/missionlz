param workspaceName  string
param workspaceLocation string
param tags object = {}
param sentinelBool bool

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: workspaceName
}

resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview'= if(sentinelBool) {
  name: 'SecurityInsights(${workspaceName})'
  location: workspaceLocation
  tags:tags
  dependsOn:[
    workspace
  ]
  properties: {
    workspaceResourceId: workspace.id
  }
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}
