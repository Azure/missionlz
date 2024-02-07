targetScope = 'subscription'
@secure()
@description('Virtual Machine admin password')
param adminPassword string
@description('Virtual Machine admin username')
param adminUsername string = 'xadmin'
@description('Application Gateway Private IP Address')
param applicationGatewayPrivateIpAddress string = '172.0.1.9'
@description('Application Gateway Subnet Address Prefix')
param applicationGatewaySubnetAddressPrefix string = '172.0.1.0/28'
@description('ArcGIS Service Account Is Domain Account')
param arcgisServiceAccountIsDomainAccount bool = false
@secure()
@description('ArcGIS Service Account Password')
param arcgisServiceAccountPassword string
@description('ArcGIS Service Account User Name')
param arcgisServiceAccountUserName string = 'arcgis'
@allowed([
  'singletier'
  'multitier'
])
@description('Architecture for ESRI. Single Tier or Multi Tier.')
param architecture string = 'singletier'
@description('Azure Firewall Name')
param azureFirewallName string = 'es1-afw-hub-dev-va'
@description('Data Store Types for Base Deployment Servers')
@allowed([
  'Relational'
  'TileCache'
  'SpatioTemporal'
  'ObjectStore'
])
param dataStoreTypesForBaseDeployment array = ['Relational', 'TileCache', 'SpatioTemporal','ObjectStore']
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
param debugMode bool = false
@description('Default Subnet Address Prefix')
param defaultSubnetAddressPrefix string = '172.0.0.0/24'
@description('Deploy Defender')
param deployDefender bool = false
@description('Deployment Name Suffix')
param deploymentNameSuffix string = utcNow('yyMMddHHs')
@description('Deploy Policy')
param deployPolicy bool = false
@description('Email Security Contact')
param emailSecurityContact string = 'micdz@microsoft.com'
@description('Enable Data Store Virtual Machine Data Disk')
param enableDataStoreVirtualMachineDataDisk bool = false
@description('Enable Graph Data Store')
param enableGraphDataStore bool = false
@description('Enable Graph Data Store Virtual Machine Data Disk')
param enableGraphDataStoreVirtualMachineDataDisk bool = false
@description('Enable Monitoring')
param enableMonitoring bool = false
@description('Enable Object Data Store')
param enableObjectDataStore bool = true
@description('Enable Object Data Store Virtual Machine Data Disk')
param enableObjectDataStoreVirtualMachineDataDisk bool = false
@description('Enable Server Log Harvester Plugin')
param enableServerLogHarvesterPlugin bool = false
@description('Enable Spatiotemporal Big Data Store')
param enableSpatiotemporalBigDataStore bool = true
@description('Enable Spatiotemporal Big Data Store Virtual Machine Data Disk')
param enableSpatiotemporalBigDataStoreVirtualMachineDataDisk bool = false
@description('Enable Tile Cache Data Store')
param enableTileCacheDataStore bool = true
@description('Enable Tile Cache Data Store Virtual Machine Data Disk')
param enableTileCacheDataStoreVirtualMachineDataDisk bool = false
@description('Enable Virtual Machine Data Disk')
param enableVirtualMachineDataDisk bool = false
@description('External DNS Hostname')
param externalDnsHostname string
@description('External DNS Hostname Prefix')
param externalDnsHostnamePrefix string = 'm11'
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
param hubResourceGroupName string = 'es1-rg-hub-dev-va'
@description('Hub Subscription Id')
param hubSubscriptionId string = 'f4972a61-1083-4904-a4e2-a790107320bf'
@description('Hub Virtual Network Name')
param hubVirtualNetworkName string = 'es1-vnet-hub-dev-va'
@description('Is Multi Machine Tile Cache Data Store')
param isMultiMachineTileCacheDataStore bool = false
@description('Is Object Data Store Clustered')
param isObjectDataStoreClustered bool = true
@description('Is Tile Cache Data Store Clustered')
param isTileCacheDataStoreClustered bool = false
@description('Updating Certificates')
param isUpdatingCertificates bool = false
@description('Join Windows Domain')
param joinWindowsDomain bool = true
@description('Location')
param location string = deployment().location
@description('Log Analytics Workspace Name')
param logAnalyticsWorkspaceName string = 'es1-log-operations-dev-va'
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
@minValue(3)
param numberOfObjectDataStoreVirtualMachines int = 3 // min value of 3 if clustering
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
param ouPath string = 'OU=ESRI;DC=mikedzikowski;DC=com'
@description('Policy')
param policy string = ''
@description('Portal License File')
param portalLicenseFile string = loadFileAsBase64('ArcGIS_Enterprise_Portal_111_427652_20230804.json')
@description('Portal License User Type Id')
param portalLicenseUserTypeId string = 'creatorUT'
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
param primarySiteAdministratorAccountUserName string = 'sadmin'
@description('Resource Prefix')
param resourcePrefix string = 'tr3'
@description('Resource Suffix')
param resourceSuffix string = 'm11'
@description('Secondary Host Name')
param secondaryDnsHostName string = ''
@secure()
@description('Certificate Password')
param selfSignedCertificatePassword string
param serverLicenseFile string = loadFileAsBase64('ArcGISGISServerAdvanced_ArcGISServer_1357854.prvc')
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
param spokelogAnalyticsWorkspaceResourceId string = '/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/resourceGroups/es1-rg-operations-dev-va/providers/Microsoft.OperationalInsights/workspaces/es1-log-operations-dev-va'
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
param useAzureFiles bool = true
@description('useCloudStorage value')
param useCloudStorage bool = true
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
param virtualNetworkAddressPrefix string = '172.0.0.0/16'
@secure()
@description('The password for the Windows domain administrator account.')
param windowsDomainAdministratorPassword string
@description('The username for the Windows domain administrator account.')
param windowsDomainAdministratorUserName string = 'esri'
@description('The name of the Windows domain.')
param windowsDomainName string = 'mikedzikowski.com'
@description('The GUID of the workload subscription.')
param workloadSubscriptionId string = 'f4972a61-1083-4904-a4e2-a790107320bf'

var applicationGatewayName = 'ag-esri-${resourceSuffix}'
var availabilitySetName = 'avset-esri-${resourceSuffix}'
var container = 'artifacts'
var dataStoreTypesForBaseDeploymentServers = join(dataStoreTypesForBaseDeployment , ',')
var dataStoreVirtualMachineNames  = join(dataStoreVirtualMachines,',')
var dataStoreVirtualMachines = [for  i in range(0, numberOfDataStoreVirtualMachines) : 'vm-esri-ds-${i}']
var dscDataStoreFunction = 'DataStoreConfiguration'
var dscGraphDataStoreFunction = 'GraphDataStoreConfiguration'
var dscObjectDataStoreFunction = 'ObjectDataStoreConfiguration'
var dscPortalFunction = 'PortalConfiguration'
var dscServerScriptFunction = 'ServerConfiguration'
var dscSingleTierConfiguration = 'BaseDeploymentSingleTierConfiguration'
var dscsSatiotemporalBigDataStoreFunction = 'SpatiotemporalBigDataStoreConfiguration'
var dscTileCacheDataStoreDscFunction = 'TileCacheDataStoreConfiguration'
var fileShareDscScriptFunction = 'FileShareConfiguration'
var fileShareVirtualMachineName  = join(fileShareVirtualMachines, ',')
var fileShareVirtualMachines = [for  i in range(0, numberOfFileShareVirtualMachineNames) : 'vm-esri-fl-${i}']
var graphDataStoreVirtualMachineNames  = join(graphDataStoreVirtualMachines, ',')
var graphDataStoreVirtualMachines = [for  i in range(0, numberOfGraphDataStoreVirtualMachineNames) : 'vm-esri-gr-${i}']
var keyVaultCertificatesOfficer = resourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
var keyVaultName = 'kv-esri-${resourceSuffix}'
var keyVaultSecretsOfficer = resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
var networkInterfaceName = 'nic-esri-${resourceSuffix}'
var objectDataStoreVirtualMachineNames  = join(objectDataStoreVirtualMachines, ',')
var objectDataStoreVirtualMachines = [for  i in range(0, numberOfObjectDataStoreVirtualMachines) : 'vm-esri-od-${i}']
var portalContext = 'portal'
var portalLicenseFileName = 'ArcGIS_Enterprise_Portal_111_427652_20230804.json' //FIX THIS
var portalVirtualMachineNames  = join(portalVirtualMachines, ',')
var portalVirtualMachines = [for  i in range(0, numberOfPortalVirtualMachines) : 'vm-esri-pr-${i}']
var privatelink_blob_name = 'privatelink.blob.${environment().suffixes.storage}'
var privatelink_keyvaultDns_name = replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
var publicIpAddressName = 'pip-esri-${resourceSuffix}'
var resourceGroupName = 'rg-esri-enterprise-${resourceSuffix}'
var serverContext = 'server'
var serverLicenseFileName = 'ArcGISGISServerAdvanced_ArcGISServer_1357854.prvc' //FIX THIS
var serverVirtualMachineNames  = join(serverVirtualMachines, ',')
var serverVirtualMachines = [for  i in range(0, numberOfEsriServers) : 'vm-esri-sv-${i}']
var spatiotemporalBigDataStoreVirtualMachineNames  = join(spatiotemporalBigDataStoreVirtualMachines, ',')
var spatiotemporalBigDataStoreVirtualMachines = [for  i in range(0, numberOfEsrispatiotemporalBigDataStoreVirtualMachines) : 'vm-esri-sp-${i}']
var subscriptionId = subscription().subscriptionId
var tileCacheDataStoreVirtualMachineNames  = join(tileCacheDataStoreVirtualMachines, ',')
var tileCacheDataStoreVirtualMachines = [for  i in range(0, numberOfTileCacheDataStoreVirtualMachineNames) : 'vm-esri-tc-${i}']
var userAssignedManagedIdentityName = 'uami-esri-${resourceSuffix}'
var virtualMachineName = 'vm-esri-${resourceSuffix}'

resource privateDnsZone_blob 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  scope: resourceGroup(subscriptionId, hubResourceGroupName)
  name: privatelink_blob_name
}

resource privateDnsZone_keyvaultDns 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  scope: resourceGroup(subscriptionId, hubResourceGroupName)
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

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module tier3 'modules/tier3.bicep' = {
  name: 'deploy-tier3-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg.name)
  params: {
    applicationGatewayName: applicationGatewayName
    applicationGatewaySubnetAddressPrefix: applicationGatewaySubnetAddressPrefix
    defaultSubnetAddressPrefix: defaultSubnetAddressPrefix
    deployDefender: deployDefender
    deployPolicy:  deployPolicy
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
    resourceGroupName: rg.name
    resourcePrefix: resourcePrefix
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    workloadSubscriptionId: workloadSubscriptionId
  }
  dependsOn: [
  ]
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
   }
   dependsOn:[
    tier3
  ]
}

module publicIpAddress './modules/publicIpAddress.bicep' = {
  name: 'deploy-pip-address-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    hostname: externalDnsHostnamePrefix
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
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
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
module multiTierServerVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in serverVirtualMachines : if (architecture == 'multitier')  {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-server-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: serverAvailabilitySet.outputs.name
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
module multiTierPortalVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in portalVirtualMachines : if (architecture == 'multitier') {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-portal-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: portalAvailabilitySet.outputs.name
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
module multiTierDatastoreServerVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in dataStoreVirtualMachines : if (architecture == 'multitier')  {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-datastore-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: dataStoreAvailabilitySet.outputs.name
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
module multiTierFileServerVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in fileShareVirtualMachines: if (architecture == 'multitier')  {
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
module multiTierSpatiotemporalBigDataStoreVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in spatiotemporalBigDataStoreVirtualMachines : if (architecture == 'multitier' && enableSpatiotemporalBigDataStore)  {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-spatiotemporal-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: enableSpatiotemporalBigDataStore ? spatiotemporalAvailabilitySet.outputs.name : 'none'
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
module multiTierTileCacheVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in tileCacheDataStoreVirtualMachines : if (architecture == 'multitier' && enableTileCacheDataStore)  {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-tilecache-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: enableTileCacheDataStore ? tileCacheAvailabilitySet.outputs.name : 'none'
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
module multiTierGraphVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in graphDataStoreVirtualMachines : if (architecture == 'multitier' && enableGraphDataStore)  {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-graph-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: enableGraphDataStore ? graphAvailabilitySet.outputs.name : 'none'
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
module multiTierObjectDataStoreVirtualMachines 'modules/virtualMachine.bicep' =  [for (server, i) in objectDataStoreVirtualMachines : if (architecture == 'multitier' && enableObjectDataStore)  {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'deploy-esri-odata-${i}-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    architecture: architecture
    availabilitySetName: enableObjectDataStore ? odataAvailabilitySet.outputs.name : 'none'
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
    keyVaultName: keyVaultName
    keyVaultSecretsOfficerRoleDefinitionResourceId: keyVaultSecretsOfficer
    localAdministratorPassword: adminPassword
    localAdministratorUsername: adminUsername
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
  }
  dependsOn: [
    rg
    tier3
  ]
}

module roleAssignmentStorageAccount './modules/roleAssignmentStorageAccount.bicep' = {
  name: 'assign-role-sa-01-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params:{
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    keyVault
    tier3
  ]
}

module roleAssignmentVirtualMachineContributor './modules/roleAssignmentVirtualMachineContributor.bicep' = {
  name: 'assign-role-vm-02-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params:{
    principalId: userAssignedIdentity.outputs.principalId
    resourceGroupName: resourceGroupName
  }
  dependsOn: [
    tier3
  ]
}

module artifacts './modules/artifacts.bicep' = {
  name: 'deploy-artifacts-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    containerName: container
    identityId: userAssignedIdentity.outputs.resourceId
    keyVaultName: keyVault.outputs.name
    location: location
    portalLicenseFile: portalLicenseFile
    portalLicenseFileName: portalLicenseFileName
    serverLicenseFile: serverLicenseFile
    serverLicenseFileName: serverLicenseFileName
    storageAccountName: storage.outputs.storageAccountName
    tags: tags
  }
  dependsOn: [
    multiTierFileServerVirtualMachines
    multiTierPortalVirtualMachines
    multiTierServerVirtualMachines
    rg
    roleAssignmentStorageAccount
    roleAssignmentVirtualMachineContributor
    singleTierVirtualMachine
    tier3
  ]
}

module certificates './modules/certificates.bicep' = {
  name: 'create-certificates-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    fileUri: '${storage.outputs.storageEndpoint}${container}/GenerateSSLCerts.ps1'
    location: location
    portalInternalCertificateFileName: ''
    portalVirtualMachineNames: architecture == 'singletier'? virtualMachineName : portalVirtualMachineNames
    serverInternalCertificateFileName: ''
    serverVirtualMachineNames: architecture == 'singletier' ? virtualMachineName : serverVirtualMachineNames
    tags: tags
    virtualMachineName: architecture == 'singletier' ? virtualMachineName : fileShareVirtualMachineName
    selfSignedSSLCertificatePassword: selfSignedCertificatePassword
  }
  dependsOn: [
    keyVault
    rg
    artifacts
    multiTierFileServerVirtualMachines
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
  iDns: multiTierFileServerVirtualMachines[0].outputs.networkInterfaceInternalDomainNameSuffix
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
}
dependsOn: [
  artifacts
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
    dataStoreTypesForBaseDeploymentServers: dataStoreTypesForBaseDeploymentServers
    debugMode: debugMode
    deploymentNameSuffix: deploymentNameSuffix
    dscConfiguration: dscSingleTierConfiguration
    dscScript: '${dscSingleTierConfiguration}.ps1'
    enableServerLogHarvesterPlugin: enableServerLogHarvesterPlugin
    enableVirtualMachineDataDisk: enableVirtualMachineDataDisk
    hostname: publicIpAddress.outputs.pipFqdn
    isTileCacheDataStoreClustered: isTileCacheDataStoreClustered
    isUpdatingCertificates: isUpdatingCertificates
    location: location
    portalContext: portalContext
    portalLicenseFileName: portalLicenseFileName
    portalLicenseUserTypeId: portalLicenseUserTypeId
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    publicKeySSLCertificateFileName: 'wildcard${replace(publicIpAddress.outputs.pipFqdn, externalDnsHostnamePrefix, '')}-PublicKey.cer'
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
  }
  dependsOn: [
    certificates
    artifacts
    singleTierVirtualMachine
  ]
}
