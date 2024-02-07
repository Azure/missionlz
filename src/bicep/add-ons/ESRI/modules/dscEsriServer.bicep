
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param cloudStorageAccountCredentialsUserName string
param convertedEpoch int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1D'))
param debugMode bool
param dscConfiguration string
param dscScript string
param enableServerLogHarvesterPlugin bool
param enableVirtualMachineDataDisk bool
param fileShareName string = 'fileshare'
param fileShareVirtualMachineName string
param externalDnsHostName string
param isUpdatingCertificates bool
param location string = resourceGroup().location
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param publicKeySSLCertificateFileName string
param serverVirtualMachineNames string
param serverContext string
param serverLicenseFileName string
param storageAccountName string
param storageUriPrefix string
param tags object
param useAzureFiles bool
param useCloudStorage bool
param virtualMachineNames string
param virtualMachineOSDiskSize int
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

resource dscEsriServer 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
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
         DebugMode: string(debugMode)
         EnableDataDisk: string(enableVirtualMachineDataDisk)
         EnableLogHarvesterPlugin: string(enableServerLogHarvesterPlugin)
         ExternalDNSHostName: externalDnsHostName
         FileShareMachineName: fileShareVirtualMachineName
         FileShareName: fileShareName
         IsUpdatingCertificates: isUpdatingCertificates
         OSDiskSize: virtualMachineOSDiskSize
         PublicKeySSLCertificateFileUrl: '${storageUriPrefix}${publicKeySSLCertificateFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
         ServerContext: serverContext
         ServerMachineNames: serverVirtualMachineNames
         ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
         UseAzureFiles: useAzureFiles
         UseCloudStorage: useCloudStorage
         ServerLicenseFileUrl: '${storageUriPrefix}${serverLicenseFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
        }
    }
    protectedSettings: {
      configurationUrlSasToken: '?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
      managedIdentity: {
        principalId: virtualMachine.identity.principalId
        tenantId: subscription().tenantId
      }
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        ServerInternalCertificatePassword: {
          userName: 'Placeholder'
          password: selfSignedSSLCertificatePassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
        StorageAccountCredential: {
          userName:  useCloudStorage ? cloudStorageAccountCredentialsUserName : 'placeholder'
          password:  useCloudStorage ? storageAccount.listKeys().keys[0].value : 'placeholder'
        }
      }
    }
  }
}

output dscsStatus string = dscEsriServer.properties.provisioningState
