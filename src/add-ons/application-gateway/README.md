 # Application Gateway Add-On (MLZ Hub)

## Overview
Deploys an Azure Application Gateway (WAF_v2) in the MLZ hub for: HTTPS termination, Web Application Firewall enforcement, and selective forced routing of ONLY declared backend CIDRs through Azure Firewall. This document intentionally focuses on the infrastructure contract (parameters, listener schema, routing model, WAF policy resolution, certificates, and outputs). It is NOT an operational runbook: performance tuning, false‑positive triage, probe debugging, and broader Application Gateway operations are out of scope—see `ADVANCED.md` for deep WAF tuning, exclusions, certificate rotation, orphan policy cleanup, and advanced troubleshooting.

## Features
* Locked-down dedicated subnet + enforced NSG (inbound 443 + platform requirements only).
* Selective UDR: one route per backend CIDR you declare; never inserts 0.0.0.0/0.
* Least‑privilege egress firewall rules derived from per-app `addressPrefixes` + port maps.
* Global WAF policy auto-created unless you adopt an existing one; per-listener policies only when overrides/exclusions supplied.
* Explicit `wafPolicyId` on an app always wins (overrides/exclusions ignored for that app).
* Deterministic certificate retrieval via versioned Key Vault secret URIs; automatic Key Vault Secrets User RBAC assignment for the inferred hub vault.
* Idempotent re-deploy (unchanged parameters = no drift).
* Diagnostics automatically provisioned when a Log Analytics workspace resource ID is provided.

## Architecture Flow
Client → Application Gateway (public IP) → WAF (global or per‑listener) → Forced route (backend CIDR) → Azure Firewall → Backend service.

## WAF Policy Resolution
| Condition | Result |
|-----------|--------|
| `wafPolicyId` set on app | Listener uses that explicit policy (ignores overrides/exclusions). |
| `wafOverrides` / `wafExclusions` present (no explicit ID) | Synthesizes a per-listener WAF policy. |
| Neither present | Listener inherits global policy (created or adopted). |
| `existingWafPolicyId` set globally | Use it; still may synthesize per-listener ones where inline fields exist. |

`perListenerWafPolicyIds` output is blank where inheritance occurs.

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
| Add diagnostics | Provide `operationsLogAnalyticsWorkspaceResourceId` (existing setting persists if you later clear it; manual delete required). |

NOTE: If a removed app previously had a generated per-listener WAF policy (due to overrides/exclusions), that standalone WAF policy resource is not auto-deleted in incremental mode and becomes an orphan. Delete manually if no longer needed.

<!-- Non-Goals section merged into Overview to reduce section noise. -->

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
| Add diagnostics | Provide `operationsLogAnalyticsWorkspaceResourceId` (existing setting persists if you later clear it; manual delete required). |

NOTE: If a removed app previously had a generated per-listener WAF policy (due to overrides/exclusions), that standalone WAF policy resource is not auto-deleted in incremental mode and becomes an orphan. Delete manually if no longer needed.

## Non-Goals
Operational runbooks, performance tuning strategies, false positive triage, health probe debugging, and general Azure Application Gateway operational guidance are intentionally excluded. For those advanced topics (WAF tuning, exclusions, certificate rotation, orphan policy cleanup, deep troubleshooting) see [ADVANCED.md](./ADVANCED.md).

<!-- Removed duplicate reminder about addressPrefixes (covered in Routing & Firewall). -->


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

## Parameter Reference (Canonical)

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
| `operationsLogAnalyticsWorkspaceResourceId` | Diagnostics emitted when provided; leave empty to omit (no separate enable flag). |
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

## Troubleshooting

| Symptom | Probable Cause | Recommended Action |
|---------|---------------|--------------------|
| Policy creation failure (listener) | Unsupported exclusion enum (Gov latency) | Probe with standalone test policy CLI call; adjust variable. |
| 502 or unhealthy probe | Host header or path mismatch | Set `backendHostHeader` or correct `healthProbePath`. |
| Unexpected egress to broad networks | Overly broad CIDR in `addressPrefixes` | Narrow to specific subnet ranges. |
| Overrides not applied | `wafPolicyId` simultaneously specified | Remove explicit ID to allow generation. |
| No diagnostics output | Workspace ID omitted | Provide `operationsLogAnalyticsWorkspaceResourceId`. |

<!-- Output Details section removed; consolidated into single Outputs table above -->

<!-- Removed File Map and Modules sections as redundant with earlier explanations. Key guidance about specifying only needed CIDRs is already covered in Routing & Firewall. -->

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

Supply `wafOverrides` and/or `wafExclusions` (without an explicit `wafPolicyId`) to generate a per‑listener WAF policy; otherwise listeners inherit the global policy described earlier. If you set `wafPolicyId`, any inline overrides/exclusions are ignored.

> NOTE: Azure Government WAF_v2 (current platform state) supports a single IPv4 public frontend; multi‑public‑IP mode removed. Use host‑based (multi‑site) listeners for segmentation.

## Subnet Private Endpoint Policy Toggle

Parameter: `disablePrivateEndpointNetworkPolicies` (default `true`). When true, Private Endpoint network policies are disabled (safe default preventing accidental PE placement).

<!-- Removed redundant Listener Configuration Surface section (information already present in Parameter Reference and Detailed Listener Definition Reference). -->

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


