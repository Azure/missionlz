@description('Name for the Application Gateway')
param agwName string

@description('Location for the Application Gateway')
param location string

@description('Resource ID of the subnet for the Application Gateway')
param subnetResourceId string

@description('Backend address pool for the Application Gateway (must match ARM schema)')
param backendAddressPool object

@description('Frontend private IP configurations for the Application Gateway')
param frontendPrivateIpConfigs array

@description('Frontend port configurations (array of objects: { name, port })')
param frontendPorts array

@description('Key Vault resource ID (required if using port 443)')
param keyvaultUri string = ''

@description('Name of the certificate in Key Vault (required if using port 443)')
param keyVaultCertName string = ''

@description('Version of the certificate in Key Vault (optional)')
param keyVaultCertVersion string = ''

@description('Minimum autoscale instances')
param autoscaleMinCapacity int = 2

@description('Maximum autoscale instances')
param autoscaleMaxCapacity int = 10

@description('Web Application Firewall configuration for the Application Gateway')
param webApplicationFirewallConfiguration object

@description('User-assigned managed identity resource ID')
param identityResourceId string


var normalizedFrontendPrivateIpConfigs = [
  for ipConfig in frontendPrivateIpConfigs: {
    name: ipConfig.name
    privateIPAllocationMethod: empty(ipConfig.privateIPAllocationMethod) ? 'Static' : ipConfig.privateIPAllocationMethod
    privateIPAddress: contains(ipConfig, 'privateIPAddress') ? ipConfig.privateIPAddress : null
  }
]

// Precompute values outside of resource definition
var frontendIpConfigs = [
  for ipConfig in normalizedFrontendPrivateIpConfigs: {
    name: ipConfig.name
    properties: union(
      {
        privateIPAllocationMethod: ipConfig.privateIPAllocationMethod
        subnet: {
          id: subnetResourceId
        }
      },
      empty(ipConfig.privateIPAddress) ? {} : {
        privateIPAddress: ipConfig.privateIPAddress
      }
    )
  }
]

var frontendPortConfigs = [for port in frontendPorts: {
  name: port.name
  properties: {
    port: port.port
  }
}]

var sslCert = keyVaultCertName == '' ? [] : [{
  name: keyVaultCertName
  properties: {
    keyVaultSecretId: keyVaultCertVersion == ''
    ? '${keyvaultUri}/secrets/${keyVaultCertName}'
    : '${keyvaultUri}/secrets/${keyVaultCertName}/${keyVaultCertVersion}'
  }
}]

var listenerNames = [for port in frontendPorts: port.port == 443 ? 'httpsListener${port.name}' : 'httpListener${port.name}']

var backendHttpSettings = [for port in frontendPorts: {
  name: 'httpSettings${port.name}'
  properties: {
    port: port.port
    protocol: port.port == 443 ? 'Https' : 'Http'
    cookieBasedAffinity: 'Disabled'
  }
}]

resource appGateway 'Microsoft.Network/applicationGateways@2022-09-01' = {
  name: agwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityResourceId}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_V2'
      tier: 'WAF_V2'
    }
    autoscaleConfiguration: {
      minCapacity: autoscaleMinCapacity
      maxCapacity: autoscaleMaxCapacity
    }
    enableHttp2: true
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    frontendIPConfigurations: frontendIpConfigs
    frontendPorts: frontendPortConfigs
    sslCertificates: sslCert
    backendAddressPools: [backendAddressPool]
    backendHttpSettingsCollection: backendHttpSettings
    httpListeners: [
      for (port, i) in frontendPorts: {
        name: listenerNames[i]
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, frontendIpConfigs[i % length(frontendIpConfigs)].name)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, port.name)
          }
          protocol: port.port == 443 ? 'Https' : 'Http'
          sslCertificate: port.port == 443 ? {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', agwName, keyVaultCertName)
          } : null
        }
      }
    ]
    requestRoutingRules: [
      for port in frontendPorts: {
        name: 'rule${port.name}'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agwName, port.port == 443 ? 'httpsListener${port.name}' : 'httpListener${port.name}')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agwName, backendAddressPool.name)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agwName, 'httpSettings${port.name}')
          }
          priority: 100 + port.port // Ensure unique priorities
        }
      }
    ]
    webApplicationFirewallConfiguration: webApplicationFirewallConfiguration
  }
}

output appGatewayId string = appGateway.id
output appGatewayName string = appGateway.name
