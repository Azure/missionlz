param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param cloudStorageAccountCredentialsUserName string
param convertedEpoch int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1D'))
param debugMode bool
param dscConfiguration string
param dscScript string
param enablePortalVirtualMachineDataDisk bool
param externalDnsHostName string
param fileShareName string = 'fileshare'
param fileShareVirtualMachineName string
param isUpdatingCertificates bool
param location string = resourceGroup().location
param portalContext string
param portalLicenseFileName string
param portalLicenseUserTypeId string
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param publicKeySSLCertificateFileName string
param secondaryDnsHostName string
param serverVirtualMachineNames string
param portalVirtualMachineNames string
param portalVirtualMachineOSDiskSize int
param serverContext string
param storageAccountName string
param storageUriPrefix string
param tags object
param useAzureFiles bool
param useCloudStorage bool
param useSelfSignedInternalSSLCertificate bool = true
param virtualMachineNames string
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

resource dscEsriPortal 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
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
      configuration: {
        url: dscModuleUrl
        script: dscScript
        function: dscConfiguration
      }
      configurationArguments: {
        DebugMode: string(debugMode)
        EnableDataDisk: string(enablePortalVirtualMachineDataDisk)
        ExternalDNSHostName: externalDnsHostName
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        IsUpdatingCertificates: isUpdatingCertificates
        OSDiskSize: portalVirtualMachineOSDiskSize
        PortalContext: portalContext
        PortalLicenseFileUrl: '${storageUriPrefix}${portalLicenseFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
        PortalMachineNames: portalVirtualMachineNames
        PrivateDNSHostName: secondaryDnsHostName
        ServerContext: serverContext
        ServerMachineNames: serverVirtualMachineNames
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        UseAzureFiles: useAzureFiles
        UseCloudStorage: useCloudStorage
        PortalLicenseUserTypeId: portalLicenseUserTypeId
        PublicKeySSLCertificateFileUrl: '${storageUriPrefix}${publicKeySSLCertificateFileName}?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
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
        PortalInternalCertificatePassword: {
          userName: 'Placeholder'
          password: useSelfSignedInternalSSLCertificate ? selfSignedSSLCertificatePassword : ''
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
        StorageAccountCredential: {
          userName: useCloudStorage ? cloudStorageAccountCredentialsUserName : 'placeholder'
          password: useCloudStorage ? storageAccount.listKeys().keys[0].value : 'placeholder'
        }
      }
    }
  }
}

output dscsStatus string = dscEsriPortal.properties.provisioningState
