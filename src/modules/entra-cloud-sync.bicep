targetScope = 'subscription'

param deploymentNameSuffix string
param location string
param mlzTags object
param name string
param tags object
param virtualMachineResourceIds array

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSync 'run-command.bicep' = [ for virtualMachineResourceId in virtualMachineResourceIds: {
  name: 'run-command-install-entra-cloud-sync-${deploymentNameSuffix}'
  scope: resourceGroup(split(virtualMachineResourceId, '/')[2], split(virtualMachineResourceId, '/')[4])
  params: {
    location: location
    mlzTags: mlzTags
    name: name
    parameters: [
      
    ]
    script: loadTextContent('../artifacts/Install-EntraCloudSync.ps1')
    tags: tags
    virtualMachineName: split(virtualMachineResourceId, '/')[8]
  }
}]
