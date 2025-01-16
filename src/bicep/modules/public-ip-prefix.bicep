/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@description('Optional. The custom IP address prefix that this prefix is associated with. A custom IP address prefix is a contiguous range of IP addresses owned by an external customer and provisioned into a subscription. When a custom IP prefix is in Provisioned, Commissioning, or Commissioned state, a linked public IP prefix can be created. Either as a subset of the custom IP prefix range or the entire range.')
param customIPPrefix object = {}

@description('Optional. Location for all resources.')
param location string

param mlzTags object

@description('Required. The name of the Public IP Prefix.')
@minLength(1)
param name string

@description('Required. Length of the Public IP Prefix.')
@minValue(21)
@maxValue(127)
param prefixLength int

@description('Optional. The public IP address version.')
@allowed([
  'IPv4'
  'IPv6'
])
param publicIPAddressVersion string = 'IPv4'

param tags object = {}

@description('Optional. Tier of a public IP prefix SKU. If set to `Global`, the `zones` property must be empty.')
@allowed([
  'Global'
  'Regional'
])
param tier string = 'Regional'

@description('Optional. A list of availability zones denoting the IP allocated for the resource needs to come from. This is only applicable for regional public IP prefixes and must be empty for global public IP prefixes.')
@allowed([
  1
  2
  3
])
param zones int[] = [
  1
  2
  3
]

resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2024-05-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/publicIPPrefixes') ? tags['Microsoft.Network/publicIPPrefixes'] : {}, mlzTags)
  sku: {
    name: 'Standard'
    tier: tier
  }
  zones: map(zones, zone => string(zone))
  properties: {
    customIPPrefix: !empty(customIPPrefix) ? customIPPrefix : null
    publicIPAddressVersion: publicIPAddressVersion
    prefixLength: prefixLength
  }
}

output name string = publicIpPrefix.name
output id string = publicIpPrefix.id
