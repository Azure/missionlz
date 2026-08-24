# Bicep Patterns & Conventions

Standard patterns for Bicep files in projects using this skill.

## File Naming

```text
main.bicep              — Orchestrator (entry point)
main.bicepparam         — Default parameter values
modules/               — Custom modules (only when AVM insufficient)
tests/                 — Deployment validation tests
environments/          — Per-environment parameter overrides
```

## Orchestrator Pattern (main.bicep)

```bicep
// main.bicep — Orchestrator pattern
// Composes AVM modules; contains no inline resource definitions

targetScope = 'subscription'

@description('Environment identifier')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources')
param location string = 'canadacentral'

@description('Project name used in resource naming')
param projectName string

@description('Tags applied to all resources')
param tags object = {
  environment: environment
  project: projectName
  'managed-by': 'bicep'
}

// --- Resource Group ---
module rg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'rg-${projectName}-${environment}'
  params: {
    name: 'rg-${projectName}-${environment}'
    location: location
    tags: tags
  }
}

// --- Subsequent modules deploy into the resource group ---
module kv 'br/public:avm/res/key-vault/vault:0.9.0' = {
  name: 'kv-${projectName}-${environment}'
  scope: resourceGroup(rg.outputs.name)
  params: {
    name: 'kv-${projectName}-${environment}'
    location: location
    tags: tags
  }
}
```

## Parameter File Pattern

```bicep
// environments/dev.bicepparam
using '../main.bicep'

param environment = 'dev'
param location = 'canadacentral'
param projectName = 'myapp'
```

## Naming Convention Helper

Follow CAF abbreviations consistently:

```bicep
// Use a naming module or inline variables
var prefix = '${projectName}-${environment}'

var names = {
  resourceGroup: 'rg-${prefix}'
  storageAccount: 'st${replace(prefix, '-', '')}' // no hyphens in storage
  keyVault: 'kv-${prefix}'
  appServicePlan: 'asp-${prefix}'
  appService: 'app-${prefix}'
  sqlServer: 'sql-${prefix}'
  vnet: 'vnet-${prefix}'
  subnet: 'snet-${prefix}'
  nsg: 'nsg-${prefix}'
  managedIdentity: 'id-${prefix}'
  logAnalytics: 'log-${prefix}'
  appInsights: 'appi-${prefix}'
  containerRegistry: 'cr${replace(prefix, '-', '')}'
  aksCluster: 'aks-${prefix}'
}
```

## Tagging Pattern

```bicep
@description('Required tags for all resources')
param tags object = {
  environment: environment
  project: projectName
  owner: 'team-name'
  'cost-center': 'CC-1234'
  'managed-by': 'bicep'
}
```

## Private Endpoint Pattern

```bicep
// All PaaS resources should use private endpoints in production
module storage 'br/public:avm/res/storage/storage-account:0.14.0' = {
  name: 'storage'
  scope: resourceGroup(rg.outputs.name)
  params: {
    name: names.storageAccount
    location: location
    tags: tags
    networkAcls: {
      defaultAction: 'Deny'
    }
    privateEndpoints: [
      {
        subnetResourceId: subnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: blobDnsZoneId
            }
          ]
        }
      }
    ]
  }
}
```

## Managed Identity Pattern

```bicep
// Prefer managed identity over keys/connection strings
module identity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'identity'
  scope: resourceGroup(rg.outputs.name)
  params: {
    name: names.managedIdentity
    location: location
    tags: tags
  }
}

// Assign roles via AVM module's roleAssignments parameter
module kv 'br/public:avm/res/key-vault/vault:0.9.0' = {
  name: 'keyvault'
  scope: resourceGroup(rg.outputs.name)
  params: {
    name: names.keyVault
    location: location
    tags: tags
    roleAssignments: [
      {
        principalId: identity.outputs.principalId
        roleDefinitionIdOrName: 'Key Vault Secrets User'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}
```

## Diagnostic Settings Pattern

```bicep
// Enable diagnostics on all resources via AVM's built-in parameter
module appService 'br/public:avm/res/web/site:0.11.0' = {
  name: 'app'
  scope: resourceGroup(rg.outputs.name)
  params: {
    name: names.appService
    location: location
    tags: tags
    kind: 'app,linux'
    serverFarmResourceId: asp.outputs.resourceId
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
        logCategoriesAndGroups: [
          { categoryGroup: 'allLogs' }
        ]
        metricCategories: [
          { category: 'AllMetrics' }
        ]
      }
    ]
  }
}
```

## Test Pattern

```bicep
// tests/main.test.bicep — Validates deployment without side effects
targetScope = 'subscription'

param location string = 'canadacentral'

module testDeployment '../main.bicep' = {
  name: 'test-${uniqueString(deployment().name)}'
  params: {
    environment: 'dev'
    location: location
    projectName: 'test'
  }
}
```

## Anti-Patterns (DO NOT)

| Anti-Pattern | Correct Approach |
|-------------|-----------------|
| Inline `resource` for standard Azure services | Use AVM module |
| Hardcoded secrets in parameters | Key Vault reference |
| `*` in NSG rules | Explicit port ranges |
| Public endpoints in production | Private endpoints + NSG |
| Shared access keys for auth | Managed Identity + RBAC |
| No version pin on module references | Always pin: `module:0.14.0` |
| Manual deployments | CI/CD pipeline |
| Single parameter file for all environments | Per-environment `.bicepparam` |
| `dependsOn` for implicit dependencies | Use module output references |
| Inline role assignments | AVM `roleAssignments` parameter |
