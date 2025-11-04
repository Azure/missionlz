# Application Gateway Add-On (MLZ Hub)

## Overview
Deploys an Azure Application Gateway (WAF_v2) in the MLZ hub for: HTTPS termination, Web Application Firewall enforcement, and selective forced routing of ONLY declared backend CIDRs through Azure Firewall. This document intentionally focuses on the infrastructure contract (parameters, listener schema, routing model, WAF policy resolution, certificates, and outputs). It is NOT an operational runbook: performance tuning, false‑positive triage, probe debugging, and broader Application Gateway operations are out of scope—see `ADVANCED.md` for deep WAF tuning, exclusions, certificate rotation, orphan policy cleanup, and advanced troubleshooting. This add-on is intentionally MLZ-specific and assumes the presence of the MLZ hub Azure Firewall and its Firewall Policy named via the MLZ naming convention; it is not a general-purpose standalone template.

## Prerequisites
* Existing MLZ hub virtual network and resource group (Application Gateway deploys into a dedicated subnet you supply / that the template creates when absent).
* Dedicated empty subnet (no other resources) sized for autoscale (default /26). Not shared with other services.
* MLZ hub Azure Firewall **and** its Firewall Policy (required). The add-on always resolves the hub Firewall private IP and attaches rule collection groups to the MLZ-named Firewall Policy; it will not operate in an environment without them.
* (Optional) Log Analytics workspace resource ID if you want diagnostics (leave empty to skip).
* Hub Key Vault containing versioned certificate secrets for each listener (at least one secret version required to infer vault and assign RBAC).
* Appropriate RBAC: permission to deploy networking + role assignments (Network Contributor + User Access Administrator or equivalent) at target scopes.

## Features
* Locked-down dedicated subnet + enforced NSG (inbound 443 + platform requirements only).
* Selective UDR (Application Gateway subnet only): one route per backend CIDR you declare; the route table for the **Application Gateway subnet** never inserts a 0.0.0.0/0 default route.
* Least‑privilege egress firewall rules derived from per-app `addressPrefixes` + port maps.
* Global WAF policy auto-created unless you adopt an existing one; per-listener policies only when overrides/exclusions supplied.
* Explicit `wafPolicyId` on an app always wins (overrides/exclusions ignored for that app).
* Deterministic certificate retrieval via versioned Key Vault secret URIs; automatic Key Vault Secrets User RBAC assignment for the inferred hub vault.
* Idempotent re-deploy (unchanged parameters = no drift).
* Diagnostics automatically provisioned when a Log Analytics workspace resource ID is provided.


## Architecture Flow
Client → Application Gateway (public IP) → WAF (global or per‑listener) → Forced route (backend CIDR) → Azure Firewall → Backend service.

## Required Parameters (Quick Reference)
Minimal deployment requires only a handful of top‑level parameters. Everything else derives from `apps` objects or sensible defaults in `commonDefaults`.

| Parameter | Purpose |
|-----------|---------|
| `location` | Region for all resources. |
| `hubVnetResourceId` | Existing hub VNet hosting the dedicated subnet. |
| `appGatewaySubnetAddressPrefix` | CIDR for (or of) the dedicated subnet. |
| `apps` | Array of listener/backends (each must include cert + backend addresses + at least one `addressPrefixes` CIDR). |
| `commonDefaults` | Shared listener defaults (ports, protocol, probe timings, autoscale bounds, generated WAF defaults). |
| `operationsLogAnalyticsWorkspaceResourceId` | Optional diagnostics sink (blank to omit). |

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

## Routine Operations (Idempotent)
| Action | Required Input Change |
|--------|-----------------------|
| Add listener/app | Append new object to `apps`. |
| Remove listener/app | Delete object from `apps` (removes listener + pool + probe + routing rule + certificate reference). |
| Introduce inline WAF tuning | Add `wafOverrides` or `wafExclusions` (creates per-listener policy). |
| Adopt external listener policy | Set `wafPolicyId`; remove overrides/exclusions. |
| Switch global to external | Set `existingWafPolicyId`. |
| Expand allowed egress ports | Update maps or `backendAllowPorts`. |
| Add diagnostics | Provide `operationsLogAnalyticsWorkspaceResourceId` (setting persists if later cleared; delete manually to remove). |

NOTE: If a removed app previously had a synthesized per-listener WAF policy (due to overrides/exclusions), that standalone WAF policy resource is not auto-deleted in incremental mode and becomes an orphan. Delete manually if no longer needed.

## Firewall Rule Precedence & NSG Egress Controls
The firewall rule module constructs collections in deterministic order inside a baseline rule collection group:

1. Platform service tags (control plane & monitoring) – always allowed (Network + Application rules).
2. CRL / OCSP FQDNs for certificate validation.
3. Backend allow collection (if backends declared) selecting the HIGHEST specificity among:
  * Per‑app maps (`backendAppPortMaps`): destinationPrefixes[] + ports[] (highest precedence)
  * Per‑prefix maps (`backendPrefixPortMaps`): single prefix + ports[]
  * Fallback broad rule: all backend prefixes + `backendAllowPorts` (only if above maps absent)
4. (Optional) Custom rule collection groups you supply (lower or higher priority numbers as you choose outside the baseline group).

All unspecified egress is implicitly denied by the Firewall default deny.

NSG outbound rules separately allow only:
* VirtualNetwork (east‑west)
* Service tags union: AzureKeyVault, AzureActiveDirectory, AzureMonitor plus any you add via `additionalAllowedOutboundServiceTags` (deduped)
* Everything else outbound is denied (final DenyAllOutbound).

Use `additionalAllowedOutboundServiceTags` sparingly—each addition broadens egress. Prefer explicit backend CIDR routing through Firewall over expanding service tag list for arbitrary Internet endpoints.

## Routing & Firewall
Workflow:
1. Collect all `addressPrefixes` across apps (each app must supply at least one backend CIDR that actually needs egress via the Firewall—don't include superfluous ranges).
2. Generate one UDR route per unique CIDR (`forcedRouteEntries`; next hop = Firewall private IP). No 0.0.0.0/0 default route is inserted in the **Application Gateway subnet** route table.
3. Associate the route table + enforced NSG with the Application Gateway subnet (NSG creation is mandatory).
4. Build firewall allow rules in strict precedence order:
  * `backendAppPortMaps` (per app + per port specificity; highest)
  * `backendPrefixPortMaps` (CIDR → port list)
  * Broad fallback rule: all collected CIDRs + `backendAllowPorts` (only if needed)
5. Anything not explicitly allowed is denied by the Firewall's default deny.

Result: Minimal egress surface—fine‑grained maps first, broad fallback last. The template resolves the Azure Firewall private IP automatically (no hardcoded next hop).

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

### Backend Address Choice: FQDN vs IP

| Address Type | Use When | Pros | Considerations | Example |
|--------------|----------|------|----------------|---------|
| FQDN (public PaaS) | Backend is an App Service / multi-instance PaaS with stable DNS name | Simplifies scaling; no IP tracking | DNS must resolve privately or over Internet as allowed by egress rules | `{ "fqdn": "app1-pe.azurewebsites.us" }` |
| FQDN (private DNS) | Private Endpoint or internal service with private zone record | Follows IP changes automatically | Requires private DNS zone link correctness | `{ "fqdn": "api.internal.corp.local" }` |
| Static IP | Backend on fixed VM / NIC | Deterministic; no DNS dependency | Manual update if backend IP changes | `{ "ipAddress": "10.60.2.10" }` |
| Multiple IPs | Simple active/active VM set | Basic distribution without VMSS | Health probe per pool member only; no autoscale | `[ { "ipAddress": "10.60.2.10" }, { "ipAddress": "10.60.2.11" } ]` |
| Mixed (FQDN + IP) | Transitioning services (lift & shift to PaaS) | Supports phased migration | Keep probe path/protocol identical across members | `[ { "ipAddress": "10.60.2.10" }, { "fqdn": "app1-pe.azurewebsites.us" } ]` |

For extended guidance (naming limits, certificate alignment, pitfalls) see [ADVANCED.md](./ADVANCED.md).

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

## Probes & Autoscale Defaults
Each listener receives a dedicated health probe. Defaults (overridable per listener via fields on the app object):

| Setting | Default |
|---------|---------|
| Interval | 30s |
| Timeout | 30s |
| Unhealthy threshold | 3 |
| Match status codes | 200-399 |

Customize via `probeInterval`, `probeTimeout`, `unhealthyThreshold`, and `probeMatchStatusCodes` on individual app entries when required (e.g., non‑200 success codes). Keep intervals aligned to backend response characteristics; avoid aggressively low timeouts that can mask transient network jitter.

Autoscale defaults: `autoscaleMinCapacity: 1`, `autoscaleMaxCapacity: 2` (set in `commonDefaults`). Increase the upper bound only when sustained capacity or WAF latency metrics justify it; keep min at 1 unless cold start latency is unacceptable for first requests.

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
* Rotation involves publishing a new version of the existing Key Vault secret and updating the parameter file to reference that version GUID before redeployment (see Azure docs below).
* If you omit the version (ending at `/secrets/<secretName>`), the latest version can change underneath you—breaking idempotence and making rollback harder.

Edge cases:

* If there are no apps yet and no `commonDefaults.defaultCertificateSecretId`, the vault name cannot be inferred—role assignment is skipped. Add at least one app with a valid versioned secret before relying on Key Vault RBAC.
* If the Key Vault lives in a different resource group, set `keyVaultResourceGroupName` so the role assignment targets the right scope.
* If you break the single‑hub‑vault assumption and place certificates in multiple vaults, only the first (or the default) vault receives automatic RBAC. Manually assign **Key Vault Secrets User** (or equivalent access) for the gateway identity on every other vault you reference.

Quick example:

References (public documentation):

* Azure Application Gateway overview: https://learn.microsoft.com/azure/application-gateway/overview
* Web Application Firewall (WAF) on Application Gateway: https://learn.microsoft.com/azure/web-application-firewall/ag/ag-overview
* Application Gateway certificates: https://learn.microsoft.com/azure/application-gateway/certificates
* Key Vault certificates & secret versions: https://learn.microsoft.com/azure/key-vault/certificates/about-certificates
* Managed rule sets (OWASP CRS): https://learn.microsoft.com/azure/web-application-firewall/ag/application-gateway-crs-rule-group-overview

```
certificateSecretId: "https://mlz-hub-kv.vault.usgovcloudapi.net/secrets/web1cert/0d9c2d4e3a2f4d8e8bb1f6c9d5a1b234"
```

This results in a role assignment granting the gateway identity read access to `mlz-hub-kv` secrets so it can fetch the certificate during deployment/run.

Always use **versioned** URIs and plan rotations by creating the new version first, then updating your parameter file.

## Diagnostics

Diagnostics are created automatically when you provide a valid Log Analytics workspace resource ID via `operationsLogAnalyticsWorkspaceResourceId`. Leave it empty to skip deployment of the diagnostic setting (output blank). There is no separate enable flag.

Recommendation: Do not skip diagnostics unless you enforce equivalent logging via another mechanism (e.g., Azure Policy assigning diagnostic settings, centralized automation, or post‑deployment scripting). Omitting diagnostics reduces visibility for WAF alert triage, performance analysis, and security investigations.

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


## Post-Deployment Verification

| Check | Expectation |
|-------|-------------|
| Public IP | Static address present & reachable (optional DNS mapped). |
| `listenerNames` | Contains an entry for each app. |
| `perListenerWafPolicyIds` | Blank entries only where no overrides/exclusions/explicit id were provided. |
| `forcedRouteEntries` | Only declared backend CIDRs; Application Gateway subnet route table has no 0.0.0.0/0 default. |
| Subnet | NSG & route table associated; outbound access disabled flag set. |
| Health probes | All listeners show healthy backends after certificate & host header alignment. |
| Firewall policy | Baseline + (optional) custom rule collections present. |



## Security

* TLS 1.2+ enforced; HTTPS‑only listeners.
* WAF baseline in Prevention (override globally or per listener).
* Certificates pulled from Key Vault via user‑assigned identity (RBAC role optional toggle).
* NSG inbound restricted to 443 + AzureLoadBalancer + ephemeral probe ports; all other inbound denied.
* **No** default 0.0.0.0/0 forced route on the Application Gateway subnet—only declared backend prefixes are routed via Firewall (prevents asymmetric probing failures).
* Host header override allows internal private resolution while preserving public FQDN SNI for backend cert validation.
* Outbound default Internet access disabled on the Application Gateway subnet (controlled egress via Firewall). No implicit 0.0.0.0/0 UDR on this subnet to avoid asymmetric probe paths.

## Hub-Spoke Integration & Routing

* Deployed into the MLZ hub VNet in a dedicated subnet (`AppGateway` by default) sized per autoscale recommendation (/26 default here).
* Backends reside in spoke VNets or private endpoints; only declared backend CIDR prefixes (via each app's `addressPrefixes`) are forced through the hub Firewall using UDR entries created by the add-on.
* No default 0.0.0.0/0 route on the Application Gateway subnet: prevents asymmetric paths for health probes and ensures only intentional egress inspection (other hub or spoke subnets may legitimately have a default route per design).
* Firewall rule module receives the backend CIDRs plus allowed ports to construct least‑privilege egress.
* NSG enforced on gateway subnet for inbound restriction (443 + platform requirements); outbound Internet access disabled at subnet level to align with centralized egress model.

## WAF Overrides Per Listener

Supply `wafOverrides` and/or `wafExclusions` (without an explicit `wafPolicyId`) to generate a per‑listener WAF policy; otherwise listeners inherit the global policy described earlier. If you set `wafPolicyId`, any inline overrides/exclusions are ignored.

> NOTE: Azure Government WAF_v2 (current platform state) supports a single IPv4 public frontend; use host‑based (multi‑site) listeners for segmentation.


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


