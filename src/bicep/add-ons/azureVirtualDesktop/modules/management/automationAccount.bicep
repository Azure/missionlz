param automationAccountDiagnosticSettingName string
param automationAccountName string
param automationAccountNetworkInterfaceName string
param automationAccountPrivateDnsZoneResourceId string
param automationAccountPrivateEndpointName string
param location string
param logAnalyticsWorkspaceResourceId string
param monitoring bool
param subnetResourceId string
param tags object
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: virtualMachineName
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: automationAccountName
  location: location
  tags: contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: automationAccountPrivateEndpointName
  location: location
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
  properties: {
    customNetworkInterfaceName: automationAccountNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: automationAccountPrivateEndpointName
        properties: {
          privateLinkServiceId: automationAccount.id
          groupIds: [
            'DSCAndHybridWorker'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(split(automationAccountPrivateDnsZoneResourceId, '/')[8], '.', '-')
        properties: {
          privateDnsZoneId: automationAccountPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource hybridRunbookWorkerGroup 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups@2022-08-08' = {
  parent: automationAccount
  name: 'Scaling Tool'
}

resource hybridRunbookWorker 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups/hybridRunbookWorkers@2022-08-08' = {
  parent: hybridRunbookWorkerGroup
  name: guid(hybridRunbookWorkerGroup.id)
  properties: {
    vmResourceId: virtualMachine.id
  }
}

resource extension_HybridWorker 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: virtualMachine
  name: 'HybridWorkerForWindows'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    publisher: 'Microsoft.Azure.Automation.HybridWorker'
    type: 'HybridWorkerForWindows'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AutomationAccountURL: automationAccount.properties.automationHybridServiceUrl
    }
  }
}

// Enables logging in a log analytics workspace for alerting and dashboards
resource diagnosticSetting 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (monitoring) {
  scope: automationAccount
  name: automationAccountDiagnosticSettingName
  properties: {
    logs: [
      {
        category: 'DscNodeStatus'
        enabled: true
      }
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

output hybridRunbookWorkerGroupName string = hybridRunbookWorkerGroup.name
