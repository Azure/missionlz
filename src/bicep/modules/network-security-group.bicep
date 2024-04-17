/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param mlzTags object
param name string
param securityRules array
param tags object

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/networkSecurityGroups') ? tags['Microsoft.Network/networkSecurityGroups'] : {}, mlzTags)
  properties: {
    securityRules: securityRules
  }
}

output id string = networkSecurityGroup.id
output name string = networkSecurityGroup.name
