param deploymentNameSuffix string
param enableAvdInsights bool
param hostPoolResourceId string
param location string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param mlzTags object
param namingConvention object
param privateLinkScopeResourceId string
param service string = 'mgmt'
param serviceToken string
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: replace(namingConvention.logAnalyticsWorkspace, serviceToken, service)
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.OperationalInsights/workspaces'] ?? {}, mlzTags)
  properties: {
    sku: {
      name: logAnalyticsWorkspaceSku
    }
    retentionInDays: logAnalyticsWorkspaceRetention
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module privateLinkScope_logAnalyticsWorkspace 'privateLinkScope.bicep' = {
  name: 'deploy-private-link-scope-law-${deploymentNameSuffix}'
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
    privateLinkScopeResourceId: privateLinkScopeResourceId
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = if (enableAvdInsights) {
  name: 'microsoft-avdi-${replace(namingConvention.dataCollectionRule, serviceToken, service)}' // The name must start with 'microsoft-avdi-' for proper integration with AVD Insights
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Insights/dataCollectionRules'] ?? {}, mlzTags)
  kind: 'Windows'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 30
          counterSpecifiers: [
            '\\LogicalDisk(C:)\\Avg. Disk Queue Length'
            '\\LogicalDisk(C:)\\Current Disk Queue Length'
            '\\Memory\\Available Mbytes'
            '\\Memory\\Page Faults/sec'
            '\\Memory\\Pages/sec'
            '\\Memory\\% Committed Bytes In Use'
            '\\PhysicalDisk(*)\\Avg. Disk Queue Length'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Read'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Transfer'
            '\\PhysicalDisk(*)\\Avg. Disk sec/Write'
            '\\Processor Information(_Total)\\% Processor Time'
            '\\User Input Delay per Process(*)\\Max Input Delay'
            '\\User Input Delay per Session(*)\\Max Input Delay'
            '\\RemoteFX Network(*)\\Current TCP RTT'
            '\\RemoteFX Network(*)\\Current UDP Bandwidth'
          ]
          name: 'perfCounterDataSource10'
        }
        {
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\LogicalDisk(C:)\\% Free Space'
            '\\LogicalDisk(C:)\\Avg. Disk sec/Transfer'
            '\\Terminal Services(*)\\Active Sessions'
            '\\Terminal Services(*)\\Inactive Sessions'
            '\\Terminal Services(*)\\Total Sessions'
          ]
          name: 'perfCounterDataSource30'
        }
      ]
      windowsEventLogs: [
        {
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
            'System!*'
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
            'Application!*[System[(Level=2 or Level=3)]]'
            'Microsoft-FSLogix-Apps/Admin!*[System[(Level=2 or Level=3 or Level=4 or Level=0)]]'
          ]
          name: 'eventLogsDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: 'la-workspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
          'Microsoft-Event'
        ]
        destinations: [
          'la-workspace'
        ]
      }
    ]
  }
}

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2021-04-01' = if (enableAvdInsights) {
  name: replace(namingConvention.dataCollectionEndpoint, serviceToken, service)
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Insights/dataCollectionEndpoints'] ?? {}, mlzTags)
  kind: 'Windows'
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Disabled'
    }
  }
}

module privateLinkScope_dataCollectionEndpoint 'privateLinkScope.bicep' = if (enableAvdInsights) {
  name: 'deploy-private-link-scope-dce-${deploymentNameSuffix}'
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  params: {
    dataCollectionEndpointResourceId: dataCollectionEndpoint.id
    privateLinkScopeResourceId: privateLinkScopeResourceId
  }
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
output dataCollectionRuleResourceId string = enableAvdInsights ? dataCollectionRule.id : ''
