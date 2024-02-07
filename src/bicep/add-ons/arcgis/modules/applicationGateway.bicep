param applicationGatewayName string
param frontEndCert string
param hostname string
param iDns string
param location string
param portalBackendSslCert string
param publicIpId string
param resourceGroup string
param resourceSuffix string
param serverBackendSSLCert string
param tags object
param userAssignedIdenityResourceId string
param virtualNetworkName string
param vmName string

resource applicationGateway 'Microsoft.Network/networkInterfaceInternalDomainNameSuffix@2023-04-01' = {
  name: applicationGatewayName
  location: location
  tags: contains(tags, 'Microsoft.Network/applicationGateways') ? tags['Microsoft.Network/applicationGateways'] : {}
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
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/gatewayIPConfigurations', applicationGatewayName, 'appGatewayIpConfig')
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
          data: frontEndCert
          password: '*.${location}.cloudapp.azure.com'
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
        name: 'EnterpriseAppGatewayFrontendIP${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'EnterpriseAppGatewayFrontendIP${resourceSuffix}')
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpId
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
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ServerBackendPool${resourceSuffix}')
        properties: {
          backendAddresses: [
            {
              fqdn: '${vmName}.${iDns}'
            }
          ]
        }
      }
      {
        name: 'PortalBackendPool${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName , 'PortalBackendPool${resourceSuffix}')
        properties: {
          backendAddresses: [
            {
              fqdn: '${vmName}.${iDns}'
            }
          ]
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'PortalHttpsSetting${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'PortalHttpsSetting${resourceSuffix}')
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
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'PortalProbeName${resourceSuffix}')
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
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'ServerHttpsSetting${resourceSuffix}')
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
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'ServerProbeName${resourceSuffix}')
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
        name: 'HttpEnterpriseDeploymentListner${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'HttpEnterpriseDeploymentListner${resourceSuffix}')
        properties: {
          frontendIPConfiguration: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'EnterpriseAppGatewayFrontendIP${resourceSuffix}')
          }
          frontendPort: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'EnterprisePort80${resourceSuffix}')
          }
          protocol: 'Http'
          hostNames: [
            '${hostname}.${location}.cloudapp.azure.com'
          ]
          requireServerNameIndication: false
        }
      }
      {
        name: 'HttpsEnterpriseDeploymentListner${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'HttpsEnterpriseDeploymentListner${resourceSuffix}')
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
            '${hostname}.${location}.cloudapp.azure.com'
          ]
          requireServerNameIndication: false
        }
      }
    ]
    listeners: []
    urlPathMaps: [
      {
        name: 'EnterprisePathMap${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/urlPathMaps', applicationGatewayName, 'EnterprisePathMap${resourceSuffix}')
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
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/urlPathMaps/pathRules', applicationGatewayName, 'EnterprisePathMap${resourceSuffix}', 'serverPathRule')
              properties: {
                paths: [
                  '/server/*'
                ]
                backendAddressPool: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ServerBackendPool${resourceSuffix}')
                }
                backendHttpSettings: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'ServerHttpsSetting${resourceSuffix}')
                }
                rewriteRuleSet: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, 'ServerRewriteRuleSet${resourceSuffix}')
                }
              }
            }
            {
              name: 'portalPathRule'
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/urlPathMaps/pathRules', applicationGatewayName, 'EnterprisePathMap${resourceSuffix}', 'portalPathRule')
              properties: {
                paths: [
                  '/portal/*'
                  '/portal'
                ]
                backendAddressPool: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'PortalBackendPool${resourceSuffix}')
                }
                backendHttpSettings: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'PortalHttpsSetting${resourceSuffix}')
                }
                rewriteRuleSet: {
                  id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, 'PortalRewriteRuleSet${resourceSuffix}')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'EnterpriseRequestRoutingRule${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/requestRoutingRules', applicationGatewayName, 'EnterpriseRequestRoutingRule${resourceSuffix}')
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 10
          httpListener: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'HttpsEnterpriseDeploymentListner${resourceSuffix}')
          }
          urlPathMap: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/urlPathMaps', applicationGatewayName, 'EnterprisePathMap${resourceSuffix}')
          }
        }
      }
      {
        name: 'HttpToHttpsEnterpriseRequestRoutingRule${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/requestRoutingRules', applicationGatewayName, 'HttpToHttpsEnterpriseRequestRoutingRule${resourceSuffix}')
        properties: {
          ruleType: 'Basic'
          priority: 20
          httpListener: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'HttpEnterpriseDeploymentListner${resourceSuffix}')
          }
          redirectConfiguration: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'EnterpriseHttpToHttps${resourceSuffix}')
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: 'ServerProbeName${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'ServerProbeName${resourceSuffix}')
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
        name: 'PortalProbeName${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'PortalProbeName${resourceSuffix}')
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
        name: 'PortalRewriteRuleSet${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, 'PortalRewriteRuleSet${resourceSuffix}')
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
        name: 'ServerRewriteRuleSet${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, 'ServerRewriteRuleSet${resourceSuffix}')
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
        name: 'EnterpriseHttpToHttps${resourceSuffix}'
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'EnterpriseHttpToHttps${resourceSuffix}')
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'HttpsEnterpriseDeploymentListner${resourceSuffix}')
          }
          includePath: true
          includeQueryString: true
          requestRoutingRules: [
            {
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/requestRoutingRules', applicationGatewayName, 'HttpToHttpsEnterpriseRequestRoutingRule${resourceSuffix}')
            }
          ]
        }
      }
    ]
    privateLinkConfigurations: []
  }
}

output appGwid string = applicationGateway.id
