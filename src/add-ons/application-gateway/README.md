<!-- README intentionally scoped to IaC contract & invariants. Advanced operational guidance lives in ADVANCED.md. -->

# Application Gateway Add-On (MLZ Hub) – IaC Contract

## 1. Overview
Provisions an Azure Application Gateway (WAF_v2) in the Mission Landing Zone hub. Focus: idempotent deployment of listeners + WAF posture + selective routing + firewall integration. Not an operations or tuning guide.

## 2. Design Invariants
* Always creates a gateway subnet with enforced restrictive NSG (cannot be disabled).
* Never creates a 0.0.0.0/0 UDR; only declared backend CIDRs become forced routes.
* Deduplicates backend CIDRs before generating route entries and firewall allows.
* Per-listener WAF policy only synthesized when `wafOverrides` or `wafExclusions` exist and no explicit `wafPolicyId` is provided.
* Explicit listener `wafPolicyId` supersedes inline overrides/exclusions for that listener.
* Global WAF policy is created unless `existingWafPolicyId` supplied.
* Re-deploy with unchanged parameters → no resource drift.
* Diagnostics only emitted when both `enableDiagnostics` and workspace ID are set.

## 3. Minimal Listener Flow
Client → AppGW public IP → WAF (global or synthesized per-listener) → Forced route (only declared CIDR) → Azure Firewall → Backend.

## 4. Module Map
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

## 5. WAF Policy Resolution (Contract Summary)
| Condition | Result |
|-----------|--------|
| `wafPolicyId` set on app | That listener uses the explicit policy (ignore overrides/exclusions). |
| Inline `wafOverrides` or `wafExclusions` (no explicit ID) | Synthesized per-listener policy. |
| Neither present | Listener inherits global policy (created or adopted). |
| `existingWafPolicyId` set | Use supplied global policy; still may synthesize per-listener ones if inline fields exist. |

`perListenerWafPolicyIds` output: blank where inheritance occurs.

## 6. `apps` Array Schema (Per Listener)
| Property | Req | Notes |
|----------|-----|-------|
| `name` | yes | Seeds listener/pool/probe naming. |
| `hostNames` | yes | Multi-site host headers (SNI). |
| `backendAddresses` | yes | Array of `{ fqdn }` or `{ ipAddress }`. |
| `certificateSecretId` | yes | Versioned Key Vault secret URI (TLS). |
| `addressPrefixes` | recommended | Backend CIDRs for forced routes + firewall rules (deduplicated). |
| `backendPort` / `backendProtocol` | no | Overrides defaults (usually 443/Https). |
| `healthProbePath` (+ probe settings) | no | Optional overrides. |
| `backendHostHeader` | no | Override Host header for backend. |
| `wafPolicyId` | no | Advanced explicit listener policy. |
| `wafOverrides` | no | Triggers synthesized listener policy (if no explicit ID). |
| `wafExclusions` | no | Triggers synthesized listener policy (if no explicit ID). |

## 7. Selected Parameters
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
| `enableDiagnostics` & `operationsLogAnalyticsWorkspaceResourceId` | Both required for diagnostics. |
| `createKeyVaultSecretAccessRole` | Optional Secrets User role assignment. |
| WAF tuning params (global) | Applied only when creating new global policy. |

## 8. Outputs
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
| `diagnosticsSettingId` | Diagnostic setting or blank when disabled. |

## 9. Routing & Firewall Precedence
1. Collect and deduplicate all `addressPrefixes` across apps.
2. Generate one UDR route per CIDR (next hop = Firewall private IP).
3. Firewall rules precedence: `backendAppPortMaps` > `backendPrefixPortMaps` > broad deduplicated CIDRs + `backendAllowPorts` fallback.

## 10. Minimal Parameter Example
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

## 11. Change Operations (Idempotent)
| Action | Required Input Change |
|--------|-----------------------|
| Add listener/app | Append new object to `apps`. |
| Remove listener/app | Delete object from `apps` (removes listener + pool + generated per-listener policy). |
| Introduce inline WAF tuning | Add `wafOverrides` or `wafExclusions` (creates policy). |
| Adopt external listener policy | Set `wafPolicyId`; remove overrides/exclusions. |
| Switch global to external | Set `existingWafPolicyId`. |
| Expand allowed egress ports | Update maps or `backendAllowPorts`. |
| Toggle diagnostics | Set flag + workspace (enable) or clear either (disable). |

## 12. Non-Goals
Operational runbooks, performance tuning strategies, false positive triage, health probe debugging, and general Azure Application Gateway operational guidance are intentionally excluded. See `ADVANCED.md` for extended material.

## 13. Change History (Excerpt)
| Change | Rationale |
|--------|-----------|
| Mandatory NSG enforcement | Ensures consistent hardening; removed legacy toggle. |
| Per-listener on-demand WAF creation | Avoids policy sprawl; only when needed. |
| Documentation split | Keep README contractual; move operations to ADVANCED.md. |
| Simplified WAF docs | Emphasize automatic behavior & precedence. |

## 14. Pointer to Advanced Content
For troubleshooting, detailed WAF exclusion guidance, security rationale, and post-deployment verification steps, consult `ADVANCED.md`.

---
`addressPrefixes` supersedes legacy singular `addressPrefix` (still accepted). Provide only CIDRs requiring firewall egress. Deduplication occurs automatically.

---
Active implementation; please raise issues referencing commit hash.

## 7. Application Definition (`apps` Array)

Each element maps to one HTTPS listener (multi‑site host names) plus a backend pool and optional dedicated WAF policy.

| Property | Required | Description |
|----------|----------|-------------|
| `name` | yes | Short identifier used to derive resource child names. |
| `hostNames` | yes | Host headers for SNI & routing. |
| `backendAddresses` | yes | Array of `{ fqdn }` or `{ ipAddress }` entries. |
| `certificateSecretId` | yes | Versioned Key Vault secret URI for TLS cert. |
| `addressPrefixes` | recommended | Backend CIDRs requiring forced routing & firewall allow (single legacy `addressPrefix` still accepted). |
| `backendPort` / `backendProtocol` | no | Override defaults (defaults 443 / Https). |
| `healthProbePath`, `probeInterval`, `probeTimeout`, `unhealthyThreshold`, `probeMatchStatusCodes` | no | Per listener probe tuning. |
| `backendHostHeader` | no | Override host header for backend/SNI preservation. |
| `wafPolicyId` | no | Advanced: attach existing externally managed policy (overrides/ exclusions ignored if both supplied). |
| `wafExclusions` | no | Exclusions list; triggers synthesized per-listener policy (when no `wafPolicyId`). |
| `wafOverrides` | no | Inline WAF tuning; triggers synthesized per-listener policy (when no `wafPolicyId`). |

### 7.1 Example Minimal App Entry

```jsonc
{
  "name": "web1",
  "hostNames": [ "web1.internal.example.gov" ],
  "backendAddresses": [ { "fqdn": "web1-pe.azurewebsites.us" } ],
  "certificateSecretId": "https://kv-example.vault.usgovcloudapi.net/secrets/web1cert/<version>",
  "addressPrefixes": [ "10.60.10.0/24" ]
}
```

### 7.2 Example With Per‑Listener Overrides

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

## 8. Parameters (Selected)

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
| `enableDiagnostics` & `operationsLogAnalyticsWorkspaceResourceId` | Both required to emit diagnostics. |
| `createKeyVaultSecretAccessRole` | Grant Key Vault Secrets User to identity. |
| WAF tuning params (`wafPolicyMode`, `wafManagedRuleSetVersion`, etc.) | Influence new global policy creation. |

## 9. Routing & Firewall Integration

1. Gather all `addressPrefixes` (legacy single field normalized).
2. Deduplicate -> produce `forcedRouteEntries` objects.
3. Route table gets one entry per prefix (next hop = Firewall) without inserting a default route.
4. Firewall module builds allow rules based on precedence:
   * `backendAppPortMaps` (highest)
   * `backendPrefixPortMaps`
   * Broad rule using deduplicated prefixes + `backendAllowPorts` (fallback)

## 10. Certificates & Key Vault

The first available app (or `commonDefaults.defaultCertificateSecretId` if present) is parsed to infer the vault name for an optional secrets access RBAC assignment to the user‑assigned identity. Always supply **versioned** secret URIs to allow safe rotation.

## 11. Managed Identity

One user‑assigned identity is created every deployment; its resource & principal IDs are returned as outputs for downstream RBAC (Key Vault, logging, etc.).

## 12. Diagnostics

Diagnostics module is parameter‑gated; if either the boolean flag is false or the workspace ID is empty no diagnostic setting resource is created (output left blank). This avoids accidental noise or cross‑subscription log writes.

## 13. Deployment Examples

### 13.1 Minimal Parameter File

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

### 13.2 Mixed Strategies (inherit + generated + explicit)

```bicep-params
param apps = [
  { name: 'portal'; hostNames: ['portal.example.gov']; certificateSecretId: 'https://kv/.../portal/<ver>'; backendAddresses: [{ fqdn: 'portal-pe.azurewebsites.us' }]; addressPrefixes: ['10.10.10.0/24'] }
  { name: 'api'; hostNames: ['api.example.gov']; certificateSecretId: 'https://kv/.../api/<ver>'; backendAddresses: [{ ipAddress: '10.20.5.10' }]; addressPrefixes: ['10.20.5.0/24']; wafOverrides: { mode: 'Detection' } }
  { name: 'legacy'; hostNames: ['legacy.example.gov']; certificateSecretId: 'https://kv/.../legacy/<ver>'; backendAddresses: [{ fqdn: 'legacy-pe.azurewebsites.us' }]; addressPrefixes: ['10.30.0.0/24']; wafPolicyId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/legacy-custom' }
]
```

### 13.3 CLI Deployment (Subscription Scope)

```powershell
az deployment sub create `
  --name appgw-mlz `
  --location usgovvirginia `
  --template-file src/add-ons/application-gateway/solution.bicep `
  --parameters @path\to\params.bicepparam
```

Portal deployment is also supported via `solution.json` + `uiDefinition.json` artifacts (commercial & government clouds).

## 14. Post-Deployment Verification

| Check | Expectation |
|-------|-------------|
| Public IP | Static address present & reachable (optional DNS mapped). |
| `listenerNames` | Contains an entry for each app. |
| `perListenerWafPolicyIds` | Blank entries only where no overrides/exclusions/explicit id were provided. |
| `forcedRouteEntries` | Only declared backend CIDRs; no 0.0.0.0/0. |
| Subnet | NSG & route table associated; outbound access disabled flag set. |
| Health probes | All listeners show healthy backends after certificate & host header alignment. |
| Firewall policy | Baseline + (optional) custom rule collections present. |

## 15. Routine Changes

| Action | Steps |
|--------|-------|
| Add application | Append new element to `apps`, redeploy (idempotent). |
| Temporarily relax WAF | Add `wafOverrides.mode = 'Detection'`, redeploy, later remove. |
| Switch to explicit policy | Set `wafPolicyId`, remove overrides & exclusions. |
| Increase autoscale ceiling | Update `commonDefaults.autoscaleMaxCapacity`. |
| Expand backend ports | Add to `backendPrefixPortMaps` or `backendAppPortMaps`. |
| Disable diagnostics | Set `enableDiagnostics = false` OR empty workspace id. |
| Mandatory NSG enforcement | Removed prior optional toggle; hardens baseline by default. |

## 16. Troubleshooting

| Symptom | Probable Cause | Recommended Action |
|---------|---------------|--------------------|
| Policy creation failure (listener) | Unsupported exclusion enum (Gov latency) | Probe with standalone test policy CLI call; adjust variable. |
| 502 or unhealthy probe | Host header or path mismatch | Set `backendHostHeader` or correct `healthProbePath`. |
| Unexpected egress to broad networks | Overly broad CIDR in `addressPrefixes` | Narrow to specific subnet ranges. |
| Overrides not applied | `wafPolicyId` simultaneously specified | Remove explicit ID to allow generation. |
| No diagnostics output | Flag/workspace mismatch | Ensure both enabled + valid workspace ID. |

## 17. Outputs

| Output | Meaning |
|--------|---------|
| `appGatewayPublicIp` | Public IPv4 address. |
| `wafPolicyResourceId` | Global WAF policy resource ID. |
| `perListenerWafPolicyIds` | Effective listener policy (blank = global). |
| `forcedRouteEntries` | Objects describing each routed backend prefix. |
| `listenerNames` | Listener resource names. |
| `backendPoolNames` | Backend pool names. |
| `userAssignedIdentityResourceIdOut` | Deployed identity resource ID. |
| `userAssignedIdentityPrincipalId` | Principal ID for RBAC correlation. |
| `diagnosticsSettingId` | Diagnostic setting (blank when disabled). |

## 18. File Map

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

## 19. Change History (Excerpt)

| Change | Rationale |
|--------|-----------|
| Per listener policy generation | Enable granular WAF posture without manual policy sprawl. |
| Deduplicated backend prefix logic | Prevent redundant routes & firewall entries. |
| Mandatory NSG enforcement | Removed historical toggle; ensures consistent hardening. |
| Diagnostics gating refinement | Avoid unintended log noise when not configured. |
| Complete documentation rewrite | Improve clarity & remove scenario naming. |
| Simplified WAF policy documentation | Emphasize automatic behavior; mark explicit IDs as advanced. |

---
Please file issues or enhancement requests with the commit hash for traceability.

> `addressPrefixes` (array) supersedes the older singular `addressPrefix`. Provide **only** the CIDRs requiring egress via Firewall; template deduplicates them and produces `forcedRouteEntries` output.
>
> Legacy support: `addressPrefix` (string) is still accepted for backward compatibility. Prefer `addressPrefixes`.

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
* Firewall rule module receives the deduplicated backend CIDRs plus allowed ports to construct least‑privilege egress.
* NSG enforced on gateway subnet for inbound restriction (443 + platform requirements); outbound Internet access disabled at subnet level to align with centralized egress model.

## WAF Overrides Per Listener

Each app/listener may supply a `wafOverrides` object (and/or `wafExclusions`) to selectively diverge from the **generated baseline**. Missing keys inherit generated defaults. Presence of `wafOverrides` or `wafExclusions` (and absence of explicit `wafPolicyId`) triggers creation of a per‑listener WAF policy.

Advanced: If you already have an externally managed WAF policy for a listener, set `wafPolicyId` and omit overrides / exclusions (no per‑listener policy generated); inline settings are ignored when an explicit ID is present.

> NOTE: Azure Government WAF_v2 (current platform state) supports a single IPv4 public frontend; multi‑public‑IP mode removed. Use host‑based (multi‑site) listeners for segmentation.

## Forced Route Entries Output

`forcedRouteEntries` output surfaces each unique backend CIDR prefix (deduplicated) generating a route table entry (next hop = Firewall private IP).

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

// Optional diagnostics
param enableDiagnostics = true
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

### Complexity Clarifications

| Aspect | Why It Exists | Key Rule | Pitfalls |
|--------|---------------|----------|----------|
| `hostNames` vs `backendAddresses` | Separate concern: request matching vs target endpoints | Hostnames drive listener creation; backendAddresses populate pool | Duplicating hostnames across two apps causes deployment errors |
| FQDN vs IP backend entries | Support dynamic (DNS-resolved) vs static targets | Choose one object type per entry | Adding both forms for same server duplicates probes |
| `backendHostHeader` | Preserve expected Host/SNI for backend cert | Set to public host when backend cert expects it | Mismatch causes TLS/SNI failures |
| `addressPrefixes` | Build selective UDR + firewall rules | Only list prefixes that must route via Firewall | Overly broad (e.g. /8) defeats least privilege |
| Per-listener WAF generation | Granular tuning without many external policies | Provide overrides/exclusions & omit `wafPolicyId` | Empty overrides still trigger policy generation |
| Global vs listener WAF precedence | Clarify control hierarchy | Listener-level policy overrides global for that listener | Mixing expectations causes confusion |
| Certificate coverage | All listener hostnames must be covered | Ensure SAN/wildcard covers each | Missing SAN → TLS errors |
| Probe status codes array | Allow structural customization | Narrow after stabilization | Broad ranges can hide issues |
| Autoscale vs subnet size | Preserve growth headroom | Use /26 or larger for scale | Too small blocks scaling |
| Key Vault secret ID parsing | Derive vault name automatically | Use full versioned secret URI | Unversioned secrets complicate rotation |

### Designing the `apps` Array

Create one element per logical application boundary (distinct probe path, cert, WAF posture, or backend behavior). Do NOT create separate app entries just to add more backend addresses—append addresses inside the existing app entry instead.

### Decision Matrix: FQDN vs IP

Choose FQDN when backend is:

* App Service (private endpoint) or other PaaS with mutable IP.
* Internal Load Balancer where pool membership may change.
* Service relying on DNS-based failover.

Choose IP when backend is:

* Static VM NIC with reserved private IP.
* Appliance or endpoint without internal DNS registration.
* Fixed ILB VIP where DNS indirection not required.

### Valid & Invalid Backend Definitions

Valid mixed backend set (two distinct systems):

```jsonc
"backendAddresses": [
  { "fqdn": "app1-pe.azurewebsites.us" },
  { "ipAddress": "10.20.10.5" }
]
```

Invalid (duplicate FQDN):

```jsonc
"backendAddresses": [
  { "fqdn": "app1-pe.azurewebsites.us" },
  { "fqdn": "app1-pe.azurewebsites.us" }
]
```

### Listener Naming and Uniqueness

`name` seeds listener, probe, and backend pool names. Keep under Azure name length limits (< 80 chars). Names must be unique across apps.

### WAF Override Minimal Example

```jsonc
"wafOverrides": {
  "mode": "Prevention",
  "managedRuleSetVersion": "3.2",
  "ruleGroupOverrides": [ { "ruleGroupName": "REQUEST-942-APPLICATION-ATTACK-SQLI", "rules": [ { "ruleId": "942100", "state": "Disabled" } ] } ]
}
```

Exclude unused keys—they inherit from generated defaults or global policy baseline.

### Common Pitfalls & Remedies

| Pitfall | Symptom | Structural Fix |
|---------|---------|----------------|
| Duplicate hostNames across apps | Deployment validation error | Consolidate or adjust hostnames |
| Missing certificate SAN for a host | TLS handshake failure | Reissue cert incl. host or split app |
| Overly broad addressPrefixes | Unintended routing | Replace with granular CIDRs |
| Overrides + wafPolicyId both supplied | Overrides ignored | Advanced use: remove overrides when using `wafPolicyId` |
| Supplying identity parameters | No effect | Remove identity params (auto-created) |
| enableDiagnostics without workspace ID | No diagnostics deployed | Provide workspace ID or disable diagnostics |
| backendHostHeader mismatch | 502/SSL errors | Match header to cert CN/SAN |

---
These clarifications are structural; operational runtime behaviors (monitoring, performance analysis) remain intentionally out of scope.

## Scope Clarification

Operational guidance (KQL queries, troubleshooting, health probe response strategies, runtime dashboards) is intentionally excluded. This document focuses on structural deployment integration within MLZ hub-spoke, routing mechanics, listener configuration surface, and composing parameter input for TLS/WAF enablement.

---
Active implementation; README constrained to integration & configuration scope. Report mismatches via issue with commit hash.
