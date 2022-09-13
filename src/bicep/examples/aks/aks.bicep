/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'
/*

  PARAMETERS

  Here are all the parameters a user can override.

  These are the required parameters that aks bicep does not provide a default for:
    - vnetName
    - subnetName
    - vnetRgName
    - dnsServiceIp
    - serviceCidr
    - dockerBridgeCidr
*/

// REQUIRED PARAMETERS

@minLength(3)
@maxLength(10)
@description('A prefix, 3-10 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string = 'mlz'

@minLength(3)
@maxLength(6)
@description('A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourceSuffix string = 'mlz'

@description('Vnet deployment output variables in json format. It defaults to the vnetDeploymentVariables.json.')
param vnetDeploymentVariables object = json(loadTextContent('./vnetDeploymentVariables.json'))
param vnetName string = vnetDeploymentVariables.virtualNetworkName.value
param subnetName string = vnetDeploymentVariables.subnetName.value
param vnetRgName string = vnetDeploymentVariables.resourceGroupName.value

@description('An IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param dnsServiceIp string

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param serviceCidr string

@description('A CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param dockerBridgeCidr string

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}

@description('Number of agents (VMs) to host docker containers. Allowed values must be in the range of 0 to 1000 (inclusive) for user pools and in the range of 1 to 1000 (inclusive) for system pools. The default value is 1.')
param aksAgentCount int = 1

@minLength(1)
@maxLength(54)
@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN, 1 to 54 characters in length, can contain alphanumerics and hyphens, but should start and end with alphanumeric. This cannot be updated once the Managed Cluster has been created.')
param aksDnsPrefix string = '${resourcePrefix}aks'

@description('AKS cluster kubernetes version.')
param kubernetesVersion string = '1.24.3'

@description('VM size availability varies by region. If a node contains insufficient compute resources (memory, cpu, etc) pods might fail to run correctly. For more details on restricted VM sizes, see: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes')
param vmSize string = 'Standard_D2_v2'

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `resourceSuffix` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

*/
var resourceToken = 'resource_token'
var nameToken = 'name_token'
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'

var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
var aksResourceGroupName = replace(resourceGroupNamingConvention, nameToken, aksName)
var aksName = 'aks'

var defaultTags = {
  'DeploymentType': 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)

module resourceGroup '../../modules/resource-group.bicep' = {
  name: aksResourceGroupName
  params: {
    name: aksResourceGroupName
    location: location
    tags: calculatedTags
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: vnetName
  scope: az.resourceGroup(vnetRgName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

module aks '../../modules/aks.bicep' = {
  name: aksName
  scope: az.resourceGroup(resourceGroup.name)
  params: {
    name: aksName
    tags: calculatedTags
    location: location
    dnsServiceIp: dnsServiceIp
    dockerBridgeCidr: dockerBridgeCidr
    serviceCidr: serviceCidr
    kubernetesVersion: kubernetesVersion
    aksDnsPrefix: aksDnsPrefix
    aksAgentCount: aksAgentCount
    vmSize: vmSize
    subnetId: subnet.id
  }
}
