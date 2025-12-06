/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@secure()
param adminPassword string
param adminUsername string
param availabilitySetResourceId string
param delimiter string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param dnsForwarder string = '168.63.129.16'
param domainName string
param hybridUseBenefit bool
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersion string
param index int
param location string
param mlzTags object
param privateIPAddressOffset int = 3
@secure()
param safeModeAdminPassword string
param subnetResourceId string
param tags object = {}
param tier object
param vmSize string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: split(subnetResourceId, '/')[8]
  scope: resourceGroup(split(subnetResourceId, '/')[2], split(subnetResourceId, '/')[4])
}

module virtualMachine 'virtual-machine.bicep' = {
  name: 'deploy-adds-vm-${index}-${deploymentNameSuffix}'
  params: {
    adminPasswordOrKey: adminPassword
    adminUsername: adminUsername
    authenticationType: 'password'
    availabilitySetResourceId: availabilitySetResourceId
    dataDisks: [{
      caching: 'None'
      createOption: 'Empty'
      diskSizeGB: 128
      lun: 0
      managedDisk: {
        diskEncryptionSet: {
          id: diskEncryptionSetResourceId
        }
        storageAccountType: 'Premium_LRS'
      }
      name: '${tier.namingConvention.virtualMachineDisk}${delimiter}dc${delimiter}${index}${delimiter}1'
    }]
    diskCaching: 'None'
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: '${tier.namingConvention.virtualMachineDisk}${delimiter}dc${delimiter}${index}${delimiter}0'
    domainJoin: false
    domainName: domainName
    hybridUseBenefit: hybridUseBenefit
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    imageVersion: imageVersion
    location: location
    mlzTags: mlzTags
    networkInterfaceName: '${tier.namingConvention.virtualMachineNetworkInterface}${delimiter}dc${delimiter}${index}'
    networkSecurityGroupResourceId: virtualNetwork.properties.subnets[0].properties.networkSecurityGroup.id
    privateIPAddress: cidrHost(virtualNetwork.properties.subnets[0].properties.addressPrefix, index + privateIPAddressOffset)
    storageAccountType: 'Premium_LRS'
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: '${tier.namingConvention.virtualMachine}dc${index}'
    virtualMachineSize: vmSize
  }  
}

module runCommand_DomainControllerPromotion 'run-command.bicep' = {
  name: 'deploy-adds-run-command-${index}-${deploymentNameSuffix}'
  params: {
    asyncExecution: true
    location: location
    mlzTags: mlzTags
    name: 'New-ADDSForest-${index}'
    parameters: [
      {
        name: 'AdminUsername'
        value: adminUsername
      }
      {
        name: 'DomainControllerNumber'
        value: string(index + 1)
      }
      {
        name: 'DomainName'
        value: domainName
      }
      {
        name: 'DNSForwarder'
        value: dnsForwarder
      }
    ]
    protectedParameters: '[{\'name\':\'AdminPassword\',\'value\':\'${adminPassword}\'},{\'name\':\'SafeModeAdminPassword\',\'value\':\'${safeModeAdminPassword}\'}]'
    script: loadTextContent('../artifacts/New-ADDSForest.ps1')
    tags: tags
    treatFailureAsDeploymentFailure: true
    virtualMachineName: virtualMachine.outputs.virtualMachineName
  }
}

output networkInterfaceResourceId string = virtualMachine.outputs.networkInterfaceResourceId
