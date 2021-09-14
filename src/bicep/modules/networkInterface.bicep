param name string
param location string
param tags object = {}

param ipConfigurationName string
param subnetId string
param networkSecurityGroupId string
param privateIPAddressAllocationMethod string

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    ipConfigurations: [
      {
        name: ipConfigurationName
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: privateIPAddressAllocationMethod
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
  }
}

output id string = networkInterface.id
output name string = networkInterface.name
