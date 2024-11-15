targetScope = 'subscription'

param avdObjectId string
param deployFslogix bool
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableApplicationInsights bool
param enableAvdInsights bool
param environmentAbbreviation string
param fslogixStorageService string
param locationVirtualMachines string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param mlzTags object
param namingConvention object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param recoveryServices bool
param recoveryServicesGeo string
param resourceAbbreviations object
param resourceGroupControlPlane string
param resourceGroupHosts string
param resourceGroupManagement string
param resourceGroupStorage string
param roleDefinitions object
param serviceToken string
param storageService string
param subnetResourceId string
param subnets array
param tags object
param timeDifference string
param timeZone string
@secure()
param virtualMachinePassword string
param virtualMachineUsername string

var hostPoolName = namingConvention.hostPool
var resourceGroups = union(
  [
    resourceGroupControlPlane
    resourceGroupHosts
    resourceGroupManagement
  ],
  deployFslogix ? [
    resourceGroupStorage
  ] : []
)
var userAssignedIdentityNamePrefix = namingConvention.userAssignedIdentity
var virtualNetworkName = split(subnetResourceId, '/')[8]
var virtualNetworkResourceGroupName = split(subnetResourceId, '/')[4]

module diskAccess 'diskAccess.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'deploy-disk-access-${deploymentNameSuffix}'
  params: {
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    mlzTags: mlzTags
    namingConvention: namingConvention
    resourceGroupControlPlane: resourceGroupControlPlane
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

// Sets an Azure policy to disable public network access to managed disks
module policy 'policy.bicep' = {
  name: 'deploy-policy-disks-${deploymentNameSuffix}'
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
    location: locationVirtualMachines
    resourceGroupName: resourceGroupHosts
  }
}

module deploymentUserAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: replace(userAssignedIdentityNamePrefix, serviceToken, 'deployment')
    tags: union(
      {
        'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
      },
      contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities')
        ? tags['Microsoft.ManagedIdentity/userAssignedIdentities']
        : {},
      mlzTags
    )
  }
}


// Role Assignments: Reader on the resource groups
//Purpose: domain join storage account(s) & set NTFS permissions on the file share(s)
module roleAssignments_deployment '../common/roleAssignments/resourceGroup.bicep' = [
  for i in range(0, length(resourceGroups)): {
    scope: resourceGroup(resourceGroups[i])
    name: 'deploy-role-assignment-${i}-${deploymentNameSuffix}'
    params: {
      principalId: deploymentUserAssignedIdentity.outputs.principalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
    }
  }
]

// Role Assignment: Storage Account Contributor on the storage resource group
// Purpose: domain join storage account(s) & set NTFS permissions on the file share(s)
module roleAssignment_StorageAccountContributor '../common/roleAssignments/resourceGroup.bicep' = {
  scope: resourceGroup(resourceGroupStorage)
  name: 'deploy-role-assignment-${deploymentNameSuffix}'
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  }
}

// Management VM
// The management VM is required to execute PowerShell scripts.
module virtualMachine 'virtualMachine.bicep' = {
  name: 'deploy-mgmt-vm-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: replace(namingConvention.virtualMachineDisk, serviceToken, 'mgt')
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    mlzTags: mlzTags
    networkInterfaceName: replace(namingConvention.virtualMachineNetworkInterface, serviceToken, 'mgt')
    organizationalUnitPath: organizationalUnitPath
    resourceGroupControlPlane: resourceGroupControlPlane
    subnet: split(subnetResourceId, '/')[10]
    tags: tags
    virtualMachineName: replace(namingConvention.virtualMachine, serviceToken, 'mgt')
    virtualMachinePassword: virtualMachinePassword
    virtualMachineUsername: virtualMachineUsername
    virtualNetwork: virtualNetworkName
    virtualNetworkResourceGroup: virtualNetworkResourceGroupName
  }
}

// Role Assignment required for Scaling Plan
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdObjectId, roleDefinitions.DesktopVirtualizationPowerOnOffContributor, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',roleDefinitions.DesktopVirtualizationPowerOnOffContributor)
    principalId: avdObjectId
  }
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableApplicationInsights || enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    namingConvention: namingConvention
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupControlPlane: resourceGroupControlPlane
    serviceToken: serviceToken
    tags: tags
  }
}

// Deploys the Auto Increase Premium File Share Quota solution on an Azure Function App
module functionApp 'functionApp.bicep' = if (deployFslogix && fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-function-app-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    delegatedSubnetResourceId: filter(subnets, subnet => contains(subnet.name, 'FunctionAppOutbound'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolName: hostPoolName
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    namingConvention: namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceAbbreviations: resourceAbbreviations
    resourceGroupControlPlane: resourceGroupControlPlane
    resourceGroupStorage: resourceGroupStorage
    serviceToken: serviceToken
    subnetResourceId: subnetResourceId
    tags: tags
    timeDifference: timeDifference
  }
}

module recoveryServicesVault 'recoveryServicesVault.bicep' = if (recoveryServices) {
  name: 'deploy-rsv-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    azureQueueStoragePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
    deployFslogix: deployFslogix
    hostPoolName: hostPoolName
    location: locationVirtualMachines
    mlzTags: mlzTags
    recoveryServicesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => startsWith(name, 'privatelink.${recoveryServicesGeo}.backup.windowsazure'))[0]}'
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    recoveryServicesVaultNetworkInterfaceName: namingConvention.recoveryServicesVaultNetworkInterface
    recoveryServicesVaultPrivateEndpointName: namingConvention.recoveryServicesVaultPrivateEndpoint
    resourceGroupControlPlane: resourceGroupControlPlane
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
}

output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output functionAppName string = fslogixStorageService == 'AzureFiles Premium' ? functionApp.outputs.functionAppName : ''
output logAnalyticsWorkspaceName string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
output recoveryServicesVaultName string = recoveryServices ? recoveryServicesVault.outputs.name : ''
output virtualMachineName string = virtualMachine.outputs.name
output virtualMachineResourceId string = virtualMachine.outputs.resourceId
