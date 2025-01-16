/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@description('Optional. The idle timeout of the NAT gateway.')
param idleTimeoutInMinutes int = 5

@description('Optional. Location for all resources.')
param location string

param mlzTags object

@description('Required. Name of the Azure NAT Gateway resource.')
param name string

@description('Optional. Existing Public IP Address resource IDs to use for the NAT Gateway.')
param publicIpResourceIds array = []

@description('Optional. Existing Public IP Prefixes resource IDs to use for the NAT Gateway.')
param publicIPPrefixResourceIds array = []

@description('Optional. Tags for the resource.')
param tags object = {}

@description('Optional. A list of availability zones denoting the zone in which Nat Gateway should be deployed.')
@allowed([
  0
  1
  2
  3
])
param zone int = 0

resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/natGateways') ? tags['Microsoft.Network/natGateways'] : {}, mlzTags)
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIpAddresses: publicIpResourceIds
    publicIpPrefixes: publicIPPrefixResourceIds
  }
  zones: zone != 0 ? [string(zone)] : []
}

output name string = natGateway.name
output id string = natGateway.id
