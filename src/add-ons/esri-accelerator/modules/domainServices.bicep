targetScope = 'subscription'

param deploymentNameSuffix string
param domainName string
param location string
param resourceGroupName string
param subnetResourceId string

module domainServices '../../active-directory-domain-services/paas/solution.bicep' = {
  name: 'domain-services-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    domainName: domainName
    location: location
    subnetResourceId: subnetResourceId
  }
}
