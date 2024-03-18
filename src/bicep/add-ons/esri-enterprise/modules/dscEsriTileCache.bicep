
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param debugMode bool
param dscConfiguration string
param dscScript string
param fileShareName string = 'fileshare'
param isTileCacheDataStoreClustered bool
param location string = resourceGroup().location
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param storageUriPrefix string
param tags object
param virtualMachineNames string
param tileCacheDataStoreVirtualMachineNames string
param isMultiMachineTileCacheDataStore bool
param fileShareVirtualMachineName string
param serverVirtualMachineNames string
param tileCacheDataStoreVirtualMachineOSDiskSize int
param enableTileCacheDataStoreVirtualMachineDataDisk bool
param storageAccountName string
param convertedEpoch int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1D'))


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
        IsTileCacheDataStoreClustered: isTileCacheDataStoreClustered
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        TileCacheDataStoreMachineNames: tileCacheDataStoreVirtualMachineNames
        IsMultiMachineTileCache: isMultiMachineTileCacheDataStore
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ServerMachineNames: serverVirtualMachineNames
        OSDiskSize: tileCacheDataStoreVirtualMachineOSDiskSize
        EnableDataDisk: string(enableTileCacheDataStoreVirtualMachineDataDisk)
        DebugMode: string(debugMode)
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
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
      }
    }
  }
}
