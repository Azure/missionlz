@description('MLZ Deployment output variables in json format. It defaults to the deploymentVariables.json.')
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))
param hubVirtualNetworkSubnetId string = mlzDeploymentVariables.hub.Value.subnetResourceId
param logAnalyticsWorkspaceResourceId string = mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = resourceGroup().location

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}

@description('Prefix the VM names will start with.')
param vmNamePrefix string

@description('Number of VM to build.')
param vmCount int = 2

@description('The administrator username for the Virtual Machine to remote into.')
param vmAdminUsername string = 'azureuser'

@description('The administrator password the Virtual Machine to remote into. It must be > 12 characters in length. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.')
@secure()
@minLength(12)
param vmAdminPassword string

@description('The size of the Virtual Machine. It defaults to "Standard_DS1_v2".')
param vmSize string = 'Standard_DS1_v2'

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

@allowed([
  'Static'
  'Dynamic'
])
@description('[Static/Dynamic] The private IP Address allocation method for the Virtual Machine. It defaults to "Static".')
param nicPrivateIPAddressAllocationMethod string = 'Static'

@description('Array of static private IP addresses for the VM Network Interface Cards')
param nicPrivateIPAddresses array = []

@description('Uri to the container that contains the DSC configuration and the Custom Script')
param extensionsFilesContainerUri string = 'https://raw.githubusercontent.com/Azure/missionlz/main/src/bicep/examples/iaas-dns-forwarders/extensions'

@description('SAS Token to access the container that contains the DSC configuration and the Custom Script. Defaults to none for a public container')
@secure()
param extensionsFilesContainerSas string = ''

@description('DSC Configurations Name')
param dscConfigName string = 'dnsForwarding'

@description('DNS Server Forwarders IP Addresses that get configured in the Windows DNS server. Defaults to Azure DNS servers.')
param dnsServerForwardersIpAddresses array = ['168.63.129.16']

@description('Custom Script file name')
param customScriptName string ='Set-ConditionalDnsForwarders.ps1'

@description('Custom Conditional DNS Forwarders that get configured in the Windows DNS server. Defaults to AzureUSGov Private Endpoint DNS Zones.')
param conditionalDnsServerForwarders array = [
  {
    Name: 'azure-automation.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'database.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'blob.core.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'table.core.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'queue.core.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'file.core.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'web.core.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'documents.azure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'batch.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'service.batch.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'postgres.database.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'mysql.database.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'mariadb.database.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'vault.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'vaultcore.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'search.windows.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'azconfig.azure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'backup.windowsazure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'siterecovery.windowsazure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'servicebus.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'servicebus.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'azure-devices.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'servicebus.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'azurewebsites.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'adx.monitor.azure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'oms.opinsights.azure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'ods.opinsights.azure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'agentsvc.azure-automation.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'cognitiveservices.azure.us'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'redis.cache.usgovcloudapi.net'
    Forwarders: ['168.63.129.16']
  }
  {
    Name: 'azurehdinsight.us'
    Forwarders: ['168.63.129.16']
  }
]

var vmAvSetName = '${vmNamePrefix}-avset-01'
var NetworkInterfaceIpConfigurationName = 'ipConfiguration1'
var sasToken = ((extensionsFilesContainerSas != '') ? '?${extensionsFilesContainerSas}' : '')

resource vmAvSet 'Microsoft.Compute/availabilitySets@2022-03-01' = {
  name: vmAvSetName
  location: location
  tags: tags
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = [for i in range(0, vmCount): {
  name: '${vmNamePrefix}-0${(i + 1)}-nic-01'
  location: location
  tags: tags

  properties: {
    ipConfigurations: [
      {
        name: NetworkInterfaceIpConfigurationName
        properties: {
          subnet: {
            id: hubVirtualNetworkSubnetId
          }
          privateIPAllocationMethod: nicPrivateIPAddressAllocationMethod
          privateIPAddress: ((nicPrivateIPAddressAllocationMethod == 'Static') ? nicPrivateIPAddresses[i] : null)
        }
      }
    ]
  }
}]

module dnsForwarderVirtualMachine '../../modules/windows-virtual-machine.bicep' = [for vmi in range(0, vmCount): {
  name: 'dnsForwarderVirtualMachines${(vmi + 1)}'
  params: {
    name: '${vmNamePrefix}-0${(vmi + 1)}'
    location: location
    tags: tags

    size: vmSize
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    publisher: vmPublisher
    offer: vmOffer
    sku: vmSku
    version: vmVersion
    createOption: vmCreateOption
    storageAccountType: vmStorageAccountType
    networkInterfaceName: '${vmNamePrefix}-0${(vmi + 1)}-nic-01'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    availabilitySet: {
      id: vmAvSet.id
    }
  }
  dependsOn: [
    networkInterface
  ]
}]

resource dnsForwarderVirtualMachines 'Microsoft.Compute/virtualMachines@2022-03-01' existing = [for i in range(0, vmCount): {
  name: '${vmNamePrefix}-0${(i + 1)}'
}]

resource DSC 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, vmCount): {
  name: 'Microsoft.Powershell.DSC'
  parent: dnsForwarderVirtualMachines[i]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.24'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${extensionsFilesContainerUri}/${dscConfigName}.ps1.zip${sasToken}'
        script: '${dscConfigName}.ps1'
        function: dscConfigName
      }
      configurationArguments: {
        dnsServerForwarders: dnsServerForwardersIpAddresses        
      }
    }
  }
  dependsOn: [
    dnsForwarderVirtualMachine
  ]
}]

resource customScript 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = [for i in range(0, vmCount): if(conditionalDnsServerForwarders != []){
  name: 'CustomScriptExt'
  location: location
  parent: dnsForwarderVirtualMachines[i]
  dependsOn: [
    DSC
  ]
  properties: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      commandToExecute: 'Powershell.exe -ExecutionPolicy Unrestricted -File ${customScriptName} -conditionalDnsForwardersJSON ${conditionalDnsServerForwarders}'
    }    
    protectedSettings: {
      fileUris: [
        '${extensionsFilesContainerUri}/${customScriptName}${sasToken}'
      ]
    }
  }
}]
