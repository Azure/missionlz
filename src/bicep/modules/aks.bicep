/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param name string
param location string = resourceGroup().location
param tags object = {}

param kubernetesVersion string = '1.21.9'
param aksDnsPrefix string
param aksAgentCount int = 1
param vmSize string = 'Standard_D2_v2'

//Network Profile
@description('This is of the form: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}')
param subnetId string

@description('An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param dnsServiceIp string

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param serviceCidr string

@description('A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param dockerBridgeCidr string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-10-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksDnsPrefix
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: aksAgentCount
        vmSize: vmSize
        vnetSubnetID: subnetId
        osType: 'Linux'
        mode: 'System'
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      dnsServiceIP: dnsServiceIp
      serviceCidr: serviceCidr
      dockerBridgeCidr: dockerBridgeCidr
    }
    kubernetesVersion: kubernetesVersion
  }
}
