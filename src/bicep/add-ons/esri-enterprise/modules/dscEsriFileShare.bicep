@secure()
param adminPassword string
param adminUsername string
param arcgisServiceAccountIsDomainAccount bool
@secure()
param arcgisServiceAccountPassword string
param arcgisServiceAccountUserName string
param storageAccountName string
param convertedEpoch int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1D'))
param debugMode bool
param dscConfiguration string
param dscScript string
param enableVirtualMachineDataDisk bool
param fileShareName string = 'fileshare'
param externalDNSHostName string
param location string = resourceGroup().location
param portalContext string
param storageUriPrefix string
param tags object
param fileShareVirtualMachineName string
param virtualMachineOSDiskSize int

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

resource fileShareVirtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: fileShareVirtualMachineName
}

resource dscEsriFileShare 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  parent: fileShareVirtualMachine
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
         DebugMode: debugMode
         EnableDataDisk: enableVirtualMachineDataDisk
         ExternalDNSHostName: externalDNSHostName
         IsBaseDeployment: 'True'
         FileShareName: fileShareName
         OSDiskSize: virtualMachineOSDiskSize
         PortalContext: portalContext
         ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        }
    }
    protectedSettings: {
      configurationUrlSasToken: '?${storageAccount.listAccountSAS('2021-04-01', sasProperties).accountSasToken}'
      managedIdentity: {
        principalId: fileShareVirtualMachine.identity.principalId
        tenantId: fileShareVirtualMachine.identity.tenantId
      }
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        MachineAdministratorCredential: {
          userName: adminUsername
          password: adminPassword
        }
      }
    }
  }
}

output dscStatus string = dscEsriFileShare.properties.provisioningState
output fileShareName string = fileShareName

