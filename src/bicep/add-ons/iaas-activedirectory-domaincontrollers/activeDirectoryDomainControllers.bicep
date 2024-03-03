@description('MLZ Deployment output variables in json format. It defaults to the deploymentVariables.json.')
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))
param identityVirtualNetworkSubnetId string = mlzDeploymentVariables.spokes.Value[0].subnetResourceId
param logAnalyticsWorkspaceResourceId string = mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = resourceGroup().location

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}

@description('Prefix the VM names will start with.')
param vmNamePrefix string

@description('Number of VM to build.')
param vmCount int = 2

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

@description('Uri to the container that contains the DSC configuration and the Custom Script')
param extensionsFilesContainerUri string = 'https://raw.githubusercontent.com/Azure/missionlz/main/src/bicep/examples/iaas-dns-forwarders/extensions'

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
            id: identityVirtualNetworkSubnetId
          }
          privateIPAllocationMethod: nicPrivateIPAddressAllocationMethod
          privateIPAddress: ((nicPrivateIPAddressAllocationMethod == 'Static') ? nicPrivateIPAddresses[i] : null)
        }
      }
    ]
  }
}]

module domainControllerVM '../../modules/windows-virtual-machine.bicep' = [for vmi in range(0, vmCount): {
  name: 'domainControllerVirtualMachines${(vmi + 1)}'
  params: {
    name: '${vmNamePrefix}-0${(vmi + 1)}'
    location: location
    tags: tags

    size: vmSize
    adminUsername: domainAdminUsername
    adminPassword: domainAdminPassword
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
    dataDisks: [
      {
        createOption: 'Empty'
        caching: 'None'
        diskSizeGB: vmDataDiskSizeGB
        lun: 1
        name: '${vmNamePrefix}-0${(vmi + 1)}-dataDisk-1'
        managedDisk: {          
          storageAccountType: vmStorageAccountType
        }
      }
    ]
  }
  dependsOn: [
    networkInterface
  ]
}]

resource domainControllerVirtualMachines 'Microsoft.Compute/virtualMachines@2022-03-01' existing = [for i in range(0, vmCount): {
  name: '${vmNamePrefix}-0${(i + 1)}'
}]

resource NewADForestDSC 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if(createOrAdd == 'NewForest') {
  name: 'NewADForestDSC'
  parent: domainControllerVirtualMachines[0]  
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.24'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${extensionsFilesContainerUri}/${newForestDscConfigName}.ps1.zip${sasToken}'
        script: '${newForestDscConfigName}.ps1'
        function: newForestDscConfigName
      }
      configurationArguments: {
        dnsDomainName: dnsDomainName
        netbiosDomainName: netbiosDomainName
        dnsForwarders: dnsForwarders
        managementSubnets: managementSubnets
      }
    }
    protectedSettings: {
      configurationArguments: {
        domainAdminCredentials: {
          UserName: domainAdminUsername
          Password: domainAdminPassword
        }
        safemodeAdminCredentials: {
          UserName: safemodeAdminUsername
          Password: safemodeAdminPassword
        }
        domainJoinUserCredentials: {
          UserName: domainJoinUsername
          Password: domainJoinUserPassword
        }
      }
    }
  }
  dependsOn: [
    domainControllerVM
  ]
}

resource AddFirstDCDSC 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if(createOrAdd == 'AddToExistingDomain') {
  name: 'AddFirstDCDSC'
  parent: domainControllerVirtualMachines[0]  
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.24'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${extensionsFilesContainerUri}/${addDcDscConfigName}.ps1.zip${sasToken}'
        script: '${addDcDscConfigName}.ps1'
        function: addDcDscConfigName
      }
      configurationArguments: {
        dnsDomainName: dnsDomainName
        dnsForwarders: dnsForwarders
        managementSubnets: managementSubnets
      }
    }
    protectedSettings: {
      configurationArguments: {
        domainAdminCredentials: {
          UserName: '${netbiosDomainName}\\${domainAdminUsername}'
          Password: domainAdminPassword
        }
        safemodeAdminCredentials: {
          UserName: safemodeAdminUsername
          Password: safemodeAdminPassword
        }
      }
    }
  }
  dependsOn: [
    domainControllerVM
  ]
}

resource AddSecondDCDSC 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: 'AddSecondDCDSC'
  parent: domainControllerVirtualMachines[1]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.24'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${extensionsFilesContainerUri}/${addDcDscConfigName}.ps1.zip${sasToken}'
        script: '${addDcDscConfigName}.ps1'
        function: addDcDscConfigName
      }
      configurationArguments: {
        dnsDomainName: dnsDomainName
        dnsForwarders: dnsForwarders
        managementSubnets: managementSubnets
      }
    }
    protectedSettings: {
      configurationArguments: {
        domainAdminCredentials: {
          UserName: '${domainAdminUsername}@${dnsDomainName}'
          Password: domainAdminPassword
        }
        safemodeAdminCredentials: {
          UserName: safemodeAdminUsername
          Password: safemodeAdminPassword
        }
      }
    }
  }
  dependsOn: [
    NewADForestDSC
    AddFirstDCDSC
  ]
}
