/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@secure()
param adminPassword string
param adminUsername string
param delimiter string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
@secure()
param hybridIdentityAdministratorPassword string
param hybridIdentityAdministratorUserPrincipalName string
param location string
param mlzTags object
param name string
param subnetResourceId string
param tags object
param tier object
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
    diskName: '${tier.namingConvention.virtualMachineDisk}${delimiter}mgt${delimiter}0'
    imageOffer: 'WindowsServer'
    imagePublisher: 'MicrosoftWindowsServer'
    imageSku: '2019-datacenter-core-g2'
    imageVersion: 'latest'
    location: location
    mlzTags: mlzTags
    networkInterfaceName: '${tier.namingConvention.virtualMachineNetworkInterface}${delimiter}mgt'
    networkSecurityGroupResourceId: virtualNetwork.properties.subnets[0].properties.networkSecurityGroup.id
    storageAccountType: 'Premium_LRS'
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: '${tier.namingConvention.virtualMachine}mgt'
    virtualMachineSize: 'Standard_DS1_v2'
  }
}

// Run command to install Entra Cloud Sync on the domain controllers
module installEntraCloudSync 'run-command.bicep' = [ for (virtualMachineName, i) in virtualMachineNames: {
  name: 'install-entra-cloud-sync-${i}-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: mlzTags
    name: name
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
