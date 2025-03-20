/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param mlzTags object
param name string
param tags object

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Network/networkWatchers'] ?? {}, mlzTags)
  properties: {}
}
