@secure()
param adminPassword string
param adminUsername string
param applicationGatewayName string
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param architecture string
param cloudStorageAccountCredentialsUserName string
param dataStoreVirtualMachineNames string
param dataStoreVirtualMachineOSDiskSize int
param dataStoreVirtualMachines array
param debugMode bool
param deploymentNameSuffix string
param dscDataStoreFunction string
param dscPortalFunction string
param dscServerScriptFunction string
param dscSpatioTemporalFunction string
param dscTileCacheFunction string
param dscGraphDataStoreFunction string
param dscObjectDataStoreFunction string
param enableDataStoreVirtualMachineDataDisk bool
param enableServerLogHarvesterPlugin bool
param enableSpatiotemporalBigDataStoreVirtualMachineDataDisk bool
param enableVirtualMachineDataDisk bool
param externalDnsHostname string
// param externalDnsHostnamePrefix string
param fileShareDscScriptFunction string
param fileShareVirtualMachineName string
// param iDns string
param isUpdatingCertificates bool
param joinWindowsDomain bool
param keyVaultUri string
param location string = resourceGroup().location
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
param serverBackendSSLCert string
param serverContext string
param serverLicenseFileName string
param serverVirtualMachineNames string
param serverVirtualMachines array
param spatiotemporalBigDataStoreVirtualMachineNames string
param spatiotemporalBigDataStoreVirtualMachineOSDiskSize int
param spatiotemporalBigDataStoreVirtualMachines array
param tileCacheVirtualMachines array
param tileCacheVirtualMachineNames string
param storageAccountName string
param storageUriPrefix string
param subscriptionId string = subscription().subscriptionId
param tags object
param useAzureFiles bool
param useCloudStorage bool
param userAssignedIdenityResourceId string
param virtualMachineOSDiskSize int
// param virtualNetworkId string
param virtualNetworkName string
@secure()
param selfSignedSSLCertificatePassword string
param tileCacheDataStoreVirtualMachineOSDiskSize int
param isTileCacheDataStoreClustered bool
param isMultiMachineTileCacheDataStore bool
param enableTileCacheDataStoreVirtualMachineDataDisk bool
param graphDataStoreVirtualMachineNames string
param graphDataStoreVirtualMachines array
param graphDataStoreVirtualMachineOSDiskSize int
param enableGraphDataStoreVirtualMachineDataDisk bool
param objectDataStoreVirtualMachineNames string
param objectDataStoreVirtualMachines array
param objectDataStoreVirtualMachineOSDiskSize int
param isObjectDataStoreClustered bool
param enableObjectDataStoreVirtualMachineDataDisk bool
param enableSpatiotemporalBigDataStore bool
param enableTileCacheDataStore bool
param enableGraphDataStore bool
param enableObjectDataStore bool
param applicationGatewayPrivateIPAddress string
param windowsDomainName string
// param hubVirtualNetworkId string

// var privateDnsDomainName ='${split(externalDnsHostname, '.')[1]}.${split(externalDnsHostname, '.')[2]}'


module dscFileShare 'dscEsriFileShare.bicep' = if (architecture == 'multitier') {
  name: 'deploy-fileshare-dsc-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    // privateDnsZone
  ]
}

// module privateDnsZone 'privateDnsZone.bicep' = if (architecture == 'multitier' && joinWindowsDomain == false) {
//   name: 'deploy-privatednszone-${deploymentNameSuffix}'
//   scope: resourceGroup(subscriptionId, resourceGroupName)
//   params: {
//     externalDnsHostname: externalDnsHostname
//     applicationGatewayPrivateIPAddress: applicationGatewayPrivateIPAddress
//     virtualNetworkId: virtualNetworkId
//     hubVirtualNetworkId: hubVirtualNetworkId
//   }
//   dependsOn: [
//   ]
// }

@batchSize(1)
module dscEsriServers 'dscEsriServer.bicep' =  [for (server, i) in serverVirtualMachines : if (architecture == 'multitier') {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    dscEsriServers
    dscEsriDataStoreServers
    dscFileShare
    dscEsriObjectDataStoreServers
    applicationGateway
    // privateDnsZone
  ]
}]


@batchSize(1)
module dscEsriTileCacheServers 'dscEsriTileCache.bicep' = [for (server, i) in tileCacheVirtualMachines : if (architecture == 'multitier' && enableTileCacheDataStore) {
  name: 'deploy-${server}-dsc-${deploymentNameSuffix}${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    dscFileShare
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
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    dscFileShare
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
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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

