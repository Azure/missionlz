param applicationGatewayName string
param applicationGatewayPrivateIpAddress string
param externalDnsHostName string
param joinWindowsDomain bool
param keyVaultUri string
param location string
param portalBackendSslCert string
param portalVirtualMachineNames string
param publicIpId string
param resourceGroup string
param resourceSuffix string
param serverBackendSSLCert string
param serverVirtualMachineNames string
param userAssignedIdenityResourceId string
param virtualNetworkName string
param windowsDomainName string


var serverBackEndVirtualMachines = split(serverVirtualMachineNames, ',')
var portalBackEndVirtualMachines = split(portalVirtualMachineNames, ',')
var nicDnsSuffix ='${split(externalDnsHostName, '.')[1]}.${split(externalDnsHostName, '.')[2]}'

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-06-01' = {
  name: applicationGatewayName
  location: location
  tags: {
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdenityResourceId}': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId(resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'appGatewaySubnet')
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'frontendCert'
        properties: {
          keyVaultSecretId: '${keyVaultUri}secrets/pfx${location}'
        }
      }
    ]
    trustedRootCertificates: [
      {
        name: 'serverBackendSSLCert'
        properties: {
          data: serverBackendSSLCert
        }
        }
      {
        name: 'portalBackendSSLCert'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'portalBackendSSLCert')
        properties: {
          data: portalBackendSslCert
        }
      }
    ]
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'pipIpConfig'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'EnterpriseAppGatewayFrontendIP${resourceSuffix}')
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
      {
        name: 'EnterpriseAppGatewayFrontendIP${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'EnterpriseAppGatewayFrontendIP${resourceSuffix}')
        properties: {
          privateIPAddress: applicationGatewayPrivateIpAddress
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId(resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'appGatewaySubnet')
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'EnterprisePort443${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'EnterprisePort443${resourceSuffix}')
        properties: {
          port: 443
        }
      }
      {
        name: 'EnterprisePort80${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'EnterprisePort80${resourceSuffix}')
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'ServerBackendPool${resourceSuffix}'
        properties: {
            backendAddresses: [for vm in serverBackEndVirtualMachines : {
              fqdn: joinWindowsDomain ? '${vm}.${windowsDomainName}' : '${vm}.${nicDnsSuffix}'
            }]
        }
      }
      {
        name: '${resourceSuffix}PortalBackendPool'
        properties: {
          backendAddresses: [for vm in portalBackEndVirtualMachines : {
              fqdn: joinWindowsDomain ? '${vm}.${windowsDomainName}' : '${vm}.${nicDnsSuffix}'
            }]
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'PortalHttpsSetting${resourceSuffix}'
        properties: {
          port: 7443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: true
            drainTimeoutInSec: 60
          }
          pickHostNameFromBackendAddress: true
          path: '/arcgis/'
          requestTimeout: 180
          probe: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/probes', applicationGatewayName, '${resourceSuffix}PortalProbeName')
          }
          trustedRootCertificates: [
            {
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'portalBackendSSLCert')
            }
          ]
        }
      }
      {
        name: 'ServerHttpsSetting${resourceSuffix}'
        properties: {
          port: 6443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: true
            drainTimeoutInSec: 60
          }
          pickHostNameFromBackendAddress: true
          path: '/arcgis/'
          requestTimeout: 180
          probe: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/probes', applicationGatewayName, '${resourceSuffix}ServerProbeName')
          }
          trustedRootCertificates: [
            {
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'serverBackendSSLCert')
            }
          ]
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: '${resourceSuffix}HttpEnterpriseDeploymentListner'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'EnterpriseAppGatewayFrontendIP${resourceSuffix}')
          }
          frontendPort: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'EnterprisePort80${resourceSuffix}')
          }
          protocol: 'Http'
          hostNames:  [
            externalDnsHostName
          ]
          requireServerNameIndication: false
        }
      }
      {
        name: '${resourceSuffix}HttpsEnterpriseDeploymentListner'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'EnterpriseAppGatewayFrontendIP${resourceSuffix}')
          }
          frontendPort: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'EnterprisePort443${resourceSuffix}')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'frontendCert')
          }
          hostNames: [
            externalDnsHostName
          ]
          requireServerNameIndication: false
        }
      }
    ]
    listeners: []
    urlPathMaps: [
      {
        name: '${resourceSuffix}EnterprisePathMap'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ServerBackendPool${resourceSuffix}')
          }
          defaultBackendHttpSettings: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'ServerHttpsSetting${resourceSuffix}')
          }
          pathRules: [
            {
              name: 'serverPathRule'
              properties: {
                paths: [
                  '/server/*'
                  '/server'
                ]
                backendAddressPool: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ServerBackendPool${resourceSuffix}')
                }
                backendHttpSettings: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'ServerHttpsSetting${resourceSuffix}')
                }
                rewriteRuleSet: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, '${resourceSuffix}ServerRewriteRuleSet')
                }
              }
            }
            {
              name: 'portalPathRule'
              properties: {
                paths: [
                  '/portal/*'
                  '/portal'
                ]
                backendAddressPool: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, '${resourceSuffix}PortalBackendPool')
                }
                backendHttpSettings: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'PortalHttpsSetting${resourceSuffix}')
                }
                rewriteRuleSet: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, '${resourceSuffix}PortalRewriteRuleSet')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: '${resourceSuffix}EnterpriseRequestRoutingRule'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 10
          httpListener: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, '${resourceSuffix}HttpsEnterpriseDeploymentListner')
          }
          urlPathMap: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/urlPathMaps', applicationGatewayName, '${resourceSuffix}EnterprisePathMap')
          }
        }
      }
      {
        name: '${resourceSuffix}HttpToHttpsEnterpriseRequestRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 20
          httpListener: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, '${resourceSuffix}HttpEnterpriseDeploymentListner')
          }
          redirectConfiguration: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, '${resourceSuffix}EnterpriseHttpToHttps')
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: '${resourceSuffix}ServerProbeName'
        properties: {
          protocol: 'Https'
          path: '/arcgis/rest/info/healthcheck'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200'
            ]
          }
        }
      }
      {
        name: '${resourceSuffix}PortalProbeName'
        properties: {
          protocol: 'Https'
          path: '/arcgis/portaladmin/healthCheck'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: [
      {
        name: '${resourceSuffix}PortalRewriteRuleSet'
        properties: {
          rewriteRules: [
            {
              ruleSequence: 50
              conditions: []
              name: 'XForwardedHostRewrite'
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'X-Forwarded-Host'
                    headerValue: '{http_req_host}'
                  }
                ]
                responseHeaderConfigurations: []
              }
            }
            {
              ruleSequence: 100
              conditions: [
                {
                  variable: 'http_resp_Location'
                  pattern: '(https?):\\/\\/[^\\/]+:7443\\/(?:arcgis|portal)(.*)$'
                  ignoreCase: true
                  negate: false
                }
              ]
              name: 'PortalRewrite'
              actionSet: {
                requestHeaderConfigurations: []
                responseHeaderConfigurations: [
                  {
                    headerName: 'RewriteLocationValue'
                    headerValue: '{http_resp_Location_1}://{http_req_host}/portal{http_resp_Location_2}'
                  }
                  {
                    headerName: 'Location'
                    headerValue: '{http_resp_Location_1}://{http_req_host}/portal{http_resp_Location_2}'
                  }
                ]
              }
            }
          ]
        }
      }
      {
        name: '${resourceSuffix}ServerRewriteRuleSet'
        properties: {
          rewriteRules: [
            {
              ruleSequence: 50
              conditions: []
              name: 'XForwardedHostRewrite'
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'X-Forwarded-Host'
                    headerValue: '{http_req_host}'
                  }
                ]
                responseHeaderConfigurations: []
              }
            }
            {
              ruleSequence: 100
              conditions: [
                {
                  variable: 'http_resp_Location'
                  pattern: '(https?):\\/\\/[^\\/]+:6443\\/(?:arcgis|server)(.*)$'
                  ignoreCase: true
                  negate: false
                }
              ]
              name: 'ServerRewrite'
              actionSet: {
                requestHeaderConfigurations: []
                responseHeaderConfigurations: [
                  {
                    headerName: 'RewriteLocationValue'
                    headerValue: '{http_resp_Location_1}://{http_req_host}/server{http_resp_Location_2}'
                  }
                  {
                    headerName: 'Location'
                    headerValue: '{http_resp_Location_1}://{http_req_host}/server{http_resp_Location_2}'
                  }
                ]
              }
            }
          ]
        }
      }
    ]
    redirectConfigurations: [
      {
        name: '${resourceSuffix}EnterpriseHttpToHttps'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, '${resourceSuffix}HttpsEnterpriseDeploymentListner')
          }
          includePath: true
          includeQueryString: true
          requestRoutingRules: [
            {
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/requestRoutingRules', applicationGatewayName, '${resourceSuffix}HttpToHttpsEnterpriseRequestRoutingRule')
            }
          ]
        }
      }
    ]
    privateLinkConfigurations: [
      // {
      //   name: 'pl'
      //   id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/privateLinkConfigurations', applicationGatewayName, 'pl')
      //   properties: {
      //     ipConfigurations: [
      //       {
      //         name: 'privateLinkIpConfig1'
      //         id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/privateLinkConfigurations/ipConfigurations', applicationGatewayName, 'pl', 'privateLinkIpConfig1')
      //         properties: {
      //           privateIPAllocationMethod: 'Dynamic'
      //           primary: false
      //           subnet: {
      //             id: resourceId(resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'appGatewaySubnet')
      //           }
      //         }
      //       }
      //     ]
      //   }
      // }
    ]
  }
}

// resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
//   name: 'pe'
//   location: location
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: 'pl'
//         properties: {
//           privateLinkServiceId: keyVault.id
//           groupIds: [
//             '${applicationGatewayName}-privIp'
//           ]
//         }
//       }
//     ]
//     manualPrivateLinkServiceConnections: []
//     subnet: {
//       id: resourceId(resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'appGatewaySubnet')
//     }
//   }
// }

output applicationGatewayPrivateIpAddress string = applicationGateway.properties.frontendIPConfigurations[1].properties.privateIPAddress
