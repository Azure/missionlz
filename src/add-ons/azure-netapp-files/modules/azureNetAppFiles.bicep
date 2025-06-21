targetScope = 'subscription'

param delegatedSubnetResourceId string
param delimiter string
param deploymentNameSuffix string
param dnsServers string
@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param domainName string
param fileShareName string
param location string
param mlzTags object
param netAppAccountName string
param netAppCapacityPoolName string
param organizationalUnitPath string
param resourceGroupName string
param smbServerName string
param sku string
param tags object 

// Azure NetApp Files
module netAppFiles '../../azure-virtual-desktop/modules/fslogix/azure-netapp-files.bicep' = {
  name: 'deploy-netapp-files-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    delegatedSubnetResourceId: delegatedSubnetResourceId
    delimiter: delimiter
    dnsServers: dnsServers
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    fileShares: [
      fileShareName
    ]
    location: location
    mlzTags: mlzTags
    netAppAccountNamePrefix: netAppAccountName
    netAppCapacityPoolNamePrefix: netAppCapacityPoolName
    organizationalUnitPath: organizationalUnitPath
    smbServerName: smbServerName
    storageSku: sku
    tags: tags
  }
}
