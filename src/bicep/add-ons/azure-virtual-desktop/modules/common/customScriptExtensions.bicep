param fileUris array
param location string
@secure()
param parameters string
param scriptFileName string
param tags object
param timestamp string = utcNow('yyyyMMddhhmmss')
param userAssignedIdentityClientId string
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: virtualMachineName
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${scriptFileName} ${parameters}'
      fileUris: fileUris
      managedIdentity: {
        clientId: userAssignedIdentityClientId
      }
    }
  }
}

output value object = json(filter(customScriptExtension.properties.instanceView.substatuses, item => item.code == 'ComponentStatus/StdOut/succeeded')[0].message)
