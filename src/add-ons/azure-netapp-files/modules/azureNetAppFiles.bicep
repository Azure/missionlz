targetScope = 'subscription'

param delegatedSubnetResourceId string
param delimiter string
param deploymentNameSuffix string
param dnsServers string
@secure()
param domainAdminPassword string
@secure()
param domainAdminUserPrincipalName string
param domainName string
param environmentAbbreviation string
param fileShareName string
param location string
param mlzTags object
param namingConvention object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param resourceAbbreviations object
param resourceGroupName string
param securityPrincipalNames array
param sku string
param smbServerName string
param subnetResourceId string
param tags object
param tier object
param tokens object
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string


// Azure NetApp Files
module netAppFiles '../../azure-virtual-desktop/modules/fslogix/azure-netapp-files.bicep' = {
  name: 'deploy-netapp-files-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    delegatedSubnetResourceId: delegatedSubnetResourceId
    delimiter: delimiter
    dnsServers: dnsServers
    domainAdminPassword: domainAdminPassword
    domainAdminUserPrincipalName: domainAdminUserPrincipalName
    domainName: domainName
    fileShares: [
      fileShareName
    ]
    location: location
    mlzTags: mlzTags
    netAppAccountNamePrefix: replace(namingConvention.netAppAccount, '${delimiter}${tokens.purpose}', '')
    netAppCapacityPoolNamePrefix: replace(namingConvention.netAppAccountCapacityPool, '${delimiter}${tokens.purpose}', '')
    organizationalUnitPath: organizationalUnitPath
    smbServerName: smbServerName
    storageSku: sku
    tags: tags
  }
}

module deploymentUserAssignedIdentity '../../azure-virtual-desktop/modules/management/user-assigned-identity.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: location
    name: replace(namingConvention.userAssignedIdentity, tokens.purpose, 'deployment')
    tags: union(tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
  }
}

module customerManagedKeys '../../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'vaultcore'))[0]}'
    location: location
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: subnetResourceId
    tags: tags
    tier: tier
    tokens: tokens
    type: 'virtualMachine'
  }
}

module virtualMachine '../../azure-virtual-desktop/modules/management/virtual-machine.bicep' = {
  name: 'deploy-mgmt-vm-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    diskName: replace(namingConvention.virtualMachineDisk, tokens.purpose, 'mgt')
    diskSku: 'Premium_LRS'
    domainJoinPassword: domainAdminPassword
    domainJoinUserPrincipalName: domainAdminUserPrincipalName
    domainName: domainName
    location: location
    mlzTags: mlzTags
    networkInterfaceName: replace(namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'mgt')
    organizationalUnitPath: organizationalUnitPath
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineName: replace(namingConvention.virtualMachine, tokens.purpose, 'mgt')
    virtualMachineSize: virtualMachineSize
  }
}

module ntfsPermissions 'ntfs-permissions.bicep' = {
  name: 'deploy-ntfspermissions-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    domainAdminPassword: domainAdminPassword
    domainAdminUserPrincipalName: domainAdminUserPrincipalName
    location: location
    parameters: [
      {
        name: 'FileShares'
        value: string(netAppFiles.outputs.fileShares[0])
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'SecurityPrincipalNames'
        value: string(securityPrincipalNames)
      }
      {
        name: 'SmbServerNamePrefix'
        value: netAppFiles.outputs.smbServerNamePrefix
      }
      {
        name: 'StorageService'
        value: 'AzureNetAppFiles'
      }
    ]
    resourceGroupName: resourceGroupName
    tags: tags
    virtualMachineName: virtualMachine.outputs.name
  }
}

output fileShare string = netAppFiles.outputs.fileShares[0]
output smbServerNamePrefix string = netAppFiles.outputs.smbServerNamePrefix
