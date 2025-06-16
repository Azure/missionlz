/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}

@description('The name of the identity resource group.')
param identityResourceGroupName string

@description('Prefix the VM names will start with.')
param vmNamePrefix string

@description('Number of VM to build.')
param vmCount int = 2

@description('The size of the Virtual Machine. It defaults to "Standard_DS2_v2".')
param vmSize string = 'Standard_DS2_v2'

@description('The publisher of the Virtual Machine. It defaults to "MicrosoftWindowsServer".')
param vmPublisher string = 'MicrosoftWindowsServer'

@description('The offer of the Virtual Machine. It defaults to "WindowsServer".')
param vmOffer string = 'WindowsServer'

@description('The SKU of the Virtual Machine. It defaults to "2022-datacenter".')
param vmSku string = '2022-datacenter'

@description('The version of the Virtual Machine. It defaults to "latest".')
param vmVersion string = 'latest'

@description('The disk creation option of the Virtual Machine. It defaults to "FromImage".')
param vmCreateOption string = 'FromImage'

@description('The storage account type of the Virtual Machine. It defaults to "StandardSSD_LRS".')
param vmStorageAccountType string = 'StandardSSD_LRS'

@description('The size of the VM Data Disk. It defaults to 16GB.')
param vmDataDiskSizeGB int = 16

@allowed([
  'Static'
  'Dynamic'
])
@description('[Static/Dynamic] The private IP Address allocation method for the Virtual Machine. It defaults to "Static".')
param nicPrivateIPAddressAllocationMethod string = 'Static'

@description('Array of static private IP addresses for the VM Network Interface Cards')
param nicPrivateIPAddresses array = []

@description('The resource ID of the identity virtual network subnet.')
param identityVirtualNetworkSubnetId string

@description('Uri to the container that contains the DSC configuration and the Custom Script')
param extensionsFilesContainerUri string = 'https://raw.githubusercontent.com/Azure/missionlz/main/src/bicep/add-ons/active-directory-domain-services/iaas/extensions'

@description('SAS Token to access the container that contains the DSC configuration and the Custom Script. Defaults to none for a public container')
@secure()
param extensionsFilesContainerSas string = ''

@description('New AD forest DSC Configurations Name')
param newForestDscConfigName string = 'firstDomainController'

@description('Add to existing domain DSC Configurations Name')
param addDcDscConfigName string = 'secondDomainController'

@description('Active Directory DNS Domain Name')
param dnsDomainName string

@description('Active Directory Netbios Domain Name')
param netbiosDomainName string

@description('DNS Forwarder IP Addresses that gets configured in the Windows DNS server. Defaults to Azure DNS servers.')
param dnsForwarders array = ['168.63.129.16']

@description('Whether to create a new Active Directory Forest, or add the domain controllers to an existing domain.')
@allowed([
  'NewForest'
  'AddToExistingDomain'
])
param createOrAdd string = 'NewForest'

@description('Management Subnets IP Prefixes that get allowed in the Windows Firewall')
param managementSubnets array

@description('Domain Administrator Username')
param domainAdminUsername string

@description('Domain Administrator password')
@secure()
param domainAdminPassword string

@description('Sademode Administrator Username')
param safemodeAdminUsername string

@description('Sademode Administrator Password')
@secure()
param safemodeAdminPassword string

@description('Domain Join User Username')
param domainJoinUsername string

@description('Domain Join User Password')
@secure()
param domainJoinUserPassword string

var vmAvSetName = '${vmNamePrefix}-avset-01'
var NetworkInterfaceIpConfigurationName = 'ipConfiguration1'

module addsResources 'active-directory-domain-controllers-resources.bicep' = {
  name: 'deploy-adds-resources'
  scope: resourceGroup(identityResourceGroupName)
  params: {
    location: location
    tags: tags
    vmNamePrefix: vmNamePrefix
    vmCount: vmCount
    vmSize: vmSize
    vmPublisher: vmPublisher
    vmOffer: vmOffer
    vmSku: vmSku
    vmVersion: vmVersion
    vmCreateOption: vmCreateOption
    vmStorageAccountType: vmStorageAccountType
    vmDataDiskSizeGB: vmDataDiskSizeGB
    nicPrivateIPAddressAllocationMethod: nicPrivateIPAddressAllocationMethod
    nicPrivateIPAddresses: nicPrivateIPAddresses
    identityVirtualNetworkSubnetId: identityVirtualNetworkSubnetId
    extensionsFilesContainerUri: extensionsFilesContainerUri
    extensionsFilesContainerSas: extensionsFilesContainerSas
    newForestDscConfigName: newForestDscConfigName
    addDcDscConfigName: addDcDscConfigName
    dnsDomainName: dnsDomainName
    netbiosDomainName: netbiosDomainName
    dnsForwarders: dnsForwarders
    createOrAdd: createOrAdd
    managementSubnets: managementSubnets
    domainAdminUsername: domainAdminUsername
    domainAdminPassword: domainAdminPassword
    safemodeAdminUsername: safemodeAdminUsername
    safemodeAdminPassword: safemodeAdminPassword
    domainJoinUsername: domainJoinUsername
    domainJoinUserPassword: domainJoinUserPassword
    vmAvSetName: vmAvSetName
    NetworkInterfaceIpConfigurationName: NetworkInterfaceIpConfigurationName
  }
}

output domainControllerVMResourceIds array = addsResources.outputs.domainControllerVMResourceIds
output domainControllerVMNames array = addsResources.outputs.domainControllerVMNames  
output domainControllerPrivateIPAddresses array = addsResources.outputs.domainControllerPrivateIPAddresses