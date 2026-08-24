# AVM Module Lookup (Bicep)

Do NOT rely on hardcoded module paths. Always look up modules dynamically.

## How to Find AVM Modules

### 1. Browse the Module Index (authoritative)

```
https://aka.ms/avm/moduleindex
```

This is the official, always-current list of all AVM modules.

### 2. Browse the GitHub source

```
https://github.com/Azure/bicep-registry-modules/tree/main/avm/res
https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn
```

Search by resource type folder name. Each folder has a `README.md` with the
current version and usage examples.

### 3. Check available versions

Navigate to the module folder on GitHub and look at the git tags, or check the
`metadata.json` / `version.json` file in the module folder for the latest
published version.

## Module Naming Convention

AVM modules follow a predictable naming pattern:

```text
br/public:avm/res/{resource-provider}/{resource-type}:{version}
br/public:avm/ptn/{pattern-name}:{version}
br/public:avm/utl/{utility-name}:{version}
```

The `{resource-provider}/{resource-type}` maps to the Azure Resource Manager
provider namespace. Examples:

| Azure Resource | AVM Path Pattern |
|---------------|-----------------|
| Storage Account | `avm/res/storage/storage-account` |
| Virtual Network | `avm/res/network/virtual-network` |
| Key Vault | `avm/res/key-vault/vault` |
| AKS Cluster | `avm/res/container-service/managed-cluster` |

To find any resource: take the ARM resource type (e.g., `Microsoft.Storage/storageAccounts`),
lowercase it, drop `Microsoft.`, replace `/` with `/`, and hyphenate the resource name.

## Version Pinning

Always pin to a specific version. Never use unversioned references.

```bicep
// CORRECT — pinned version
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.0' = {
  name: 'storage'
  params: { ... }
}

// WRONG — no version pin
module storageAccount 'br/public:avm/res/storage/storage-account' = {
  name: 'storage'
  params: { ... }
}
```

## AVM Module Common Interfaces

All AVM resource modules support these standard parameters:

| Parameter | Type | Purpose |
|-----------|------|---------|
| `name` | string | Resource name |
| `location` | string | Azure region |
| `tags` | object | Resource tags |
| `lock` | object | Resource lock configuration |
| `roleAssignments` | array | RBAC role assignments |
| `diagnosticSettings` | array | Diagnostic settings (logs + metrics) |
| `managedIdentities` | object | System/user-assigned identity config |
| `privateEndpoints` | array | Private endpoint connections |

This consistency is a key benefit of AVM — every module follows the same
interface patterns regardless of resource type.

## Module Categories

| Category | Registry Prefix | Purpose |
|----------|----------------|---------|
| Resource modules | `br/public:avm/res/*` | Single Azure resource, full config surface |
| Pattern modules | `br/public:avm/ptn/*` | Multi-resource compositions (e.g., hub-spoke) |
| Utility modules | `br/public:avm/utl/*` | Helpers (shared types, naming) |
