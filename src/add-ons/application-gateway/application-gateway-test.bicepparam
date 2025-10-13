// Parameter file for testing Scenario A Application Gateway add-on
// Replace ALL <PLACEHOLDER_*> values before deploying.

using 'solution.bicep'

param location = '<PLACEHOLDER_LOCATION>'
param deploymentName = 'agwtest'

// Existing hub virtual network resource ID
param hubVnetResourceId = '/subscriptions/<PLACEHOLDER_SUBSCRIPTION_ID>/resourceGroups/<PLACEHOLDER_HUB_RG>/providers/Microsoft.Network/virtualNetworks/<PLACEHOLDER_HUB_VNET_NAME>'

// Leave empty to create a new WAF policy in this deployment; set to an existing policy ID to reuse.
param existingWafPolicyId = ''

// Defaults applied to (current) single app. Adjust as needed.
param commonDefaults = {
  autoscaleMinCapacity: 2
  autoscaleMaxCapacity: 4
  backendPort: 443
  backendProtocol: 'Https'
  healthProbePath: '/health'
  enableHttp2: false
  // listenerFrontendPort: 443 // optional override
}

// Only the first element is used in the current minimal scaffold.
param apps = [
  {
    name: 'app1'
    hostNames: [ 'app1.contoso.test' ] // Replace with your hostnames (optional for basic test)
    backendTargets: [
      { type: 'ip', value: '<PLACEHOLDER_BACKEND_IP>' } // Example: 10.100.20.10 (must be reachable from gateway subnet)
      // { type: 'fqdn', value: 'backend.example.com' }
    ]
    // certificateSecretId: '<OPTIONAL_KEYVAULT_CERT_SECRET_ID>' // Needed if using HTTPS listener with real cert
    // backendPort: 8443 // per-app override example
    // backendProtocol: 'Https'
    // healthProbePath: '/health'
  }
]

param tags = {
  environment: 'dev'
  workload: 'appgw-scenario-a'
}
