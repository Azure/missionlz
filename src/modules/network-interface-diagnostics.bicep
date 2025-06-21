param logAnalyticsWorkspaceResourceId string
param logs array
param metrics array
param networkInterfaceResourceId string
param storageAccountResourceIds array
param tiers array

var networkInterfaceDiagnosticSettingName = tiers[tierIndex].namingConvention.virtualMachineNetworkInterfaceDiagnosticSetting
var storageAccountResourceId = storageAccountResourceIds[tierIndex]
var tierIndex = contains(networkInterfaceResourceId, '-ops-') ? 1 : contains(networkInterfaceResourceId, '-svcs-') ? 2 : contains(networkInterfaceResourceId, '-id-') ? 3 : 0

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
 name: split(networkInterfaceResourceId, '/')[8]
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: networkInterface
  name: networkInterfaceDiagnosticSettingName
  properties: {
    logs: logs
    metrics: metrics
    storageAccountId: storageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
