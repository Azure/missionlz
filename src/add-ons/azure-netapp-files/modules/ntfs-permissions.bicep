targetScope = 'subscription'

param deploymentNameSuffix string
@secure()
param domainAdminPassword string
param domainAdminUserPrincipalName string
param location string
param parameters array
param resourceGroupName string
param tags object
param virtualMachineName string

module ntfsPermissions '../../azure-virtual-desktop/modules/fslogix/run-command.bicep' = {
  name: 'deploy-fslogix-ntfs-permissions-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    domainAdminPassword: domainAdminPassword
    domainAdminUserPrincipalName: domainAdminUserPrincipalName
    location: location
    name: 'Set-NtfsPermissions.ps1'
    parameters: parameters
    script: loadTextContent('../artifacts/Set-NtfsPermissions.ps1')
    tags: tags
    virtualMachineName: virtualMachineName
  }
}
