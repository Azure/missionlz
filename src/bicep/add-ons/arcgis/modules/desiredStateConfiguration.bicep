@secure()
param adminPassword string
param adminUsername string
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param cloudStorageAccountCredentialsUserName string
param convertedEpoch int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1D'))
param dataStoreTypesForBaseDeploymentServers string
param debugMode bool
param dscConfiguration string
param dscScript string
param enableServerLogHarvesterPlugin bool
param enableVirtualMachineDataDisk bool
param fileShareName string = 'fileshare'
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
param storageUriPrefix string
param tags object
param useAzureFiles bool
param useCloudStorage bool
param useSelfSignedInternalSSLCertificate bool = true
param virtualMachineNames string
param virtualMachineOSDiskSize int
param storageAccountName string
@secure()
param selfSignedSSLCertificatePassword string

var dscModuleUrl = '${storageUriPrefix}DSC.zip'
var convertedDatetime = dateTimeFromEpoch(convertedEpoch)
var sasProperties = {
  signedProtocol: 'https'
  signedResourceTypes: 'sco'
  signedPermission: 'rl'
  signedServices: 'b'
  signedExpiry: convertedDatetime
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  scope: resourceGroup(subscription().subscriptionId, resourceGroup().name)
  name: storageAccountName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: virtualMachineNames
}

resource extension_DSC 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: virtualMachine
  name: 'DSCConfiguration'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    settings: {
      wmfVersion: 'latest'
      configuration:{
        url: dscModuleUrl
        script: dscScript
        function: dscConfiguration
      }
      configurationArguments: {
         ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
         PortalLicenseUserTypeId: portalLicenseUserTypeId
         MachineName: virtualMachine.name
         PeerMachineName: virtualMachine.name
         ExternalDNSHostName: hostname
         PrivateDNSHostName: ''
         DataStoreTypes: dataStoreTypesForBaseDeploymentServers
         IsTileCacheDataStoreClustered: isTileCacheDataStoreClustered
         FileShareName: fileShareName
         UseCloudStorage: useCloudStorage
         UseAzureFiles: useAzureFiles
         OSDiskSize: virtualMachineOSDiskSize
         EnableDataDisk: string(enableVirtualMachineDataDisk)
         EnableLogHarvesterPlugin: string(enableServerLogHarvesterPlugin)
         DebugMode: string(debugMode)
         ServerContext: serverContext
         PortalContext: portalContext
         IsUpdatingCertificates: isUpdatingCertificates
        }
    }
    protectedSettings: {
      configurationUrlSasToken: '?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
      configurationArguments: {
        PublicKeySSLCertificateFileUrl: '${storageUriPrefix}${publicKeySSLCertificateFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
        ServerLicenseFileUrl: '${storageUriPrefix}${serverLicenseFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
        PortalLicenseFileUrl: '${storageUriPrefix}${portalLicenseFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        MachineAdministratorCredential: {
          userName: adminUsername
          password:  adminPassword
        }
        ServerInternalCertificatePassword: {
          userName: 'Placeholder'
          password: useSelfSignedInternalSSLCertificate ? selfSignedSSLCertificatePassword : ''
        }
        PortalInternalCertificatePassword: {
          userName: 'Placeholder'
          password: useSelfSignedInternalSSLCertificate ? selfSignedSSLCertificatePassword : ''
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
        StorageAccountCredential: {
          userName:  useCloudStorage ? cloudStorageAccountCredentialsUserName : 'placeholder'
          password:  useCloudStorage ? storageAccount.listKeys().keys[0].value  : 'placeholder'
        }
      }
    }
  }
}
