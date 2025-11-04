
# Application Gateway Add-On (MLZ Hub)

## Overview
Deploys an Azure Application Gateway (WAF_v2) in the Mission Landing Zone (MLZ) hub for HTTPS termination, WAF enforcement, and selective, least‑privilege routing of backend traffic through Azure Firewall. This document covers the IaC contract: parameters, listener model, routing, and outputs. Operational tuning and advanced WAF topics are in [ADVANCED.md](./ADVANCED.md).

## Features
* A dedicated subnet for the gateway with a locked-down NSG (you don't pick rules; it's enforced).
* Only the backend networks you list get user-defined routes to the Firewall (no surprise 0.0.0.0/0 route).
* Backend CIDRs you list drive route and firewall rule creation (no implicit broad routes).
* One global WAF policy is created unless you point to an existing one; a listener gets its own policy only if you add `wafOverrides` or `wafExclusions`.
* If you set `wafPolicyId` on an app that exact policy is used and any overrides/exclusions for that app are ignored.
* The gateway's managed identity automatically gets Key Vault Secrets read access (when the certificate secret's vault can be inferred).
* Safe re-run: deploying again with the same parameters doesn't change anything.
* Diagnostics enabled automatically when you supply a Log Analytics workspace resource ID (omit to skip).

## Architecture Flow
Client → AppGW Public IP → WAF (global or per‑listener) → Forced route (declared backend CIDR) → Azure Firewall → Backend.

## Module Map
| Module | Purpose |
|--------|---------|
| `solution.bicep` | Orchestrates sub‑resources, identity, routing, NSG, WAF resolution, diagnostics. |
| `modules/appgateway-core.bicep` | Gateway + listeners + probes + per‑listener policy generation. |
| `modules/wafpolicy-resolver.bicep` | Global WAF policy create/adopt. |
| `modules/appgateway-route-table.bicep` | UDR with selective routes only. |
| `modules/appgateway-nsg.bicep` | Hardened inbound/outbound rules. |
| `modules/appgateway-firewall-rules.bicep` | Firewall policy rule collections (baseline + custom). |
| `modules/appgateway-diagnostics.bicep` | Conditional diagnostic setting. |
| `modules/resolve-firewall-ip.bicep` | Looks up firewall private IP. |
| `modules/kv-role-assignment.bicep` | Optional Key Vault Secrets User RBAC. |

## WAF Policy Resolution
| Condition | Result |
|-----------|--------|
| `wafPolicyId` set on app | That listener uses the explicit policy (ignore overrides/exclusions). |
| Inline `wafOverrides` or `wafExclusions` (no explicit ID) | Synthesized per-listener policy. |
| Neither present | Listener inherits global policy (created or adopted). |
| `existingWafPolicyId` set | Use supplied global policy; still may synthesize per-listener ones if inline fields exist. |

`perListenerWafPolicyIds` output: blank where inheritance occurs.

## Listener Definition (`apps` Array Schema)
| Property | Req | Notes |
|----------|-----|-------|
| `name` | yes | Seeds listener/pool/probe naming. |
| `hostNames` | yes | Multi-site host headers (SNI). |
| `backendAddresses` | yes | Array of `{ fqdn }` or `{ ipAddress }`. |
| `certificateSecretId` | yes | Versioned Key Vault secret URI (TLS). |
| `addressPrefixes` | yes | Backend CIDRs for forced routes + firewall rules (REQUIRED; at least one CIDR per app). |
| `backendPort` / `backendProtocol` | no | Overrides defaults (usually 443/Https). |
| `healthProbePath` (+ probe settings) | no | Optional overrides. |
| `backendHostHeader` | no | Override Host header for backend. |
| `wafPolicyId` | no | Advanced explicit listener policy. |
| `wafOverrides` | no | Triggers synthesized listener policy (if no explicit ID). |
| `wafExclusions` | no | Triggers synthesized listener policy (if no explicit ID). |

## Key Parameters
| Name | Summary |
|------|---------|
| `location` | Region. |
| `hubVnetResourceId` | Existing hub VNet ID. |
| `appGatewaySubnetAddressPrefix` | Subnet CIDR (default /26). |
| `apps` / `commonDefaults` | Listener definitions + shared defaults. |
| `existingWafPolicyId` | Advanced: adopt external global policy. |
| `backendPrefixPortMaps` / `backendAppPortMaps` | Granular firewall shaping precedence. |
| `backendAllowPorts` | Fallback ports when maps absent. |
| `customAppGatewayFirewallRuleCollectionGroups` | Extra firewall allow groups. |
| `operationsLogAnalyticsWorkspaceResourceId` | Log Analytics workspace ID (diagnostics enabled automatically when set). |
| WAF tuning params (global) | Applied only when creating new global policy. |

## Outputs
| Output | Meaning |
|--------|---------|
| `appGatewayPublicIp` | Static IPv4. |
| `wafPolicyResourceId` | Global policy ID. |
| `perListenerWafPolicyIds` | Listener→policy mapping (blank = inherit). |
| `forcedRouteEntries` | Objects for each unique backend CIDR. |
| `listenerNames` | Listener resource names. |
| `backendPoolNames` | Backend pool names. |
| `userAssignedIdentityResourceIdOut` | Identity resource ID. |
| `userAssignedIdentityPrincipalId` | Identity principal ID. |
| `diagnosticsSettingId` | Diagnostic setting ID (blank when workspace ID omitted). |

## Routing & Firewall
Workflow:
1. Collect all `addressPrefixes` across apps (each app must supply at least one backend CIDR that actually needs egress via the Firewall—don't include superfluous ranges).
2. Generate one UDR route per unique CIDR (`forcedRouteEntries`; next hop = Firewall private IP). No 0.0.0.0/0 default route is inserted.
3. Associate the route table + enforced NSG with the Application Gateway subnet (NSG creation is mandatory).
4. Build firewall allow rules in strict precedence order:
  * `backendAppPortMaps` (per app + per port specificity; highest)
  * `backendPrefixPortMaps` (CIDR → port list)
  * Broad fallback rule: all collected CIDRs + `backendAllowPorts` (only if needed)
5. Anything not explicitly allowed is denied by the Firewall's default deny.

Result: Minimal egress surface—fine‑grained maps first, broad fallback last.

## Minimal Parameter File Example
```bicep-params
using './solution.bicep'
param location = 'usgovvirginia'
param hubVnetResourceId = '/subscriptions/<subId>/resourceGroups/<hubRg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>'
param commonDefaults = {
  backendPort: 443
  backendProtocol: 'Https'
  healthProbePath: '/'
  autoscaleMinCapacity: 1
  autoscaleMaxCapacity: 2
  generatedPolicyMode: 'Prevention'
  generatedPolicyManagedRuleSetVersion: '3.2'
}
param apps = [
  {
    name: 'web1'
    hostNames: [ 'web1.example.gov' ]
    certificateSecretId: 'https://kv-example.vault.usgovcloudapi.net/secrets/web1cert/<version>'
    backendAddresses: [ { fqdn: 'web1-pe.azurewebsites.us' } ]
    addressPrefixes: [ '10.60.10.0/24' ]
  }
]
```

## Routine Operations (Idempotent)
| Action | Required Input Change |
|--------|-----------------------|
| Add listener/app | Append new object to `apps`. |
| Remove listener/app | Delete object from `apps` (removes listener + pool + probe + routing rule + certificate reference). |
| Introduce inline WAF tuning | Add `wafOverrides` or `wafExclusions` (creates policy). |
| Adopt external listener policy | Set `wafPolicyId`; remove overrides/exclusions. |
| Switch global to external | Set `existingWafPolicyId`. |
| Expand allowed egress ports | Update maps or `backendAllowPorts`. |
| Add diagnostics | Provide `operationsLogAnalyticsWorkspaceResourceId`. |
| Remove diagnostics | Clear `operationsLogAnalyticsWorkspaceResourceId`. |

NOTE: If a removed app previously had a generated per-listener WAF policy (due to overrides/exclusions), that standalone WAF policy resource is not auto-deleted in incremental mode and becomes an orphan. Delete manually if no longer needed.

## Non-Goals
Operational runbooks, performance tuning strategies, false positive triage, health probe debugging, and general Azure Application Gateway operational guidance are intentionally excluded. For those advanced topics (WAF tuning, exclusions, certificate rotation, orphan policy cleanup, deep troubleshooting) see [ADVANCED.md](./ADVANCED.md).

Provide only CIDRs requiring firewall egress in `addressPrefixes`.


## Detailed Listener Definition Reference

Each element maps to one HTTPS listener (multi‑site host names) plus a backend pool and optional dedicated WAF policy.

| Property | Required | Description |
|----------|----------|-------------|
| `name` | yes | Short identifier used to derive resource child names. |
| `hostNames` | yes | Host headers for SNI & routing. |
| `backendAddresses` | yes | Array of `{ fqdn }` or `{ ipAddress }` entries. |
| `certificateSecretId` | yes | Versioned Key Vault secret URI for TLS cert. |
| `addressPrefixes` | yes | Backend CIDRs requiring forced routing & firewall allow (must not be empty; each app needs at least one CIDR). |
| `backendPort` / `backendProtocol` | no | Override defaults (defaults 443 / Https). |
| `healthProbePath`, `probeInterval`, `probeTimeout`, `unhealthyThreshold`, `probeMatchStatusCodes` | no | Per listener probe tuning. |
| `backendHostHeader` | no | Override host header for backend/SNI preservation. |
| `wafPolicyId` | no | Advanced: attach existing externally managed policy (overrides/ exclusions ignored if both supplied). |
| `wafExclusions` | no | Exclusions list; triggers synthesized per-listener policy (when no `wafPolicyId`). |
| `wafOverrides` | no | Inline WAF tuning; triggers synthesized per-listener policy (when no `wafPolicyId`). |

### Example: Minimal App

```jsonc
{
  "name": "web1",
  "hostNames": [ "web1.internal.example.gov" ],
  "backendAddresses": [ { "fqdn": "web1-pe.azurewebsites.us" } ],
  "certificateSecretId": "https://kv-example.vault.usgovcloudapi.net/secrets/web1cert/<version>",
  "addressPrefixes": [ "10.60.10.0/24" ]
}
```

### Example: Per‑Listener WAF Overrides

```jsonc
{
  "name": "api",
  "hostNames": [ "api.example.gov" ],
  "backendAddresses": [ { "ipAddress": "10.70.5.10" } ],
  "certificateSecretId": "https://kv-example.vault.usgovcloudapi.net/secrets/api-cert/<version>",
  "addressPrefixes": [ "10.70.5.0/24" ],
  "wafOverrides": {
    "mode": "Detection",
    "maxRequestBodySizeInKb": 256,
    "ruleGroupOverrides": [ { "ruleGroupName": "REQUEST-930-APPLICATION-ATTACK-LFI", "rules": [ { "ruleId": "930100", "state": "Disabled" } ] } ]
  }
}
```

## Expanded Parameter Reference

| Name | Summary |
|------|---------|
| `location` | Azure region for resources. |
| `hubVnetResourceId` | Existing hub virtual network resource ID. |
| `appGatewaySubnetAddressPrefix` | CIDR for the gateway subnet (default /26). |
| `apps` / `commonDefaults` | Application listener definitions & shared defaults. |
| `existingWafPolicyId` | Advanced: adopt external global WAF policy (typical deployments leave unset). |
| `backendAllowPorts` | Port list used when no detailed maps provided. |
| `backendPrefixPortMaps` / `backendAppPortMaps` | Fine‑grained firewall rule shaping. |
| `customAppGatewayFirewallRuleCollectionGroups` | Additional firewall policy rule groups. |
| (NSG always enforced) | Not applicable—cannot disable via parameter. |
| `operationsLogAnalyticsWorkspaceResourceId` | Diagnostics emitted when provided; leave empty to omit. |
| Add diagnostics | Provide `operationsLogAnalyticsWorkspaceResourceId`. |
| Remove diagnostics | Clear `operationsLogAnalyticsWorkspaceResourceId`. |
| WAF tuning params (`wafPolicyMode`, `wafManagedRuleSetVersion`, etc.) | Influence new global policy creation. |

<!-- (Merged former 'Routing & Firewall Rule Precedence' and 'Routing & Firewall Integration' sections to remove redundancy.) -->

## Certificates & Key Vault

Assumption: All TLS certificates used by the Application Gateway listeners are stored in the hub Key Vault (the vault inferred from `commonDefaults.defaultCertificateSecretId` or, if absent, the first app's `certificateSecretId`). The module only performs automatic RBAC (Key Vault Secrets User) assignment for that single inferred vault. If you intentionally distribute certificates across multiple vaults, you must manually grant the gateway's user‑assigned identity access to each additional vault.

How the template discovers the Key Vault:

1. It looks for `commonDefaults.defaultCertificateSecretId` first. If set, that value wins.
2. If not set, it takes the `certificateSecretId` from the first element in `apps`.
3. From that secret URI it extracts the vault name (the part before `.vault.`).
4. If it can extract a vault name, it automatically assigns the **Key Vault Secrets User** RBAC role to the gateway's user‑assigned identity (in the hub resource group by default, or the group you specify with `keyVaultResourceGroupName`).

Secret URI format (versioned):

```
https://<vaultName>.vault.azure.net/secrets/<secretName>/<secretVersionGuid>
```

Why the version matters:

* Using a versioned URI (includes the final GUID segment) makes redeploys deterministic; Azure never silently shifts to a newer cert.
* Rotation workflow: add a new secret version, validate it, then update the parameter file to reference the new version GUID and redeploy.
* If you omit the version (ending at `/secrets/<secretName>`), the latest version can change underneath you—breaking idempotence and making rollback harder.

Edge cases:

* If there are no apps yet and no `commonDefaults.defaultCertificateSecretId`, the vault name cannot be inferred—role assignment is skipped. Add at least one app with a valid versioned secret before relying on Key Vault RBAC.
* If the Key Vault lives in a different resource group, set `keyVaultResourceGroupName` so the role assignment targets the right scope.
* If you break the single‑hub‑vault assumption and place certificates in multiple vaults, only the first (or the default) vault receives automatic RBAC. Manually assign **Key Vault Secrets User** (or equivalent access) for the gateway identity on every other vault you reference.

Quick example:

```
certificateSecretId: "https://mlz-hub-kv.vault.usgovcloudapi.net/secrets/web1cert/0d9c2d4e3a2f4d8e8bb1f6c9d5a1b234"
```

This results in a role assignment granting the gateway identity read access to `mlz-hub-kv` secrets so it can fetch the certificate during deployment/run.

Always use **versioned** URIs and plan rotations by creating the new version first, then updating your parameter file.

## Diagnostics

Diagnostics are created automatically when you provide a valid Log Analytics workspace resource ID via `operationsLogAnalyticsWorkspaceResourceId`. Leave it empty to skip deployment of the diagnostic setting (output blank). There is no separate enable flag.

## Deployment Examples

### Minimal Parameter File

```bicep-params
using './solution.bicep'

param location = 'usgovvirginia'
param hubVnetResourceId = '/subscriptions/<subId>/resourceGroups/<hubRg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>'
param commonDefaults = {
  backendPort: 443
  backendProtocol: 'Https'
  healthProbePath: '/'
  autoscaleMinCapacity: 1
  autoscaleMaxCapacity: 2
  generatedPolicyMode: 'Prevention'
  generatedPolicyManagedRuleSetVersion: '3.2'
}
param apps = [
  {
    name: 'web1'
    hostNames: [ 'web1.example.gov' ]
    certificateSecretId: 'https://kv-example.vault.usgovcloudapi.net/secrets/web1cert/<version>'
    backendAddresses: [ { fqdn: 'web1-pe.azurewebsites.us' } ]
    addressPrefixes: [ '10.60.10.0/24' ]
  }
]
```

### Mixed Strategies (inherit + generated + explicit)

```bicep-params
param apps = [
  { name: 'portal'; hostNames: ['portal.example.gov']; certificateSecretId: 'https://kv/.../portal/<ver>'; backendAddresses: [{ fqdn: 'portal-pe.azurewebsites.us' }]; addressPrefixes: ['10.10.10.0/24'] }
  { name: 'api'; hostNames: ['api.example.gov']; certificateSecretId: 'https://kv/.../api/<ver>'; backendAddresses: [{ ipAddress: '10.20.5.10' }]; addressPrefixes: ['10.20.5.0/24']; wafOverrides: { mode: 'Detection' } }
  { name: 'legacy'; hostNames: ['legacy.example.gov']; certificateSecretId: 'https://kv/.../legacy/<ver>'; backendAddresses: [{ fqdn: 'legacy-pe.azurewebsites.us' }]; addressPrefixes: ['10.30.0.0/24']; wafPolicyId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/legacy-custom' }
]
```

### CLI Deployment (Subscription Scope)

```powershell
az deployment sub create `
  --name appgw-mlz `
  --location usgovvirginia `
  --template-file src/add-ons/application-gateway/solution.bicep `
  --parameters @path\to\params.bicepparam
```

Portal deployment is also supported via `solution.json` + `uiDefinition.json` artifacts (commercial & government clouds).

## Post-Deployment Verification

| Check | Expectation |
|-------|-------------|
| Public IP | Static address present & reachable (optional DNS mapped). |
| `listenerNames` | Contains an entry for each app. |
| `perListenerWafPolicyIds` | Blank entries only where no overrides/exclusions/explicit id were provided. |
| `forcedRouteEntries` | Only declared backend CIDRs; no 0.0.0.0/0. |
| Subnet | NSG & route table associated; outbound access disabled flag set. |
| Health probes | All listeners show healthy backends after certificate & host header alignment. |
| Firewall policy | Baseline + (optional) custom rule collections present. |

## Routine Change Quick Reference

| Action | Steps |
|--------|-------|
| Add application | Append new element to `apps`, redeploy (idempotent). |
| Temporarily relax WAF | Add `wafOverrides.mode = 'Detection'`, redeploy, later remove. |
| Switch to explicit policy | Set `wafPolicyId`, remove overrides & exclusions. |
| Increase autoscale ceiling | Update `commonDefaults.autoscaleMaxCapacity`. |
| Expand backend ports | Add to `backendPrefixPortMaps` or `backendAppPortMaps`. |
| Remove diagnostics | Clear `operationsLogAnalyticsWorkspaceResourceId`. |
| Mandatory NSG enforcement | Removed prior optional toggle; hardens baseline by default. |

## Troubleshooting

| Symptom | Probable Cause | Recommended Action |
|---------|---------------|--------------------|
| Policy creation failure (listener) | Unsupported exclusion enum (Gov latency) | Probe with standalone test policy CLI call; adjust variable. |
| 502 or unhealthy probe | Host header or path mismatch | Set `backendHostHeader` or correct `healthProbePath`. |
| Unexpected egress to broad networks | Overly broad CIDR in `addressPrefixes` | Narrow to specific subnet ranges. |
| Overrides not applied | `wafPolicyId` simultaneously specified | Remove explicit ID to allow generation. |
| No diagnostics output | Workspace ID omitted | Provide `operationsLogAnalyticsWorkspaceResourceId`. |

<!-- Output Details section removed; consolidated into single Outputs table above -->

## File Map

| File | Description |
|------|-------------|
| `solution.bicep` | Subscription‑scope orchestrator. |
| `solution.json` / `uiDefinition.json` | Portal deployment assets. |
| `modules/appgateway-core.bicep` | Gateway definition & listener logic. |
| `modules/wafpolicy-resolver.bicep` | Global WAF policy creation / reuse. |
| `modules/appgateway-subnet.bicep` | Subnet + delegation + enforced NSG association. |
| `modules/appgateway-route-table.bicep` | Route table & targeted routes. |
| `modules/appgateway-nsg.bicep` | Network security group. |
| `modules/appgateway-firewall-rules.bicep` | Firewall policy rule groups. |
| `modules/appgateway-diagnostics.bicep` | Diagnostic settings. |
| `modules/resolve-firewall-ip.bicep` | Firewall IP resolution. |
| `modules/kv-role-assignment.bicep` | Optional Key Vault RBAC assignment. |



> Provide **only** the CIDRs requiring egress via Firewall in `addressPrefixes`; the template emits one `forcedRouteEntries` item per CIDR you specify.

## Modules

* `solution.bicep` – orchestration (naming inference, subnet creation, NSG/route table, WAF policy resolution, diagnostics, firewall rules, per‑listener object shaping, identity RBAC to Key Vault).
* `modules/appgateway-core.bicep` – gateway resource, dynamic listeners, pools, probes, autoscale, generated per‑listener WAF policies.
* `modules/appgateway-subnet.bicep` – authoritative subnet definition with enforced NSG & route table association.
* `modules/appgateway-route-table.bicep` – constructs forced routes referencing only declared backend CIDRs (no 0.0.0.0/0).
* `modules/appgateway-diagnostics.bicep` – diagnostic settings binding to LA workspace.
* `modules/appgateway-firewall-rules.bicep` – firewall policy rule collection groups (baseline + custom additions).
* `modules/wafpolicy-resolver.bicep` – resolves existing or creates baseline WAF policy.
* `modules/kv-role-assignment.bicep` – optional Key Vault secrets RBAC assignment for user‑assigned identity.
* `modules/resolve-firewall-ip.bicep` – resolves Firewall private IP used in routes & firewall rule logic.

## Scaling

Add or update apps by editing the `apps` array in a parameter file, then redeploy. Removal is destructive (listener/pool/probe + generated per‑listener WAF policy deleted).

## Security

* TLS 1.2+ enforced; HTTPS‑only listeners.
* WAF baseline in Prevention (override globally or per listener).
* Certificates pulled from Key Vault via user‑assigned identity (RBAC role optional toggle).
* NSG inbound restricted to 443 + AzureLoadBalancer + ephemeral probe ports; all other inbound denied.
* **No** default 0.0.0.0/0 forced route—only declared backend prefixes are routed via Firewall (prevents asymmetric probing failures).
* Host header override allows internal private resolution while preserving public FQDN SNI for backend cert validation.
* Outbound default Internet access disabled on subnet (controlled egress via Firewall). No implicit 0.0.0.0/0 UDR is created to avoid asymmetric probe paths.

## Hub-Spoke Integration & Routing

* Deployed into the MLZ hub VNet in a dedicated subnet (`AppGateway` by default) sized per autoscale recommendation (/26 default here).
* Backends reside in spoke VNets or private endpoints; only declared backend CIDR prefixes (via each app's `addressPrefixes`) are forced through the hub Firewall using UDR entries created by the add-on.
* No default 0.0.0.0/0 route: prevents asymmetric paths for health probes and ensures only intentional egress inspection.
* Firewall rule module receives the backend CIDRs plus allowed ports to construct least‑privilege egress.
* NSG enforced on gateway subnet for inbound restriction (443 + platform requirements); outbound Internet access disabled at subnet level to align with centralized egress model.

## WAF Overrides Per Listener

Each app/listener may supply a `wafOverrides` object (and/or `wafExclusions`) to selectively diverge from the **generated baseline**. Missing keys inherit generated defaults. Presence of `wafOverrides` or `wafExclusions` (and absence of explicit `wafPolicyId`) triggers creation of a per‑listener WAF policy.

Advanced: If you already have an externally managed WAF policy for a listener, set `wafPolicyId` and omit overrides / exclusions (no per‑listener policy generated); inline settings are ignored when an explicit ID is present.

> NOTE: Azure Government WAF_v2 (current platform state) supports a single IPv4 public frontend; multi‑public‑IP mode removed. Use host‑based (multi‑site) listeners for segmentation.

## Forced Route Entries Output

`forcedRouteEntries` output lists each backend CIDR prefix generating a route table entry (next hop = Firewall private IP).

## Subnet Private Endpoint Policy Toggle

Parameter: `disablePrivateEndpointNetworkPolicies` (default `true`). When true, Private Endpoint network policies are disabled (safe default preventing accidental PE placement).

## Listener Configuration Surface

Each element in `apps` drives one or more multi-site HTTPS listeners and its backend pool. Granular overrides allow per-listener WAF tuning and probe adjustments without changing the core module.

Key per-app options:

* `hostNames`: Array of FQDNs mapped to a single listener (multi-site SNI based).
* `backendAddresses`: Array of objects (either `{ "fqdn": "..." }` or `{ "ipAddress": "..." }`).
* `backendHostHeader`: Override Host header sent to backend (useful when private endpoint resolves internal FQDN different from public host).
* `backendPort` / `backendProtocol`: Defaults inherited from `commonDefaults` (TLS inspection requires `Https`).
* `certificateSecretId`: Key Vault secret reference for listener TLS certificate.
* `healthProbePath`, `probeInterval`, `probeTimeout`, `unhealthyThreshold`, `probeMatchStatusCodes`: Optional fine-grained probe tuning.
* `wafOverrides` / `wafExclusions`: Trigger per-listener WAF policy generation (if `wafPolicyId` not supplied).
* `wafPolicyId`: Attach an existing Application Gateway WAF policy to just this listener (skip generation).
* `addressPrefixes`: Backend CIDR set used to build selective UDR forced routes and firewall egress rules.

## Out of Scope

* Scenario B (gateway after firewall)
* Azure Front Door integration
* Private‑only frontends (future enhancement under review)

## Constructing a `.bicepparam` File

The `.bicepparam` file supplies required deployment-scope parameters plus structured `commonDefaults` and `apps` arrays. Below is a minimal example emphasizing TLS inspection and selective routing.

```jsonc
using 'solution.bicep'

param location = 'usgovvirginia'
param hubVnetResourceId = '/subscriptions/<subId>/resourceGroups/<hubRg>/providers/Microsoft.Network/virtualNetworks/<hubVnetName>'
// (Identity created automatically; no identity parameters required)
// Optional: override abbreviations only if deviating from repository defaults (loaded internally).
// param resourceAbbreviations = loadJsonContent('../../data/resource-abbreviations.json')
param commonDefaults = {
  backendPort: 443
  backendProtocol: 'Https'
  healthProbePath: '/'
  probeInterval: 30
  probeTimeout: 30
  unhealthyThreshold: 3
  probeMatchStatusCodes: [ '200-399' ]
  autoscaleMinCapacity: 1
  autoscaleMaxCapacity: 2
  generatedPolicyMode: 'Prevention'
  generatedPolicyManagedRuleSetVersion: '3.2'
}
param apps = [
  {
    name: 'app1'
    hostNames: [ 'app1.example.gov' ]
    certificateSecretId: 'https://kv-example.vault.usgovcloudapi.net/secrets/app1cert/<version>'
    backendAddresses: [ { fqdn: 'app1-pe-appservice.azurewebsites.us' } ]
    backendHostHeader: 'app1.example.gov'
    healthProbePath: '/'
    addressPrefixes: [ '10.50.1.0/24' ]
    wafOverrides: {
      mode: 'Prevention'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      managedRuleSetVersion: '3.2'
    }
  }
  {
    name: 'app2'
    hostNames: [ 'app2.example.gov' ]
    certificateSecretId: 'https://kv-example.vault.usgovcloudapi.net/secrets/app2cert/<version>'
    backendAddresses: [ { ipAddress: '10.60.2.10' }, { ipAddress: '10.60.2.11' } ]
    backendPort: 443
    backendProtocol: 'Https'
    healthProbePath: '/'
    addressPrefixes: [ '10.60.2.0/24' ]
    wafPolicyId: '/subscriptions/<subId>/resourceGroups/<hubRg>/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/app2-listener-policy'
  }
]

// Optional diagnostics (add workspace ID to enable)
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/<subId>/resourceGroups/<opsRg>/providers/Microsoft.OperationalInsights/workspaces/<laWorkspace>'
```

Guidance:

* Include only CIDRs in `addressPrefixes` that must traverse Firewall from the gateway.
* Identity is always created (idempotent). No identity parameters required.
* Use `wafOverrides` / `wafExclusions` for inline listener-specific tuning; only use `wafPolicyId` when an external, centrally managed policy already exists (advanced scenario).
* Provide consistent Key Vault secret versioned IDs for certificates; the module derives vault name for optional RBAC assignment.

### Step-by-Step Parameter File Construction

1. Core subscription-scope parameters: define `location`, `hubVnetResourceId`, and (optionally) `resourceAbbreviations` (identity is automatic).
2. Establish `commonDefaults`: decide your baseline backend protocol (`Https` for TLS inspection), port, probe timings, autoscale caps, and (optionally) generated per-listener WAF defaults.
3. Define each app in `apps`: supply a unique `name`, its `hostNames`, certificate secret, and backend addresses. Add only necessary overrides—omit fields to inherit `commonDefaults`.
4. Add `addressPrefixes` per app: include ONLY the CIDRs that represent backend network segments requiring Firewall egress. Avoid overly broad CIDRs.
5. Decide WAF strategy per listener: use `wafOverrides` (inline) OR `wafPolicyId` (external policy). Do not combine.
6. (Optional) Include diagnostics parameters if you need LA workspace integration.

## Advanced Topics
For deep dives (WAF overrides details, backend address design, naming limits, decision matrices, pitfalls, extended examples) see [ADVANCED.md](./ADVANCED.md). README stays focused on core deployment and usage.

<!-- Designing the apps array guidance moved to ADVANCED.md -->

<!-- FQDN vs IP decision matrix moved to ADVANCED.md -->

<!-- Backend definition examples moved to ADVANCED.md -->

<!-- Listener naming guidance moved to ADVANCED.md -->

<!-- WAF override minimal example moved to ADVANCED.md -->

<!-- Common pitfalls moved to ADVANCED.md -->


