param location string
param name string
param tags object

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
}
