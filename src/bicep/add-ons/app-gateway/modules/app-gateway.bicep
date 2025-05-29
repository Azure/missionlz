@description('Name for the Application Gateway')
param agwName string

@description('Location for the Application Gateway')
param location string

@description('Name of the subnet for the Application Gateway')
param subnetName string

@description('Resource ID of the Virtual Network containing the subnet')
param vnetResourceId string

@description('Backend address pool for the Application Gateway (must match ARM schema)')
param backendAddressPool object

@description('Frontend private IP configuration for the Application Gateway')
param frontendPrivateIpConfig object

@description('Address prefix for the subnet where the Application Gateway will be deployed')
param addressPrefix string

@description('Frontend port configuration (e.g., { name: "frontendPort80", port: 80 })')
param frontendPort object = {
  name: 'frontendPort80'
  port: 80
}

@description('Key Vault resource ID (required if using port 443)')
param keyVaultResourceId string = ''

@description('Name of the certificate in Key Vault (required if using port 443)')
param keyVaultCertName string = ''

@description('Version of the certificate in Key Vault (optional)')
@allowed([
  ''
])
param keyVaultCertVersion string = ''

resource existingVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: split(vnetResourceId, '/')[8]
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  name: subnetName
  parent: existingVnet
  properties: {
    addressPrefix: addressPrefix
  }
}

// Create a user-assigned managed identity for the Application Gateway
resource agwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${agwName}-identity'
  location: location
}

// Assign Key Vault Reader permissions to the managed identity (only if port 443)
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = if (frontendPort.port == 443) {
  name: '${split(keyVaultResourceId, '/')[8]}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: agwIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2022-09-01' = {
  name: agwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${agwIdentity.id}': {}
    }
  }
  sku: {
    name: 'WAF_v2'
    tier: 'WAF_v2'
    capacity: 2
  }
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendPrivateIpConfig.name
        properties: {
          privateIPAddress: frontendPrivateIpConfig.privateIPAddress
          privateIPAllocationMethod: frontendPrivateIpConfig.privateIPAllocationMethod
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPort.name
        properties: {
          port: frontendPort.port
        }
      }
    ]
    sslCertificates: frontendPort.port == 443 ? [
      {
        name: keyVaultCertName
        properties: {
          keyVaultSecretId: keyVaultCertVersion == ''
            ? '${keyVaultResourceId}/secrets/${keyVaultCertName}'
            : '${keyVaultResourceId}/secrets/${keyVaultCertName}/${keyVaultCertVersion}'
        }
      }
    ] : []
    backendAddressPools: [
      backendAddressPool
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings'
        properties: {
          port: frontendPort.port
          protocol: frontendPort.port == 443 ? 'Https' : 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      frontendPort.port == 443 ? {
        name: 'httpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, frontendPrivateIpConfig.name)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, frontendPort.name)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', agwName, keyVaultCertName)
          }
        }
      } : {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, frontendPrivateIpConfig.name)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, frontendPort.name)
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              agwName,
              frontendPort.port == 443 ? 'httpsListener' : 'httpListener'
            )
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agwName, backendAddressPool.name)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agwName, 'httpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}
