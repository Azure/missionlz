param deploymentNameSuffix string
param location string
param mlzTags array
param name string
param tags array
param virtualMachineName string

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSync 'run-command.bicep' = {
  name: 'install-entra-cloud-sync-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: name
    script: loadTextContent('../artifacts/')
    tags: tags
    virtualMachineName: virtualMachineName
  }
}
