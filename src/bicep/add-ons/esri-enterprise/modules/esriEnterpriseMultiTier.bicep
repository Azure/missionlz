param applicationGatewayName string
param applicationGatewayPrivateIPAddress string
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUsername string
param architecture string
param cloudStorageAccountCredentialsUserName string
param dataStoreVirtualMachineNames string
param dataStoreVirtualMachineOSDiskSize int
param dataStoreVirtualMachines array
param debugMode bool
param deploymentNameSuffix string
param dscDataStoreFunction string
param dscGraphDataStoreFunction string
param dscObjectDataStoreFunction string
param dscPortalFunction string
param dscServerScriptFunction string
param dscSpatioTemporalFunction string
param dscTileCacheFunction string
param enableDataStoreVirtualMachineDataDisk bool
param enableGraphDataStore bool
param enableGraphDataStoreVirtualMachineDataDisk bool
param enableObjectDataStore bool
param enableObjectDataStoreVirtualMachineDataDisk bool
param enableServerLogHarvesterPlugin bool
param enableSpatiotemporalBigDataStore bool
param enableSpatiotemporalBigDataStoreVirtualMachineDataDisk bool
param enableTileCacheDataStore bool
param enableTileCacheDataStoreVirtualMachineDataDisk bool
param enableVirtualMachineDataDisk bool
param externalDnsHostname string
param fileShareDscScriptFunction string
param fileShareVirtualMachineName string
param graphDataStoreVirtualMachineNames string
param graphDataStoreVirtualMachineOSDiskSize int
param graphDataStoreVirtualMachines array
param isMultiMachineTileCacheDataStore bool
param isObjectDataStoreClustered bool
param isTileCacheDataStoreClustered bool
param isUpdatingCertificates bool
param joinWindowsDomain bool
param keyVaultUri string
param location string = resourceGroup().location
param objectDataStoreVirtualMachineNames string
param objectDataStoreVirtualMachineOSDiskSize int
param objectDataStoreVirtualMachines array
param portalBackendSslCert string
param portalContext string
param portalLicenseFileName string
param portalLicenseUserTypeId string
param portalVirtualMachineNames string
param portalVirtualMachineOSDiskSize int
param portalVirtualMachines array
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param publicIpId string
param resourceGroupName string
param resourceSuffix string
param secondaryDnsHostName string
@secure()
param selfSignedSSLCertificatePassword string
param serverBackendSSLCert string
param serverContext string
param serverLicenseFileName string
param serverVirtualMachineNames string
param serverVirtualMachines array
param spatiotemporalBigDataStoreVirtualMachineNames string
param spatiotemporalBigDataStoreVirtualMachineOSDiskSize int
param spatiotemporalBigDataStoreVirtualMachines array
param tileCacheDataStoreVirtualMachineOSDiskSize int
param tileCacheVirtualMachines array
param tileCacheVirtualMachineNames string
param storageAccountName string
param storageUriPrefix string
param subscriptionId string = subscription().subscriptionId
param tags object
param useAzureFiles bool
param useCloudStorage bool
param userAssignedIdenityResourceId string
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineOSDiskSize int
param virtualNetworkName string
param windowsDomainName string

module dscFileShare 'dscEsriFileShare.bicep' = if (architecture == 'multitier') {
  name: 'deploy-fileshare-dsc-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    debugMode: debugMode
    dscConfiguration: fileShareDscScriptFunction
    dscScript: 'FileShareConfiguration.ps1'
    enableVirtualMachineDataDisk: enableVirtualMachineDataDisk
    externalDNSHostName: externalDnsHostname
    fileShareVirtualMachineName: fileShareVirtualMachineName
    location: location
    portalContext: portalContext
    storageAccountName: storageAccountName
    storageUriPrefix: storageUriPrefix
    tags: tags
    virtualMachineAdminPassword: virtualMachineAdminUsername
    virtualMachineAdminUsername: virtualMachineAdminPassword
    virtualMachineOSDiskSize: virtualMachineOSDiskSize
  }
  dependsOn: [
  ]
}

module applicationGateway 'applicationGateway.bicep' = if (architecture == 'multitier') {
  name: 'deploy-applicationgateway-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    applicationGatewayName: applicationGatewayName
    applicationGatewayPrivateIpAddress: applicationGatewayPrivateIPAddress
    externalDnsHostName: externalDnsHostname
    // iDns: iDns
    joinWindowsDomain: joinWindowsDomain
    keyVaultUri: keyVaultUri
    location: location
    portalBackendSslCert: portalBackendSslCert
    portalVirtualMachineNames: portalVirtualMachineNames
    publicIpId: publicIpId
    resourceGroup: resourceGroupName
    resourceSuffix: resourceSuffix
    serverBackendSSLCert: serverBackendSSLCert
    serverVirtualMachineNames: serverVirtualMachineNames
    userAssignedIdenityResourceId: userAssignedIdenityResourceId
    virtualNetworkName: virtualNetworkName
    windowsDomainName: windowsDomainName
  }
  dependsOn: [
    dscFileShare
  ]
}

@batchSize(1)
module dscEsriServers 'dscEsriServer.bicep' =  [for (server, i) in serverVirtualMachines : if (architecture == 'multitier') {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    cloudStorageAccountCredentialsUserName: cloudStorageAccountCredentialsUserName
    debugMode: debugMode
    dscConfiguration: dscServerScriptFunction
    dscScript: '${dscServerScriptFunction}.ps1'
    enableServerLogHarvesterPlugin: enableServerLogHarvesterPlugin
    enableVirtualMachineDataDisk: enableVirtualMachineDataDisk
    externalDnsHostName: externalDnsHostname
    fileShareVirtualMachineName: fileShareVirtualMachineName
    isUpdatingCertificates: isUpdatingCertificates
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    publicKeySSLCertificateFileName: 'wildcard${externalDnsHostname}-PublicKey.cer'
    serverContext: serverContext
    serverLicenseFileName: serverLicenseFileName
    serverVirtualMachineNames: serverVirtualMachineNames
    storageAccountName: storageAccountName
    storageUriPrefix: storageUriPrefix
    tags: tags
    useAzureFiles: useAzureFiles
    useCloudStorage: useCloudStorage
    virtualMachineNames: server
    virtualMachineOSDiskSize: virtualMachineOSDiskSize
    selfSignedSSLCertificatePassword: selfSignedSSLCertificatePassword
  }
  dependsOn: [
    dscFileShare
    applicationGateway
    // privateDnsZone
  ]
}]

@batchSize(1)
module dscEsriDataStoreServers 'dscEsriDataStore.bicep' = [for (server, i) in dataStoreVirtualMachines : if (architecture == 'multitier') {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    cloudStorageAccountCredentialsUserName: cloudStorageAccountCredentialsUserName
    dataStoreVirtualMachineNames: dataStoreVirtualMachineNames
    dataStoreVirtualMachineOSDiskSize: dataStoreVirtualMachineOSDiskSize
    debugMode: debugMode
    dscConfiguration: dscDataStoreFunction
    dscScript: '${dscDataStoreFunction}.ps1'
    enableDataStoreVirtualMachineDataDisk: enableDataStoreVirtualMachineDataDisk
    externalDnsHostName: externalDnsHostname
    fileShareVirtualMachineName: fileShareVirtualMachineName
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    serverVirtualMachineNames: serverVirtualMachineNames
    storageAccountName: storageAccountName
    storageUriPrefix:storageUriPrefix
    tags: tags
    useAzureFiles: useAzureFiles
    useCloudStorage: useCloudStorage
    virtualMachineNames: server
  }
  dependsOn:[
    dscEsriServers
    dscFileShare
    applicationGateway
    // privateDnsZone
  ]
}]

@batchSize(1)
module dscEsriSpatioTemporalServers 'dscEsriSpatioTemporal.bicep' = [for (server, i) in spatiotemporalBigDataStoreVirtualMachines : if (architecture == 'multitier' && enableSpatiotemporalBigDataStore) {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    debugMode: debugMode
    dscConfiguration: dscSpatioTemporalFunction
    dscScript: '${dscSpatioTemporalFunction}.ps1'
    enableSpatiotemporalBigDataStoreVirtualMachineDataDisk: enableSpatiotemporalBigDataStoreVirtualMachineDataDisk
    fileShareVirtualMachineName: fileShareVirtualMachineName
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    serverVirtualMachineNames: serverVirtualMachineNames
    spatiotemporalBigDataStoreVirtualMachineNames: spatiotemporalBigDataStoreVirtualMachineNames
    spatiotemporalBigDataStoreVirtualMachineOSDiskSize: spatiotemporalBigDataStoreVirtualMachineOSDiskSize
    storageAccountName: storageAccountName
    storageUriPrefix: storageUriPrefix
    tags: tags
    virtualMachineNames: server
  }
  dependsOn:[
    applicationGateway
    dscEsriDataStoreServers
    dscEsriObjectDataStoreServers
    dscEsriServers
    dscFileShare
  ]
}]


@batchSize(1)
module dscEsriTileCacheServers 'dscEsriTileCache.bicep' = [for (server, i) in tileCacheVirtualMachines : if (architecture == 'multitier' && enableTileCacheDataStore) {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    debugMode: debugMode
    dscConfiguration: dscTileCacheFunction
    dscScript: '${dscTileCacheFunction}.ps1'
    enableTileCacheDataStoreVirtualMachineDataDisk: enableTileCacheDataStoreVirtualMachineDataDisk
    fileShareVirtualMachineName: fileShareVirtualMachineName
    isMultiMachineTileCacheDataStore: isMultiMachineTileCacheDataStore
    isTileCacheDataStoreClustered: isTileCacheDataStoreClustered
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    serverVirtualMachineNames: serverVirtualMachineNames
    storageAccountName: storageAccountName
    storageUriPrefix: storageUriPrefix
    tags: tags
    tileCacheDataStoreVirtualMachineNames: tileCacheVirtualMachineNames
    tileCacheDataStoreVirtualMachineOSDiskSize: tileCacheDataStoreVirtualMachineOSDiskSize
    virtualMachineNames: server
  }
  dependsOn:[
    dscEsriServers
    dscEsriDataStoreServers
    dscFileShare
    dscEsriGraphDataStoreServers
    applicationGateway
    // privateDnsZone
  ]
}]

@batchSize(1)
module dscEsriGraphDataStoreServers 'dscEsriGraphDataStore.bicep' = [for (server, i) in graphDataStoreVirtualMachines  : if (architecture == 'multitier' && enableGraphDataStore) {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    debugMode: debugMode
    dscConfiguration: dscGraphDataStoreFunction
    dscScript: '${dscGraphDataStoreFunction}.ps1'
    enableGraphDataStoreVirtualMachineDataDisk: enableGraphDataStoreVirtualMachineDataDisk
    fileShareVirtualMachineName: dscFileShare.outputs.fileShareName
    graphDataStoreVirtualMachineNames: graphDataStoreVirtualMachineNames
    graphDataStoreVirtualMachineOSDiskSize: graphDataStoreVirtualMachineOSDiskSize
    location: location
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName:primarySiteAdministratorAccountUserName
    serverVirtualMachineNames: serverVirtualMachineNames
    storageAccountName: storageAccountName
    storageUriPrefix: storageUriPrefix
    tags: tags
    virtualMachineNames: server
  }
  dependsOn:[
    dscEsriServers
    dscEsriDataStoreServers
    dscEsriObjectDataStoreServers
    dscEsriSpatioTemporalServers
    applicationGateway
    // privateDnsZone
  ]
}]

@batchSize(1)
module dscEsriObjectDataStoreServers 'dscEsriObjectDataStore.bicep' = [for (server, i) in objectDataStoreVirtualMachines  : if (architecture == 'multitier' && enableObjectDataStore) {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    debugMode: debugMode
    dscConfiguration: dscObjectDataStoreFunction
    dscScript: '${dscObjectDataStoreFunction}.ps1'
    enableObjectDataStoreVirtualMachineDataDisk: enableObjectDataStoreVirtualMachineDataDisk
    fileShareVirtualMachineName: dscFileShare.outputs.fileShareName
    isObjectDataStoreClustered: isObjectDataStoreClustered
    objectDataStoreVirtualMachineNames: objectDataStoreVirtualMachineNames
    objectDataStoreVirtualMachineOSDiskSize: objectDataStoreVirtualMachineOSDiskSize
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    serverVirtualMachineNames: serverVirtualMachineNames
    storageUriPrefix: storageUriPrefix
    tags: tags
    virtualMachineNames: server
    storageAccountName: storageAccountName
  }
  dependsOn:[
    dscEsriServers
    dscEsriDataStoreServers
    applicationGateway
    // privateDnsZone
  ]
}]


@batchSize(1)
module dscEsriPortalServers 'dscEsriPortal.bicep' = [for (server, i) in portalVirtualMachines : if (architecture == 'multitier') {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    cloudStorageAccountCredentialsUserName: cloudStorageAccountCredentialsUserName
    debugMode: debugMode
    dscConfiguration: dscPortalFunction
    dscScript: '${dscPortalFunction}.ps1'
    enablePortalVirtualMachineDataDisk: enableVirtualMachineDataDisk
    externalDnsHostName: externalDnsHostname
    fileShareVirtualMachineName: fileShareVirtualMachineName
    isUpdatingCertificates: isUpdatingCertificates
    location: location
    portalContext: portalContext
    portalLicenseFileName: portalLicenseFileName
    portalLicenseUserTypeId: portalLicenseUserTypeId
    portalVirtualMachineNames: portalVirtualMachineNames
    portalVirtualMachineOSDiskSize: portalVirtualMachineOSDiskSize
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    publicKeySSLCertificateFileName: 'wildcard${externalDnsHostname}-PublicKey.cer'
    secondaryDnsHostName:  secondaryDnsHostName
    serverContext: serverContext
    serverVirtualMachineNames: serverVirtualMachineNames
    storageAccountName: storageAccountName
    storageUriPrefix: storageUriPrefix
    tags: tags
    useAzureFiles: useAzureFiles
    useCloudStorage: useCloudStorage
    virtualMachineNames: server
    selfSignedSSLCertificatePassword: selfSignedSSLCertificatePassword
  }
  dependsOn:[
    dscEsriDataStoreServers
    dscEsriServers
    dscFileShare
    dscEsriSpatioTemporalServers
    dscEsriGraphDataStoreServers
    dscEsriObjectDataStoreServers
    dscEsriTileCacheServers
    applicationGateway
    // privateDnsZone
  ]
}]

