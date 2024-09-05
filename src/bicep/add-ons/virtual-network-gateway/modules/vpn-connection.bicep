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
resource vpnConnection 'Microsoft.Network/connections@2023-02-01' = if (empty(errorMsg)) {
  name: vpnConnectionName
  location: vgwlocation
  properties: {
    virtualNetworkGateway1: {
      id: resourceId(vpnGatewayResourceGroupName, 'Microsoft.Network/virtualNetworkGateways', vpnGatewayName)
    }
    localNetworkGateway2: {
      id: resourceId(vpnGatewayResourceGroupName, 'Microsoft.Network/localNetworkGateways', localNetworkGatewayName)
    }
    connectionType: 'IPsec'
    routingWeight: 10

    sharedKey: connectionSharedKey

    // Use ipsecPolicies if Key Vault certificate URI is provided
    ipsecPolicies: connectionIpsecPolicies

    // Additional properties as required
    enableBgp: false
    usePolicyBasedTrafficSelectors: false
  }
}
