param azureFirewallSku string
param deploymentNameSuffix string
param privateDnsZoneNames array
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubscriptionId string
param workloadShortName string

module virtualNetworkLinks '../../../modules/virtual-network-link.bicep' = if (azureFirewallSku == 'Basic')  {
  name: 'deploy-vnet-links-${workloadShortName}-rg-${deploymentNameSuffix}'
  params: {
    privateDnsZoneNames: privateDnsZoneNames
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkSubscriptionId: virtualNetworkSubscriptionId
  }
}
