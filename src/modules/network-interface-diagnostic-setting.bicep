/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param delimiter string
param logAnalyticsWorkspaceResourceId string
param logs array
param metrics array
param networkInterfaceResourceId string
param storageAccountResourceIds array
param tiers array
param tokens object

var networkInterfaceDiagnosticSettingName = replace(tiers[tierIndex].namingConvention.virtualMachineNetworkInterfaceDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
var storageAccountResourceId = storageAccountResourceIds[tierIndex]
var tierIndex = contains(networkInterfaceResourceId, '-ops-') ? 1 : contains(networkInterfaceResourceId, '-svcs-') ? 2 : contains(networkInterfaceResourceId, '-id-') ? 3 : 0

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
 name: split(networkInterfaceResourceId, '/')[8]
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: networkInterface
  name: networkInterfaceDiagnosticSettingName
  properties: {
    logs: logs
    metrics: metrics
    storageAccountId: storageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
