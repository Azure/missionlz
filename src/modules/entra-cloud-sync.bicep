/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0'

@secure()
param adminPassword string
param adminUsername string
param delimiter string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param domainName string
@secure()
param hybridIdentityAdministratorPassword string
param hybridIdentityAdministratorUserPrincipalName string
param location string
param mlzTags object
param subnetResourceId string
param tags object
param tier object
param tokens object
param virtualMachineNames array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: split(subnetResourceId, '/')[8]
  scope: resourceGroup(split(subnetResourceId, '/')[2], split(subnetResourceId, '/')[4])
}

// Management virtual machine to setup the Entra Cloud Sync configuration
module managementVirtualMachine 'virtual-machine.bicep' = {
  name: 'management-virtual-machine-${deploymentNameSuffix}'
  params: {
    adminPasswordOrKey: adminPassword
    adminUsername: adminUsername
    authenticationType: 'password'
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: '${replace(tier.namingConvention.virtualMachineDisk, tokens.purpose, 'mgt')}${delimiter}0'
    imageOffer: 'WindowsServer'
    imagePublisher: 'MicrosoftWindowsServer'
    imageSku: '2019-datacenter-core-g2'
    imageVersion: 'latest'
    location: location
    mlzTags: mlzTags
    networkInterfaceName: replace(tier.namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'mgt')
    networkSecurityGroupResourceId: virtualNetwork.properties.subnets[0].properties.networkSecurityGroup.id
    storageAccountType: 'Premium_LRS'
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: replace(tier.namingConvention.virtualMachine, tokens.purpose, 'mgt')
    virtualMachineSize: 'Standard_DS1_v2'
  }
}

// Get the Resource Id of the Graph resource in the tenant
resource graphServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '00000003-0000-0000-c000-000000000000'
}

// Assign Microsoft Graph permissions to the management virtual machine to allow the deployment of the Entra Cloud Sync configuration
resource assignAppRole 'Microsoft.Graph/appRoleAssignedTo@v1.0' = {
  appRoleId: (filter(graphServicePrincipal.appRoles, role => role.value == 'DeviceManagementConfiguration.ReadWrite.All')[0]).id
  principalId: managementVirtualMachine.outputs.virtualMachinePrincipalId
  resourceId: graphServicePrincipal.id
}

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSyncAgents 'run-command.bicep' = [ for (virtualMachineName, i) in virtualMachineNames: {
  name: 'install-entra-cloud-sync-${i}-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: 'Install-EntraCloudSyncAgent'
    parameters: [
      {
        name: 'AzureEnvironment'
        value: environment().name
      }
      {
        name: 'AzureResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'DomainAdministratorUsername'
        value: adminUsername
      }
      {
        name: 'HybridIdentityAdministratorUserPrincipalName'
        value: hybridIdentityAdministratorUserPrincipalName
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
    ]
    protectedParameters: '[{\'name\':\'DomainAdministratorPassword\',\'value\':\'${adminPassword}\'},{\'name\':\'HybridIdentityAdministratorPassword\',\'value\':\'${hybridIdentityAdministratorPassword}\'}]'
    script: loadTextContent('../artifacts/Install-EntraCloudSyncAgent.ps1')
    tags: tags
    virtualMachineName: virtualMachineName
  }
}]

// Run command to provision the Entra Cloud Sync configuration in Entra ID
module provisionEntraCloudSyncConfiguration 'run-command.bicep' = {
  name: 'provision-entra-cloud-sync-config-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: 'New-EntraCloudSyncConfiguration'
    parameters: [
      {
        name: 'CloudSuffix'
        value: last(split(split(environment().resourceManager, '/')[2], '.'))
      }
      {
        name: 'DomainName'
        value: domainName
      }
    ]
    script: loadTextContent('../artifacts/New-EntraCloudSyncConfiguration.ps1')
    tags: tags
    virtualMachineName: managementVirtualMachine.outputs.virtualMachineName
  }
  dependsOn: [
    installEntraCloudSyncAgents
  ]
}
