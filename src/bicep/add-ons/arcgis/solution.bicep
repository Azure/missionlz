targetScope = 'subscription'
@secure()
@description('Virtual Machine admin password')
param adminPassword string
@description('Virtual Machine admin username')
param adminUsername string
@description('Application Gateway Private IP Address')
param applicationGatewayPrivateIpAddress string
@description('Application Gateway Subnet Address Prefix')
param applicationGatewaySubnetAddressPrefix string
@description('ArcGIS Service Account Is Domain Account')
param arcgisServiceAccountIsDomainAccount bool
@secure()
@description('ArcGIS Service Account Password')
param arcgisServiceAccountPassword string
@description('ArcGIS Service Account User Name')
param arcgisServiceAccountUserName string
@allowed([
  'singletier'
  'multitier'
])
@description('Architecture for ESRI. Single Tier or Multi Tier.')
param architecture string
@description('Azure Firewall Name')
param azureFirewallName string
// @description('Data Store Types for Base Deployment Servers')
// param dataStoreTypesForBaseDeployment array = []
@description('Data Store Virtual Machine OS Disk Size')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param dataStoreVirtualMachineOSDiskSize int = 128
@description('Debug Mode for ESRI')
param debugMode bool
@description('Default Subnet Address Prefix')
param defaultSubnetAddressPrefix string
@description('Deploy Defender')
param deployDefender bool
@description('Deployment Name Suffix')
param deploymentNameSuffix string = utcNow('yyMMddHHs')
@description('Deploy Policy')
param deployPolicy bool
param diskEncryptionSetResourceId string
@description('Email Security Contact')
param emailSecurityContact string = ''
@description('Enable Data Store Virtual Machine Data Disk')
param enableDataStoreVirtualMachineDataDisk bool = false
@description('Enable Graph Data Store')
param enableGraphDataStore bool
@description('Enable Graph Data Store Virtual Machine Data Disk')
param enableGraphDataStoreVirtualMachineDataDisk bool = false
@description('Enable Monitoring')
param enableMonitoring bool
@description('Enable Object Data Store')
param enableObjectDataStore bool
@description('Enable Object Data Store Virtual Machine Data Disk')
param enableObjectDataStoreVirtualMachineDataDisk bool = false
@description('Enable Server Log Harvester Plugin')
param enableServerLogHarvesterPlugin bool = false
@description('Enable Spatiotemporal Big Data Store')
param enableSpatiotemporalBigDataStore bool
@description('Enable Spatiotemporal Big Data Store Virtual Machine Data Disk')
param enableSpatiotemporalBigDataStoreVirtualMachineDataDisk bool = false
@description('Enable Tile Cache Data Store')
param enableTileCacheDataStore bool
@description('Enable Tile Cache Data Store Virtual Machine Data Disk')
param enableTileCacheDataStoreVirtualMachineDataDisk bool = false
@description('Enable Virtual Machine Data Disk')
param enableVirtualMachineDataDisk bool = false
@description('External DNS Hostname')
param externalDnsHostname string
@description('Graph Data Store Virtual Machine OS Disk Size')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param graphDataStoreVirtualMachineOSDiskSize int = 128
@description('Hub Resource Group Name')
param hubResourceGroupName string
@description('Hub Subscription Id')
param hubSubscriptionId string
@description('Hub Virtual Network Name')
param hubVirtualNetworkName string
@description('Updating Certificates')
param isUpdatingCertificates bool = false
@description('Join Windows Domain')
param joinWindowsDomain bool = false
@description('Location')
param location string = deployment().location
@description('Log Analytics Workspace Name')
param logAnalyticsWorkspaceName string = ''
@description('Number of data store virtual machines')
param numberOfDataStoreVirtualMachines int = 2
@description('Number of Esri servers')
param numberOfEsriServers int = 2
@description('Number of file share virtual machines')
param numberOfEsrispatiotemporalBigDataStoreVirtualMachines int = 3
@description('Number of file share virtual machines')
param numberOfFileShareVirtualMachineNames int = 1
@description('Number of graph data store virtual machines')
param numberOfGraphDataStoreVirtualMachineNames int = 1
@description('Number of object data store virtual machines')
@minValue(1)
param numberOfObjectDataStoreVirtualMachines int = 1 // min value of 3 if clustering
@description('Number of portal virtual machines')
param numberOfPortalVirtualMachines int = 2
@description('Number of tile cache data store virtual machines')
param numberOfTileCacheDataStoreVirtualMachineNames int = 1
@description('Object Data Store Virtual Machine OS Disk Size')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param objectDataStoreVirtualMachineOSDiskSize int = 128
@description('OU Path if using domain join for the virtual machines.')
param ouPath string = ''
@description('Policy')
param policy string = ''
@description('Portal License File')
param portalLicenseFile string
@description('Portal License User Type Id')
@allowed([
  'creatorUT'
  'editorUT'
  'fieldWorkerUT'
  'GISProfessionalAdvUT'
  'GISProfessionalBasicUT'
  'GISProfessionalStdUT'
  'IndoorsUserUT'
  'insightsAnalystUT'
  'viewerUT'
])
param portalLicenseUserTypeId string
@description('Portal Virtual Machine OS Disk Size')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param portalVirtualMachineOSDiskSize int = 128
@secure()
@description('Primary Site Administrator Account Password')
param primarySiteAdministratorAccountPassword string
@description('Primary Site Administrator Account User Name')
param primarySiteAdministratorAccountUserName string
@description('Resource Prefix')
param resourcePrefix string
@description('Secondary Host Name')
param secondaryDnsHostName string = ''
@secure()
@description('Certificate Password')
param selfSignedCertificatePassword string
param serverLicenseFile string
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param spatiotemporalBigDataStoreVirtualMachineOSDiskSize int = 128
param spokelogAnalyticsWorkspaceResourceId string
param tags object = {}
@description('tileCacheDataStoreVirtualMachineOSDiskSize value')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param tileCacheDataStoreVirtualMachineOSDiskSize int = 128
@description('Use cloud storage value')
param useAzureFiles bool
@description('useCloudStorage value')
param useCloudStorage bool
@description('The size of the virtual machine OS disk')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param virtualMachineOSDiskSize int = 128
@description('The size of the virtual machines')
param virtualMachineSize string = 'Standard_DS4_v2'
@description('The virtual network address prefix')
param virtualNetworkAddressPrefix string
@secure()
@description('The password for the Windows domain administrator account.')
param windowsDomainAdministratorPassword string = ''
@description('The username for the Windows domain administrator account.')
param windowsDomainAdministratorUserName string = ''
@description('The name of the Windows domain.')
param windowsDomainName string = ''
@description('The GUID of the workload subscription.')
param workloadSubscriptionId string = ''

@secure()
param certificatePassword string
param certificateFileName string
param artifactsStorageAccountName string
param artifactsContainerName string
param artifactsStorageAccountResourceGroupName string
param artifactsStorageAccountSubscriptionId string

// Resource Naming
var resourceSuffix = resourcePrefix
// var externalDnsHostnamePrefix = resourcePrefix
var applicationGatewayName = 'ag-esri-${resourceSuffix}'
var availabilitySetName = 'avset-esri-${resourceSuffix}'
var container = 'artifacts'
var keyVaultCertificatesOfficer = resourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
var keyVaultName = 'kv-esri-${resourceSuffix}'
var keyVaultSecretsOfficer = resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
var keyVaultCryptoOfficer = resourceId('Microsoft.Authorization/roleDefinitions', '14b46e9e-c2b7-41b4-b07b-48a6ebf60603')
var networkInterfaceName = 'nic-esri-${resourceSuffix}'
var portalContext = 'portal'
var portalLicenseFileName = 'portalLicense.json' //FIX THIS
var privatelink_blob_name = 'privatelink.blob.${environment().suffixes.storage}'
var privatelink_keyvaultDns_name = replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
var privatelink_file_name = 'privatelink.file.${environment().suffixes.storage}'
var publicIpAddressName = 'pip-esri-${resourceSuffix}'
var resourceGroupName = 'rg-esri-enterprise-${resourceSuffix}'
var serverContext = 'server'
var serverLicenseFileName = 'serverLicense.prvc' //FIX THIS
var subscriptionId = subscription().subscriptionId
var userAssignedManagedIdentityName = 'uami-esri-${resourceSuffix}'
var virtualMachineName = 'vm-esri-${resourceSuffix}'

// Virtual Machine Names
var dataStoreVirtualMachineNames = join(dataStoreVirtualMachines, ',')
var dataStoreVirtualMachines = [for i in range(0, numberOfDataStoreVirtualMachines): 'vm-esri-ds-${i}']
var fileShareVirtualMachineName = join(fileShareVirtualMachines, ',')
var fileShareVirtualMachines = [for i in range(0, numberOfFileShareVirtualMachineNames): 'vm-esri-fl-${i}']
var graphDataStoreVirtualMachineNames = join(graphDataStoreVirtualMachines, ',')
var graphDataStoreVirtualMachines = [for i in range(0, numberOfGraphDataStoreVirtualMachineNames): 'vm-esri-gr-${i}']
var objectDataStoreVirtualMachineNames = join(objectDataStoreVirtualMachines, ',')
var objectDataStoreVirtualMachines = [for i in range(0, numberOfObjectDataStoreVirtualMachines): 'vm-esri-od-${i}']
var portalVirtualMachineNames = join(portalVirtualMachines, ',')
var portalVirtualMachines = [for i in range(0, numberOfPortalVirtualMachines): 'vm-esri-pr-${i}']
var serverVirtualMachineNames = join(serverVirtualMachines, ',')
var serverVirtualMachines = [for i in range(0, numberOfEsriServers): 'vm-esri-sv-${i}']
var spatiotemporalBigDataStoreVirtualMachineNames = join(spatiotemporalBigDataStoreVirtualMachines, ',')
var spatiotemporalBigDataStoreVirtualMachines = [for i in range(0, numberOfEsrispatiotemporalBigDataStoreVirtualMachines): 'vm-esri-sp-${i}']
var tileCacheDataStoreVirtualMachineNames = join(tileCacheDataStoreVirtualMachines, ',')
var tileCacheDataStoreVirtualMachines = [for i in range(0, numberOfTileCacheDataStoreVirtualMachineNames): 'vm-esri-tc-${i}']

// DSC Functions
var dscDataStoreFunction = 'DataStoreConfiguration'
var dscGraphDataStoreFunction = 'GraphDataStoreConfiguration'
var dscObjectDataStoreFunction = 'ObjectDataStoreConfiguration'
var dscPortalFunction = 'PortalConfiguration'
var dscServerScriptFunction = 'ServerConfiguration'
var dscSingleTierConfiguration = 'BaseDeploymentSingleTierConfiguration'
var dscsSatiotemporalBigDataStoreFunction = 'SpatiotemporalBigDataStoreConfiguration'
var dscTileCacheDataStoreDscFunction = 'TileCacheDataStoreConfiguration'
var fileShareDscScriptFunction = 'FileShareConfiguration'

// dynamic cluster
var isObjectDataStoreClustered = numberOfObjectDataStoreVirtualMachines >= 3 ? true : false
var isTileCacheDataStoreClustered = numberOfTileCacheDataStoreVirtualMachineNames >= 1 ? true : false
var isMultiMachineTileCacheDataStore = numberOfTileCacheDataStoreVirtualMachineNames >= 1 ? true : false

// Naming conventions
// var locations = (loadJsonContent('../../data/locations.json'))[environment().name]
// var locationAbbreviation = locations[location].abbreviation
// var resourceToken = 'resource_token'
// var serviceToken = 'service_token'
// var networkToken = 'network_token'
// var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${serviceToken}-${networkToken}-${environmentAbbreviation}-${locationAbbreviation}'

// var keyVaultNamingConvention = '${replace(replace(namingConvention, resourceToken, 'kv'), '-', '')}unique_token'
// var logAnalyticsWorkspaceNamingConvention = replace(namingConvention, resourceToken, 'log')
// var networkInterfaceNamingConvention = replace(namingConvention, resourceToken, 'nic')
// var networkSecurityGroupNamingConvention = replace(namingConvention, resourceToken, 'nsg')
// var networkWatcherNamingConvention = replace(namingConvention, resourceToken, 'nw')
// var privateEndpointNamingConvention = replace(namingConvention, resourceToken, 'pe')
// var privateLinkScopeName = replace(namingConvention, resourceToken, 'pls')
// var publicIpAddressNamingConvention = replace(namingConvention, resourceToken, 'pip')
// var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
// var routeTableNamingConvention = replace(namingConvention, resourceToken, 'rt')
// var storageAccountNamingConvention = toLower('${replace(replace(namingConvention, resourceToken, 'st'), '-', '')}unique_token')
// var subnetNamingConvention = replace(namingConvention, resourceToken, 'snet')
// var userAssignedIdentityNamingConvention = replace(namingConvention, resourceToken, 'id')
// var virtualMachineNamingConvention = replace(namingConvention, resourceToken, 'vm')
// var virtualNetworkNamingConvention = replace(namingConvention, resourceToken, 'vnet')

resource privateDnsZone_blob 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: privatelink_blob_name
}

resource privateDnsZone_file 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: privatelink_file_name
}

resource privateDnsZone_keyvaultDns 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: privatelink_keyvaultDns_name
}

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: hubVirtualNetworkName
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-05-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: azureFirewallName
}

resource artifactsStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  scope: resourceGroup(hubSubscriptionId, artifactsStorageAccountResourceGroupName)
  name: artifactsStorageAccountName
}

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module singleTierDataStoreTypes 'modules/singleTierDatastoreTypes.bicep' = if (architecture == 'singletier') {
  name: 'deploy-single-tier-datastore-types-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    enableSpatiotemporalBigDataStore: (architecture == 'singletier') ? enableSpatiotemporalBigDataStore : false
    enableTileCacheDataStore: (architecture == 'singletier') ? enableTileCacheDataStore : false
  }
  dependsOn: [
    rg
  ]
}

module tier3 'modules/tier3.bicep' = {
  name: 'deploy-tier3-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg.name)
  params: {
    applicationGatewayName: applicationGatewayName
    applicationGatewaySubnetAddressPrefix: applicationGatewaySubnetAddressPrefix
    defaultSubnetAddressPrefix: defaultSubnetAddressPrefix
    deployDefender: deployDefender
    deployPolicy: deployPolicy
    emailSecurityContact: emailSecurityContact
    firewallPrivateIPAddress: azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
    hubResourceGroupName: hubResourceGroupName
    hubSubscriptionId: hubSubscriptionId
    hubVirtualNetworkName: hubVirtualNetwork.name
    hubVirtualNetworkResourceId: hubVirtualNetwork.id
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceResourceId: spokelogAnalyticsWorkspaceResourceId
    policy: policy
    privatelink_keyvaultDns_name: split(privateDnsZone_keyvaultDns.id, '/')[8]
    resourceGroupName: rg.name
    resourcePrefix: resourcePrefix
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    workloadSubscriptionId: workloadSubscriptionId
  }
  dependsOn: []
}

module userAssignedIdentity './modules/userAssignedManagedIdentity.bicep' = {
  name: 'deploy-uami-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg.name)
  params: {
    location: location
    name: userAssignedManagedIdentityName
    tags: tags
  }
  dependsOn: [
    tier3
  ]
}

module storage './modules/storageAccount.bicep' = {
  name: 'deploy-storage-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg.name)
  params: {
    containerName: container
    location: location
    tags: tags
    useCloudStorage: useCloudStorage
    blobsPrivateDnsZoneResourceId: privateDnsZone_blob.id
    filePrivateDnsZoneResourceId: privateDnsZone_file.id
    subnetResourceId: tier3.outputs.subnetResourceId
    keyVaultUri: keyVault.outputs.keyVaultUri
    storageEncryptionKeyName: keyVault.outputs.storageKeyName
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
  }
  dependsOn: [
    tier3
  ]
}

module publicIpAddress './modules/publicIpAddress.bicep' = {
  name: 'deploy-pip-address-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    hostname: 'esri-${resourcePrefix}${uniqueString(resourceGroupName)}'
    location: location
    publicIpAddressName: publicIpAddressName
    publicIpAllocationMethod: 'Static'
    tags: tags
  }
  dependsOn: [
    rg
    tier3
  ]
}

module serverAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier') {
  name: 'deploy-avset-server-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-server'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module portalAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier') {
  name: 'deploy-avset-portal-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-portal'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module dataStoreAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier') {
  name: 'deploy-avset-datastore-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-datastore'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module spatiotemporalAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier' && enableSpatiotemporalBigDataStore) {
  name: 'deploy-avset-spatiotemporal-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-spatiotemporal'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module tileCacheAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier' && enableTileCacheDataStore) {
  name: 'deploy-avset-tilecache-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-tilecache'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module graphAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier' && enableGraphDataStore) {
  name: 'deploy-avset-graph-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-graph'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module odataAvailabilitySet 'modules/availabilitySet.bicep' = if (architecture == 'multitier' && enableObjectDataStore) {
  name: 'deploy-avset-odata-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilitySetName: 'av-set-odata'
    location: location
  }
  dependsOn: [
    rg
    tier3
  ]
}

module singleTierVirtualMachine 'modules/virtualMachine.bicep' = if (architecture == 'singletier') {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-virtual-machine-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: availabilitySetName
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: networkInterfaceName
    ouPath: ouPath
    serverFunction: 'singletier'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: architecture == 'singletier' ? tier3.outputs.subnetResourceId : 'none'
    tags: tags
    userAssignedIdentityResourceId: architecture == 'singletier' ? userAssignedIdentity.outputs.resourceId : 'none'
    virtualMachineName: virtualMachineName
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}

@batchSize(5)
module multiTierServerVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in serverVirtualMachines: if (architecture == 'multitier') {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-server-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' ? serverAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'server'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierPortalVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in portalVirtualMachines: if (architecture == 'multitier') {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-portal-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' ? portalAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'portal'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierDatastoreServerVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in dataStoreVirtualMachines: if (architecture == 'multitier') {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-datastore-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' ? dataStoreAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'datastore'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierFileServerVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in fileShareVirtualMachines: if (architecture == 'multitier') {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-fileserver-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: ''
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'fileshare'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierSpatiotemporalBigDataStoreVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in spatiotemporalBigDataStoreVirtualMachines: if (architecture == 'multitier' && enableSpatiotemporalBigDataStore) {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-spatiotemporal-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' && enableSpatiotemporalBigDataStore ? spatiotemporalAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'spatiotemporal'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierTileCacheVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in tileCacheDataStoreVirtualMachines: if (architecture == 'multitier' && enableTileCacheDataStore) {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-tilecache-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' && enableTileCacheDataStore ? tileCacheAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'tilecache'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierGraphVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in graphDataStoreVirtualMachines: if (architecture == 'multitier' && enableGraphDataStore) {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-graph-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' && enableGraphDataStore ? graphAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'graph'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

@batchSize(5)
module multiTierObjectDataStoreVirtualMachines 'modules/virtualMachine.bicep' = [for (server, i) in objectDataStoreVirtualMachines: if (architecture == 'multitier' && enableObjectDataStore) {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-odata-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: architecture == 'multitier' && enableObjectDataStore ? odataAvailabilitySet.outputs.name : 'none'
    enableMonitoring: enableMonitoring
    joinWindowsDomain: joinWindowsDomain
    location: location
    networkInterfaceName: '${networkInterfaceName}-${server}'
    ouPath: ouPath
    serverFunction: 'objectDataStore'
    storageAccountName: storage.outputs.storageAccountName
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: server
    windowsDomainAdministratorPassword: windowsDomainAdministratorPassword
    windowsDomainAdministratorUserName: windowsDomainAdministratorUserName
    windowsDomainName: windowsDomainName
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    rg
  ]
}]

module keyVault './modules/keyVault.bicep' = {
  name: 'deploy-key-vault-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    domainJoinPassword: joinWindowsDomain ? windowsDomainAdministratorPassword : 'None'
    domainJoinUserPrincipalName: joinWindowsDomain ? windowsDomainAdministratorUserName : 'None'
    keyVaultCertificatesOfficerRoleDefinitionResourceId: keyVaultCertificatesOfficer
    keyVaultName: take('${keyVaultName}-${uniqueString(rg.id, keyVaultName)}', 24)
    keyVaultSecretsOfficerRoleDefinitionResourceId: keyVaultSecretsOfficer
    localAdministratorPassword: adminPassword
    localAdministratorUsername: adminUsername
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
    keyVaultPrivateDnsZoneResourceId: privateDnsZone_keyvaultDns.id
    subnetResourceId: tier3.outputs.subnetResourceId
    keyVaultCryptoOfficerRoleDefinitionResourceId: keyVaultCryptoOfficer
  }
  dependsOn: [
    tier3
  ]
}

module roleAssignmentStorageAccount './modules/roleAssignmentStorageAccount.bicep' = {
  name: 'assign-role-sa-01-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    keyVault
    tier3
  ]
}

module roleAssignmentArtifactsStorageAccount './modules/roleAssignmentStorageAccount.bicep' = {
  name: 'assign-role-sa-02-${deploymentNameSuffix}'
  scope: resourceGroup(artifactsStorageAccountSubscriptionId, artifactsStorageAccountResourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: artifactsStorageAccount.name
  }
  dependsOn: [
    keyVault
    tier3
  ]
}

module roleAssignmentVirtualMachineContributor './modules/roleAssignmentVirtualMachineContributor.bicep' = {
  name: 'assign-role-vm-02-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    resourceGroupName: resourceGroupName
  }
  dependsOn: [
    tier3
  ]
}

module managementVm 'modules/managementVirtualMachine.bicep' = {
  name: 'deploy-management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: take('vm-esri-mgmt-${resourceSuffix})', 15)
    certificateFileName: certificateFileName
    certificatePassword: certificatePassword
    artifactsContainerName: artifactsContainerName
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    externalDnsHostname: externalDnsHostname
    hybridUseBenefit: false
    keyVaultName: keyVault.outputs.name
    localAdministratorPassword: adminPassword
    localAdministratorUsername: adminUsername
    portalLicenseFile: portalLicenseFile
    portalLicenseFileName: portalLicenseFileName
    serverLicenseFile: serverLicenseFile
    serverLicenseFileName: serverLicenseFileName
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
    userAssignedIdentityClientId: userAssignedIdentity.outputs.clientId
    artifactsStorageAccountName: artifactsStorageAccount.name
    esriStorageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    multiTierFileServerVirtualMachines
    multiTierPortalVirtualMachines
    multiTierServerVirtualMachines
    rg
    roleAssignmentArtifactsStorageAccount
    roleAssignmentStorageAccount
    roleAssignmentVirtualMachineContributor
    tier3
    userAssignedIdentity
  ]
}

module certificates './modules/certificates.bicep' = {
  name: 'create-certificates-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    fileUri: '${storage.outputs.storageEndpoint}${container}/GenerateSSLCerts.ps1'
    location: location
    portalInternalCertificateFileName: ''
    portalVirtualMachineNames: architecture == 'singletier' ? virtualMachineName : portalVirtualMachineNames
    serverInternalCertificateFileName: ''
    serverVirtualMachineNames: architecture == 'singletier' ? virtualMachineName : serverVirtualMachineNames
    tags: tags
    virtualMachineName: architecture == 'singletier' ? virtualMachineName : fileShareVirtualMachineName
    selfSignedSSLCertificatePassword: selfSignedCertificatePassword
  }
  dependsOn: [
    keyVault
    managementVm
    multiTierFileServerVirtualMachines
    rg
    singleTierVirtualMachine
    tier3
  ]
}

module configureEsriMultiTier './modules/esriEnterpriseMultiTier.bicep' = if (architecture == 'multitier') {
  name: 'deploy-esri-multitier-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    applicationGatewayName: applicationGatewayName
    applicationGatewayPrivateIPAddress: applicationGatewayPrivateIpAddress
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
    architecture: architecture
    cloudStorageAccountCredentialsUserName: storage.outputs.cloudStorageAccountCredentialsUserName
    dataStoreVirtualMachineNames: dataStoreVirtualMachineNames
    dataStoreVirtualMachineOSDiskSize: dataStoreVirtualMachineOSDiskSize
    dataStoreVirtualMachines: dataStoreVirtualMachines
    debugMode: debugMode
    deploymentNameSuffix: deploymentNameSuffix
    dscDataStoreFunction: dscDataStoreFunction
    dscGraphDataStoreFunction: dscGraphDataStoreFunction
    dscObjectDataStoreFunction: dscObjectDataStoreFunction
    dscPortalFunction: dscPortalFunction
    dscServerScriptFunction: dscServerScriptFunction
    dscSpatioTemporalFunction: dscsSatiotemporalBigDataStoreFunction
    dscTileCacheFunction: dscTileCacheDataStoreDscFunction
    enableDataStoreVirtualMachineDataDisk: enableDataStoreVirtualMachineDataDisk
    enableGraphDataStore: enableGraphDataStore
    enableGraphDataStoreVirtualMachineDataDisk: enableGraphDataStoreVirtualMachineDataDisk
    enableObjectDataStore: enableObjectDataStore
    enableObjectDataStoreVirtualMachineDataDisk: enableObjectDataStoreVirtualMachineDataDisk
    enableServerLogHarvesterPlugin: enableServerLogHarvesterPlugin
    enableSpatiotemporalBigDataStore: enableSpatiotemporalBigDataStore
    enableSpatiotemporalBigDataStoreVirtualMachineDataDisk: enableSpatiotemporalBigDataStoreVirtualMachineDataDisk
    enableTileCacheDataStore: enableTileCacheDataStore
    enableTileCacheDataStoreVirtualMachineDataDisk: enableTileCacheDataStoreVirtualMachineDataDisk
    enableVirtualMachineDataDisk: enableVirtualMachineDataDisk
    externalDnsHostname: externalDnsHostname
    fileShareDscScriptFunction: fileShareDscScriptFunction
    fileShareVirtualMachineName: fileShareVirtualMachineName
    graphDataStoreVirtualMachineNames: graphDataStoreVirtualMachineNames
    graphDataStoreVirtualMachineOSDiskSize: graphDataStoreVirtualMachineOSDiskSize
    graphDataStoreVirtualMachines: graphDataStoreVirtualMachines
    iDns: architecture == 'multitier' ? multiTierFileServerVirtualMachines[0].outputs.networkInterfaceInternalDomainNameSuffix : ''
    isMultiMachineTileCacheDataStore: isMultiMachineTileCacheDataStore
    isObjectDataStoreClustered: isObjectDataStoreClustered
    isTileCacheDataStoreClustered: isTileCacheDataStoreClustered
    isUpdatingCertificates: isUpdatingCertificates
    joinWindowsDomain: joinWindowsDomain
    keyVaultUri: keyVault.outputs.keyVaultUri
    location: location
    objectDataStoreVirtualMachineNames: objectDataStoreVirtualMachineNames
    objectDataStoreVirtualMachineOSDiskSize: objectDataStoreVirtualMachineOSDiskSize
    objectDataStoreVirtualMachines: objectDataStoreVirtualMachines
    portalBackendSslCert: certificates.outputs.portalBackendSSLCert
    portalContext: portalContext
    portalLicenseFileName: portalLicenseFileName
    portalLicenseUserTypeId: portalLicenseUserTypeId
    portalVirtualMachineNames: portalVirtualMachineNames
    portalVirtualMachineOSDiskSize: portalVirtualMachineOSDiskSize
    portalVirtualMachines: portalVirtualMachines
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    publicIpId: publicIpAddress.outputs.pipId
    resourceGroupName: resourceGroupName
    resourceSuffix: resourceSuffix
    secondaryDnsHostName: secondaryDnsHostName
    selfSignedSSLCertificatePassword: selfSignedCertificatePassword
    serverBackendSSLCert: certificates.outputs.serverBackendSSLCert
    serverContext: serverContext
    serverLicenseFileName: serverLicenseFileName
    serverVirtualMachineNames: serverVirtualMachineNames
    serverVirtualMachines: serverVirtualMachines
    spatiotemporalBigDataStoreVirtualMachineNames: spatiotemporalBigDataStoreVirtualMachineNames
    spatiotemporalBigDataStoreVirtualMachineOSDiskSize: spatiotemporalBigDataStoreVirtualMachineOSDiskSize
    spatiotemporalBigDataStoreVirtualMachines: spatiotemporalBigDataStoreVirtualMachines
    storageAccountName: storage.outputs.storageAccountName
    storageUriPrefix: '${storage.outputs.storageEndpoint}${container}/'
    tags: tags
    tileCacheDataStoreVirtualMachineOSDiskSize: tileCacheDataStoreVirtualMachineOSDiskSize
    tileCacheVirtualMachineNames: tileCacheDataStoreVirtualMachineNames
    tileCacheVirtualMachines: tileCacheDataStoreVirtualMachines
    useAzureFiles: useAzureFiles
    useCloudStorage: useCloudStorage
    userAssignedIdenityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineOSDiskSize: virtualMachineOSDiskSize
    virtualNetworkId: tier3.outputs.virtualNetworkResourceId
    virtualNetworkName: tier3.outputs.virtualNetworkName
    windowsDomainName: joinWindowsDomain ? windowsDomainName : 'none'
    hubVirtualNetworkId: hubVirtualNetwork.id
  }
  dependsOn: [
    managementVm
    certificates
    multiTierDatastoreServerVirtualMachines
    multiTierFileServerVirtualMachines
    multiTierGraphVirtualMachines
    multiTierGraphVirtualMachines
    multiTierObjectDataStoreVirtualMachines
    multiTierPortalVirtualMachines
    multiTierServerVirtualMachines
    multiTierSpatiotemporalBigDataStoreVirtualMachines
    multiTierTileCacheVirtualMachines
    publicIpAddress
    tier3
  ]
}

module configuration './modules/esriEnterpriseSingleTier.bicep' = if (architecture == 'singletier') {
  name: 'deploy-esri-singletier-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
    cloudStorageAccountCredentialsUserName: storage.outputs.cloudStorageAccountCredentialsUserName
    dataStoreTypesForBaseDeploymentServers: (architecture == 'singletier') ? singleTierDataStoreTypes.outputs.dataStoreTypesForBaseDeploymentServers : 'none'
    debugMode: debugMode
    deploymentNameSuffix: deploymentNameSuffix
    dscConfiguration: dscSingleTierConfiguration
    dscScript: '${dscSingleTierConfiguration}.ps1'
    enableServerLogHarvesterPlugin: enableServerLogHarvesterPlugin
    enableVirtualMachineDataDisk: enableVirtualMachineDataDisk
    hostname: externalDnsHostname
    isTileCacheDataStoreClustered: isTileCacheDataStoreClustered
    isUpdatingCertificates: isUpdatingCertificates
    location: location
    portalContext: portalContext
    portalLicenseFileName: portalLicenseFileName
    portalLicenseUserTypeId: portalLicenseUserTypeId
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    publicKeySSLCertificateFileName: 'wildcard${externalDnsHostname}-PublicKey.cer'
    serverContext: serverContext
    serverLicenseFileName: serverLicenseFileName
    storageAccountName: storage.outputs.storageAccountName
    storageUriPrefix: '${storage.outputs.storageEndpoint}${container}/'
    tags: tags
    useAzureFiles: useAzureFiles
    useCloudStorage: useCloudStorage
    virtualMachineName: virtualMachineName
    virtualMachineOSDiskSize: virtualMachineOSDiskSize
    selfSignedSSLCertificatePassword: selfSignedCertificatePassword
    applicationGatewayName: applicationGatewayName
    externalDnsHostname: externalDnsHostname
    iDns: architecture == 'singletier' ? singleTierVirtualMachine.outputs.networkInterfaceInternalDomainNameSuffix : 'none'
    joinWindowsDomain: joinWindowsDomain
    keyVaultUri: keyVault.outputs.keyVaultUri
    portalBackendSslCert: certificates.outputs.portalBackendSSLCert
    publicIpId: publicIpAddress.outputs.pipId
    resourceGroupName: rg.name
    resourceSuffix: resourceSuffix
    serverBackendSSLCert: certificates.outputs.serverBackendSSLCert
    userAssignedIdenityResourceId: userAssignedIdentity.outputs.resourceId
    virtualNetworkName: tier3.outputs.virtualNetworkName
    windowsDomainName: windowsDomainName
    architecture: architecture
    virtualNetworkId: tier3.outputs.virtualNetworkResourceId
    hubVirtualNetworkId: hubVirtualNetwork.id
    applicationGatewayPrivateIpAddress: applicationGatewayPrivateIpAddress
  }
  dependsOn: [
    certificates
    managementVm
    singleTierVirtualMachine
  ]
}
