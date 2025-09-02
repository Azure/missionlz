param deploymentNameSuffix string
param location string
param mlzTags object
param name string
param tags object
param virtualMachineName string

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSync '../../../modules/run-command.bicep' = {
  name: 'run-command-install-entra-cloud-sync-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: name
    script: loadTextContent('../artifacts/Install-EntraCloudSync.ps1')
    tags: tags
    virtualMachineName: virtualMachineName
  }
}
