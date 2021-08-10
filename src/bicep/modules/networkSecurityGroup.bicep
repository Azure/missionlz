param name string
param location string
param tags object = {}

param securityRules array

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    securityRules: securityRules
  }
}

output id string = networkSecurityGroup.id
output name string = networkSecurityGroup.name
