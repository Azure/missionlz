param name string
param location string
param tags object = {}

param virtualNetworkName string

var subnetName = 'AzureBastionSubnet' // The subnet name for Azure Bastion Hosts must be 'AzureBastionSubnet'
param subnetAddressPrefix string

param publicIPAddressName string
param publicIPAddressSkuName string
param publicIPAddressAllocationMethod string
param publicIPAddressAvailabilityZones array

param ipConfigurationName string

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIPAddressName
  location: location
  tags: tags

  sku: {
    name: publicIPAddressSkuName
  }

  properties: {
    publicIPAllocationMethod: publicIPAddressAllocationMethod
  }

  zones: publicIPAddressAvailabilityZones
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${virtualNetworkName}/${subnetName}'

  properties: {
    addressPrefix: subnetAddressPrefix
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    ipConfigurations: [
      {
        name: ipConfigurationName
        properties: {
          subnet: {
            id: subnet.id
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
  }
}
