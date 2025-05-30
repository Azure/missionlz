param deploymentNameSuffix string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param location string
param parameters array
param resourceGroupName string
param tags object
param virtualMachineName string

module ntfsPermissions 'run-command.bicep' = {
  name: 'deploy-fslogix-ntfs-permissions-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    location: location
    name: 'Set-NtfsPermissions.ps1'
    parameters: parameters
    script: loadTextContent('../../artifacts/Set-NtfsPermissions.ps1')
    tags: tags
    virtualMachineName: virtualMachineName
  }
}
