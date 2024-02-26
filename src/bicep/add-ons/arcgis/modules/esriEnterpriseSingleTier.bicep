@secure()
param adminPassword string
param adminUsername string
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param cloudStorageAccountCredentialsUserName string
param dataStoreTypesForBaseDeploymentServers string
param debugMode bool
param deploymentNameSuffix string
param dscConfiguration string
param dscScript string
param enableServerLogHarvesterPlugin bool
param enableVirtualMachineDataDisk bool
param hostname string
param isTileCacheDataStoreClustered bool
param isUpdatingCertificates bool
param location string = resourceGroup().location
param portalContext string
param portalLicenseFileName string
param portalLicenseUserTypeId string
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param publicKeySSLCertificateFileName string
param serverContext string
param serverLicenseFileName string
param storageAccountName string
param storageUriPrefix string
param tags object
param useAzureFiles bool
param useCloudStorage bool
param virtualMachineName string
param virtualMachineOSDiskSize int
@secure()
param selfSignedSSLCertificatePassword string
param applicationGatewayName string
param externalDnsHostname string
// param externalDnsHostnamePrefix string
param iDns string
param joinWindowsDomain bool
param keyVaultUri string
param portalBackendSslCert string
param publicIpId string
param resourceGroupName string
param resourceSuffix string
param serverBackendSSLCert string
param subscriptionId string = subscription().subscriptionId
param userAssignedIdenityResourceId string
param virtualNetworkName string
param applicationGatewayPrivateIPAddress string
param windowsDomainName string
param architecture string
param virtualNetworkId string


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  scope: resourceGroup(subscription().subscriptionId, resourceGroup().name)
  name: storageAccountName
}

module privateDnsZone 'privateDnsZone.bicep' = if (architecture == 'multitier' && joinWindowsDomain == false) {
  name: 'deploy-privatednszone-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    externalDnsHostname: externalDnsHostname
    applicationGatewayPrivateIPAddress: multiTierApplicationGateway.outputs.applicationGatewayPrivateIpAddress
    virtualNetworkId: virtualNetworkId
  }
  dependsOn: [
  ]
}

module multiTierApplicationGateway 'esriEnterpriseApplicationGatewayMultiTier.bicep' = {
  name: 'deploy-applicationgateway-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    applicationGatewayName: applicationGatewayName
    applicationGatewayPrivateIpAddress: applicationGatewayPrivateIPAddress
    externalDnsHostName: externalDnsHostname
    iDns: iDns
    joinWindowsDomain: joinWindowsDomain
    keyVaultUri: keyVaultUri
    location: location
    portalBackendSslCert: portalBackendSslCert
    portalVirtualMachineNames: virtualMachineName
    publicIpId: publicIpId
    resourceGroup: resourceGroupName
    resourceSuffix: resourceSuffix
    serverBackendSSLCert: serverBackendSSLCert
    serverVirtualMachineNames: virtualMachineName
    userAssignedIdenityResourceId: userAssignedIdenityResourceId
    virtualNetworkName: virtualNetworkName
    windowsDomainName: windowsDomainName
  }
  dependsOn: [

  ]
}

module desiredStateConfiguration 'desiredStateConfiguration.bicep' = {
  name: 'desired-state-configuration-${deploymentNameSuffix}'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    arcgisServiceAccountIsDomainAccount: arcgisServiceAccountIsDomainAccount
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
    cloudStorageAccountCredentialsUserName: cloudStorageAccountCredentialsUserName
    dataStoreTypesForBaseDeploymentServers: dataStoreTypesForBaseDeploymentServers
    debugMode: debugMode
    dscConfiguration: dscConfiguration
    dscScript: dscScript
    enableServerLogHarvesterPlugin: enableServerLogHarvesterPlugin
    enableVirtualMachineDataDisk: enableVirtualMachineDataDisk
    hostname: hostname
    isTileCacheDataStoreClustered: isTileCacheDataStoreClustered
    isUpdatingCertificates: isUpdatingCertificates
    location: location
    portalContext: portalContext
    portalLicenseFileName: portalLicenseFileName
    portalLicenseUserTypeId: portalLicenseUserTypeId
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    publicKeySSLCertificateFileName: publicKeySSLCertificateFileName
    serverContext: serverContext
    serverLicenseFileName: serverLicenseFileName
    storageUriPrefix: storageUriPrefix
    tags: tags
    useAzureFiles: useAzureFiles
    useCloudStorage: useCloudStorage
    virtualMachineNames: virtualMachineName
    virtualMachineOSDiskSize: virtualMachineOSDiskSize
    storageAccountName: storageAccount.name
    selfSignedSSLCertificatePassword: selfSignedSSLCertificatePassword
  }
  dependsOn: [
    multiTierApplicationGateway
    privateDnsZone
  ]
}

