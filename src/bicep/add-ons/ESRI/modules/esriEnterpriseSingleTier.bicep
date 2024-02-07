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

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  scope: resourceGroup(subscription().subscriptionId, resourceGroup().name)
  name: storageAccountName
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
}

