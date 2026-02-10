param dnsServers array
param enableProxy bool
param intrusionDetectionMode string
param location string
param name string
param skuTier string
param tags object
param threatIntelMode string

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    threatIntelMode: threatIntelMode
    intrusionDetection: skuTier == 'Premium' ? {
      mode: intrusionDetectionMode
    } : null
    sku: {
      tier: skuTier
    }
    dnsSettings: {
      enableProxy: enableProxy
      servers: dnsServers
    }
  }
}
