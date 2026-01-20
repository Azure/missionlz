param vpnConnectionName string
param vgwlocation string
param vpnGatewayName string
param vpnGatewayResourceGroupName string
param sharedKey string
param keyVaultCertificateUri string
param localNetworkGatewayName string

// Determine if either sharedKey or keyVaultCertificateUri is provided
var useSharedKey = !empty(sharedKey)
var useKeyVaultCertificate = !empty(keyVaultCertificateUri)

// Conditional validation through variables
var errorMsg = (useSharedKey && useKeyVaultCertificate) ? 'Cannot provide both sharedKey and keyVaultCertificateUri' : ''
var connectionSharedKey = useSharedKey ? sharedKey : null
var connectionIpsecPolicies = useKeyVaultCertificate ? [
  // disable-next-line BCP035
  {
    saLifeTimeSeconds: 3600
    saDataSizeKilobytes: 102400000
    ipsecEncryption: 'AES256'
    ipsecIntegrity: 'SHA256'
    ikeEncryption: 'AES256'
    ikeIntegrity: 'SHA256'
    dhGroup: 'DHGroup2'
    pfsGroup: 'PFS2'
  }
] : null

// Deploy the VPN connection only if the conditions are met
// Schema requires only id references for nested gateway objects; suppress warning.
// disable-next-line BCP035
resource vpnConnection 'Microsoft.Network/connections@2023-02-01' = if (empty(errorMsg)) {
  name: vpnConnectionName
  location: vgwlocation
  properties: {
    // disable-next-line BCP035
    virtualNetworkGateway1: {
      id: resourceId(vpnGatewayResourceGroupName, 'Microsoft.Network/virtualNetworkGateways', vpnGatewayName)
      // Bicep type model expects properties; Azure accepts id-only. Provide empty object to satisfy linter.
      properties: {}
    }
    // disable-next-line BCP035
    localNetworkGateway2: {
      id: resourceId(vpnGatewayResourceGroupName, 'Microsoft.Network/localNetworkGateways', localNetworkGatewayName)
      properties: {}
    }
    connectionType: 'IPsec'
    routingWeight: 10

    sharedKey: connectionSharedKey

    // Use ipsecPolicies if Key Vault certificate URI is provided
    ipsecPolicies: connectionIpsecPolicies == null ? [] : connectionIpsecPolicies

    // Additional properties as required
    enableBgp: false
    usePolicyBasedTrafficSelectors: false
  }
}
