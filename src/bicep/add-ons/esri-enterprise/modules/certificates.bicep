param fileShareName string = 'fileshare'
param fileUri string
param location string = resourceGroup().location
param tags object
param timestamp string = utcNow('yyyyMMddhhmmss')
param useSelfSignedInternalSSLCertificate bool = true
param virtualMachineName string
param serverVirtualMachineNames string
param portalVirtualMachineNames string
param serverInternalCertificateFileName string
param portalInternalCertificateFileName string
@secure()
param selfSignedSSLCertificatePassword string

// var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: virtualMachineName
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: timestamp
    }
    protectedSettings: {
     commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File .\\GenerateSSLCerts.ps1 -ServerMachineNames "${serverVirtualMachineNames}" -PortalMachineNames "${portalVirtualMachineNames}" -FileShareName "${fileShareName}" ${(useSelfSignedInternalSSLCertificate ? '-UseInternalSelfSignedCertificate -CertificatePassword ${selfSignedSSLCertificatePassword}' : '-ServerInternalCertificateFileName "${(empty(serverInternalCertificateFileName) ? '' : serverInternalCertificateFileName)}" -PortalInternalCertificateFileName "${(empty(portalInternalCertificateFileName) ? '' : portalInternalCertificateFileName)}"')}'

      fileUris: [
        fileUri
      ]
      managedIdentity: {}
    }
  }
}

output vmId string = virtualMachine.id
output serverBackendSSLCert string = split(customScriptExtension.properties.instanceView.substatuses[0].message, '###DATA###')[0]
output portalBackendSSLCert string = split(customScriptExtension.properties.instanceView.substatuses[0].message, '###DATA###')[1]
