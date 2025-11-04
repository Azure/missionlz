# Application Gateway (Scenario A: WAF Before Firewall)

This README reflects the current `solution.bicep` implementation (modules relocated under `modules/`).
> IMPORTANT (Azure Government): Some WAF exclusion `matchVariable` enum values documented for public cloud (e.g. `RequestHeaderNames`, `RequestBodyPostArgs`) may not yet be accepted in this environment. Attempting invalid values causes deployment failures at the per-listener policy creation step. Validate exclusions by creating a temporary test policy with the Azure CLI before embedding them in `apps`.

## WAF Precedence Logic (Listener vs Global)

Order of evaluation for each listener:

1. Explicit `wafPolicyId` on the app element (highest precedence; no generated policy).
2. Generated per-listener policy when `wafOverrides` OR `wafExclusions` provided (and no `wafPolicyId`).
3. Global gateway policy (resolver output) when neither overrides/exclusions nor explicit ID supplied.

The deployment surfaces an output array `perListenerWafPolicyIds` showing the effective policy per listener (blank means inherited global).

## Safely Introducing Exclusions (Azure Gov)

1. Create a test policy: `az network application-gateway waf-policy create -g <rg> -n testEnumProbe --type OWASP --version 3.2`
2. Add a candidate exclusion: `az network application-gateway waf-policy managed-rules exclusion add -g <rg> --policy-name testEnumProbe --match-variable <Candidate> --selector-match-operator Equals --selector x-probe`
3. If accepted, reuse `<Candidate>` inside `wafExclusions` / `wafOverrides.exclusions`. Remove the test policy afterward.

Record discovered valid enum names for your environment in a team doc to avoid future trial/error.

## Advanced `.bicepparam` Patterns

### Multiple Certificates & Mixed WAF Strategies

Example combining inherited global policy, generated listener policy, and explicit external policy:

```bicep-params
<!-- markdownlint-disable MD013 -->
# Application Gateway Add-On (Scenario A: WAF Before Firewall)
<!-- markdownlint-enable MD013 -->

## Purpose

Deploy a single Azure Application Gateway (WAF_v2) in the Mission Landing Zone (MLZ) hub virtual network. Scenario A places TLS termination and WAF inspection **before** traffic reaches Azure Firewall while still enforcing selective, least‑privilege egress from the gateway through the firewall.

## When to Use

Use this add-on when you need:

* Central TLS termination & WAF for multiple internal applications (multi‑site listeners)
* Per‑application (listener) WAF tuning or explicit listener WAF policies
* Strong control of egress (only declared backend prefixes are routed through Firewall; no blanket 0.0.0.0/0)
* Key Vault sourced certificates without storing secrets in the repo
* Hub‑spoke alignment where application backends live in spokes or expose private endpoints

Not in scope: Scenario B (gateway behind firewall), Azure Front Door, private‑only frontends.

## Architecture Overview

Flow: Internet → Public IP (App Gateway) → WAF (global or per‑listener policy) → Selective UDR (only declared backend CIDRs) → Azure Firewall → Backend (ILB / Private Endpoint / VM / PaaS).

Key design points:
* Subnet hardened (no default outbound, optional NSG) sized /26 (autoscale headroom)
* Selective routing: only `apps[].addressPrefixes` appear in route table & firewall rules
* WAF policy resolver module creates or adopts global policy; per‑listener policies generated only when needed
* User‑assigned identity always created; optional Key Vault secrets RBAC assignment
* Diagnostics setting created only when both flag and workspace ID set

## Components

| Module | Responsibility |
|--------|----------------|
| `solution.bicep` | Orchestration, naming, identity, subnet, route table, NSG, WAF resolver, listener shaping, diagnostics, firewall rules. |
| `modules/appgateway-core.bicep` | Application Gateway resource, listeners, probes, pools, per‑listener WAF policies. |
| `modules/wafpolicy-resolver.bicep` | Create or reuse global WAF policy. |
| `modules/appgateway-subnet.bicep` | Authoritative subnet + delegation + associations. |
| `modules/appgateway-route-table.bicep` | Builds selective UDRs for backend prefixes. |
| `modules/appgateway-nsg.bicep` | Baseline NSG (443 + platform) + deny all. |
| `modules/appgateway-firewall-rules.bicep` | Baseline firewall egress collections + optional custom groups. |
| `modules/appgateway-diagnostics.bicep` | Diagnostic settings binding. |
| `modules/resolve-firewall-ip.bicep` | Retrieves firewall private IP. |
| `modules/kv-role-assignment.bicep` | Optional Key Vault secrets role assignment. |

## WAF Strategy & Precedence

Per listener evaluation order:
1. Explicit `wafPolicyId` on listener (apps entry)
2. Generated per‑listener policy (if `wafOverrides` or `wafExclusions` present)
3. Inherit global policy (resolver output)

Output `perListenerWafPolicyIds` shows effective policy (blank = inherited global).

Azure Government Note: Some exclusion `matchVariable` values documented publicly may not yet be accepted. Validate unfamiliar enum values with a temporary test policy before committing them.

## App (Listener) Object Schema

Each element in `apps` drives one HTTPS multi‑site listener plus its backend pool and optional per‑listener WAF policy.

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `name` | string | yes | Seed for listener/pool/probe names. |
| `hostNames` | string[] | yes | Host headers for multi‑site routing. |
| `backendAddresses` | object[] | yes | `{ fqdn }` or `{ ipAddress }` entries. |
| `certificateSecretId` | string | yes | Versioned Key Vault secret for certificate. |
| `addressPrefixes` | string[] | recommended | Backend CIDRs for selective routing & firewall allow rules. |
| `backendPort` / `backendProtocol` | int / string | no | Override defaults (default 443 / Https). |
| `healthProbePath` / `probeInterval` / `probeTimeout` / `unhealthyThreshold` / `probeMatchStatusCodes` | mixed | no | Per listener probe tuning. |
| `backendHostHeader` | string | no | Override Host header for backend & probe (SNI alignment). |
| `wafPolicyId` | string | no | Explicit existing listener WAF policy (skip generation). |
| `wafExclusions` | array | no | List of baseline exclusions (triggers generated policy). |
| `wafOverrides` | object | no | Inline tuning (mode, sizes, ruleGroupOverrides, exclusions). |

Legacy `addressPrefix` (single) still accepted; prefer `addressPrefixes`.

### `wafOverrides` Object (selected keys)

| Key | Meaning | Default Source |
|-----|---------|----------------|
| `mode` | Detection or Prevention | `commonDefaults.generatedPolicyMode` or global policy mode |
| `requestBodyCheck` | Enable inspection | global / generated defaults |
| `maxRequestBodySizeInKb` | Body size limit | global default (128) |
| `fileUploadLimitInMb` | Upload size limit | global default (100) |
| `managedRuleSetVersion` | OWASP CRS version | generated/global default (3.2) |
| `exclusions` | Additional exclusions | empty [] |
| `ruleGroupOverrides` | Fine rule actions | empty [] |

## Parameter Highlights (`solution.bicep`)

| Parameter | Purpose |
|-----------|---------|
| `hubVnetResourceId` | Hub VNet hosting gateway subnet. |
| `appGatewaySubnetAddressPrefix` | Subnet CIDR (default /26). |
| `apps` / `commonDefaults` | Listener definitions + shared defaults. |
| `existingWafPolicyId` | Reuse existing global WAF policy. |
| `backendAllowPorts` | Broad allowed ports when not using detailed maps. |
| `backendPrefixPortMaps` / `backendAppPortMaps` | Detailed per‑prefix or per‑app port rules (firewall). |
| `customAppGatewayFirewallRuleCollectionGroups` | Append custom firewall policy groups. |
| `enableDiagnostics` + `operationsLogAnalyticsWorkspaceResourceId` | Diagnostics gating (both required). |
| `createSubnetNsg` | Toggle NSG creation. |
| `createKeyVaultSecretAccessRole` | Assign Secrets User to user‑assigned identity. |
| WAF tuning params | Global policy creation (mode, version, sizes). |

## Selective Routing & Firewall Rules

* Route table only includes declared backend CIDRs (no 0.0.0.0/0) — avoids asymmetric probe paths.
* Firewall baseline rule group adds:
  * Platform service tags (AAD, ARM, Traffic Manager, Monitor, Storage) 443
  * CRL/OCSP FQDNs for certificate revocation
  * Backend allow collection built from (precedence): `backendAppPortMaps` → `backendPrefixPortMaps` → (`backendPrefixes` + `backendAllowPorts`)

## Diagnostics

Created only when:
1. `enableDiagnostics = true`
2. `operationsLogAnalyticsWorkspaceResourceId` not empty

## Deployment

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
    name: 'app1'
    hostNames: [ 'app1.example.gov' ]
    certificateSecretId: 'https://kv-example.vault.usgovcloudapi.net/secrets/app1cert/<version>'
    backendAddresses: [ { fqdn: 'app1-pe-appservice.azurewebsites.us' } ]
    addressPrefixes: [ '10.50.1.0/24' ]
  }
]
```

### Mixed WAF Strategies Example

```bicep-params
// Inherit global, generate, explicit
param apps = [
  { name: 'ops'; hostNames: ['ops.example.gov']; certificateSecretId: 'https://kv/.../ops/<ver>'; backendAddresses: [{ fqdn: 'ops-pe.azurewebsites.us' }]; addressPrefixes: ['10.11.10.0/24'] }
  { name: 'identity'; hostNames: ['identity.example.gov']; certificateSecretId: 'https://kv/.../identity/<ver>'; backendAddresses: [{ fqdn: 'identity-pe.azurewebsites.us' }]; addressPrefixes: ['10.11.20.0/24']; wafOverrides: { mode: 'Detection' } }
  { name: 'shared'; hostNames: ['shared.example.gov']; certificateSecretId: 'https://kv/.../shared/<ver>'; backendAddresses: [{ fqdn: 'shared-pe.azurewebsites.us' }]; addressPrefixes: ['10.11.30.0/24']; wafPolicyId: '/subscriptions/.../providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/shared-explicit' }
]
```

### CLI Deploy (Subscription Scope)

```powershell
az deployment sub create `
  --name appgw-scenarioA `
  --location usgovvirginia `
  --template-file src/add-ons/application-gateway/solution.bicep `
  --parameters @path\to\file.bicepparam
```

### Portal Deploy

This add-on includes a `solution.json` and `uiDefinition.json` enabling portal deployment (Commercial & Gov). Use the standard Deploy to Azure buttons (see repository root README) or custom deployment blade with raw GitHub URLs.

## Validation Checklist

After deploy verify:

1. `appGatewayPublicIp` output resolves to static IP; DNS (if any) updated.
2. `listenerNames` list matches all apps.
3. `perListenerWafPolicyIds` contains IDs only for listeners with overrides/exclusions/explicit policies; blanks otherwise.
4. `forcedRouteEntries` contains only declared backend CIDRs.
5. Subnet shows NSG and route table associations; no default 0.0.0.0/0 route.
6. Backend health probes green.
7. Firewall policy rule collection group shows platform + backend rules.

## Common Customizations

| Goal | Change |
|------|--------|
| Add new app | Append to `apps` with hostNames, cert, backendAddresses, addressPrefixes. |
| Temporarily relax WAF | Add `wafOverrides: { mode: 'Detection' }` for that app. |
| Explicit listener policy | Set `wafPolicyId` (remove overrides). |
| Increase body size | Set `wafOverrides.maxRequestBodySizeInKb`. |
| Add backend port range | Use `backendPrefixPortMaps` or `backendAppPortMaps`. |
| More capacity | Raise `commonDefaults.autoscaleMaxCapacity`. |
| Disable diagnostics | Set `enableDiagnostics=false` or clear workspace ID. |

## Troubleshooting Tips

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Deployment fails on exclusion enum | Unsupported `matchVariable` in Gov | Probe with temporary test policy. |
| Listener health 502 | Host header mismatch | Set `backendHostHeader`. |
| Unexpected broad routing | Overly broad `addressPrefixes` (e.g. /16) | Narrow to specific backend subnets. |
| Overrides ignored | `wafPolicyId` also set | Remove overrides or drop explicit policy. |
| No diagnostics | Missing workspace ID or flag false | Provide both or disable flag. |

## Outputs

| Output | Description |
|--------|-------------|
| `appGatewayPublicIp` | Public IPv4 address. |
| `wafPolicyResourceId` | Global WAF policy ID. |
| `perListenerWafPolicyIds` | Effective listener policy IDs (blank = global). |
| `forcedRouteEntries` | Objects: `{ prefix, source }` for UDR creation. |
| `listenerNames` | Listener resource names. |
| `backendPoolNames` | Backend pool names. |
| `userAssignedIdentityResourceIdOut` | Identity resource ID. |
| `userAssignedIdentityPrincipalId` | Identity principal ID (RBAC). |
| `diagnosticsSettingId` | Diagnostic setting (blank if disabled). |

## Files

| File | Purpose |
|------|---------|
| `solution.bicep` | Entry point (subscription scope). |
| `solution.json` / `uiDefinition.json` | Portal deployment artifacts. |
| `modules/appgateway-core.bicep` | Gateway + listeners + per-listener WAF. |
| `modules/wafpolicy-resolver.bicep` | Global WAF creation/adoption. |
| `modules/appgateway-subnet.bicep` | Subnet & delegation. |
| `modules/appgateway-route-table.bicep` | Selective UDRs. |
| `modules/appgateway-nsg.bicep` | Baseline NSG. |
| `modules/appgateway-firewall-rules.bicep` | Firewall policy rule groups. |
| `modules/appgateway-diagnostics.bicep` | Diagnostics setting. |
| `modules/resolve-firewall-ip.bicep` | Firewall private IP lookup. |
| `modules/kv-role-assignment.bicep` | Key Vault Secrets RBAC. |

## Change Log

Major recent enhancements:

* Per-listener WAF policy generation & precedence logic
* Selective routing refactor (deduplicated prefixes)
* Diagnostics gating (both flag + workspace ID)
* Expanded README with structured patterns (this rewrite)

---
Feedback & issues: open a GitHub issue with the commit hash and a clear reproduction or enhancement rationale.
| `enableDiagnostics` / `operationsLogAnalyticsWorkspaceResourceId` | Control diagnostics creation/association (both required). |
| `createSubnetNsg` | Toggle creation of NSG specifically for AppGW subnet. |
| `createKeyVaultSecretAccessRole` | Create Key Vault Secrets User RBAC assignment for the user-assigned identity (derived from first cert secret). |
| `deploymentNameSuffix` | Unique suffix for deployment-scoped module names (defaults to `utcNow()`; pin for deterministic what-if). |
| `identifier`, `environmentAbbreviation`, `locationAbbreviation`, `networkName` | Optional naming inference overrides (inferred from hub VNet name when omitted). |
| `backendPrefixPortMaps`, `backendAppPortMaps` | Advanced shaping (leave empty unless extending firewall logic). |
| `resourceAbbreviations` | Abbreviation object (loaded automatically from repo JSON unless overridden). |

### `apps` Element Structure

```jsonc
{
  "name": "app1",                                  // Listener + derived pool/probe name seed
  "hostNames": [ "app1.contoso.gov" ],             // One or more host headers -> multi-site listener
  "backendAddresses": [                             // Backend pool entries
    { "fqdn": "app1-ilb.internal.contoso.gov" },
    { "ipAddress": "10.20.10.5" }
  ],
  "certificateSecretId": "https://kv.vault.usgovcloudapi.net/secrets/app1cert/<version>",
  "healthProbePath": "/healthz",                   // Optional (defaults from commonDefaults)
  "backendPort": 443,                               // Optional
  "backendProtocol": "Https",                      // Optional
  "probeInterval": 30,
  "probeTimeout": 30,
  "unhealthyThreshold": 3,
  "probeMatchStatusCodes": [ "200" ],              // Optional per-listener override (default often ["200-399"])
  "backendHostHeader": "mlz-ops-webapp1.azurewebsites.us", // Optional Host/SNI override
  "addressPrefixes": [ "10.20.0.0/16" ],           // Used for forced routes & firewall rules
  "wafPolicyId": "",                              // Optional explicit listener WAF policy
  "wafExclusions": [
    { "matchVariable": "RequestHeaderNames", "selectorMatchOperator": "Equals", "selector": "x-custom-ignore" }
  ],
  "wafOverrides": {                                 // Triggers generated per-listener WAF policy
    "mode": "Detection",
    "requestBodyCheck": true,
    "maxRequestBodySizeInKb": 256,
    "fileUploadLimitInMb": 150,
    "managedRuleSetVersion": "3.2",
    "exclusions": [
      { "matchVariable": "RequestHeaderNames", "selectorMatchOperator": "Equals", "selector": "x-ignore" }
    ],
    "ruleGroupOverrides": [
      { "ruleGroupName": "REQUEST-930-APPLICATION-ATTACK-LFI", "rules": [ { "ruleId": "930100", "state": "Disabled" } ] }
    ]
  }
}
```

> `addressPrefixes` (array) supersedes the older singular `addressPrefix`. Provide **only** the CIDRs requiring egress via Firewall; template deduplicates them and produces `forcedRouteEntries` output.
>
> Legacy support: `addressPrefix` (string) is still accepted for backward compatibility. Prefer `addressPrefixes`.

## Modules

* `solution.bicep` – orchestration (naming inference, subnet creation, NSG/route table, WAF policy resolution, diagnostics, firewall rules, per‑listener object shaping, identity RBAC to Key Vault).
* `modules/appgateway-core.bicep` – gateway resource, dynamic listeners, pools, probes, autoscale, generated per‑listener WAF policies.
* `modules/appgateway-subnet.bicep` – authoritative subnet definition with optional NSG & route table association.
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
* NSG optionally applied to gateway subnet for inbound restriction (443 + platform requirements); outbound Internet access disabled at subnet level to align with centralized egress model.

## WAF Overrides Per Listener

Each app/listener may supply a `wafOverrides` object to selectively diverge from the **generated baseline**. Missing keys inherit generated defaults. Presence of `wafOverrides` or `wafExclusions` (and absence of explicit `wafPolicyId`) triggers creation of a per‑listener WAF policy.

If you already have an external WAF policy for a listener, set `wafPolicyId` and omit overrides / exclusions (no per‑listener policy generated).

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
* Use `wafOverrides` for inline listener-specific tuning; prefer `wafPolicyId` when an external, centrally managed policy already exists.
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
| Overrides + wafPolicyId both supplied | Overrides ignored | Remove overrides when using `wafPolicyId` |
| Supplying identity parameters | No effect | Remove identity params (auto-created) |
| enableDiagnostics without workspace ID | No diagnostics deployed | Provide workspace ID or disable diagnostics |
| backendHostHeader mismatch | 502/SSL errors | Match header to cert CN/SAN |

---
These clarifications are structural; operational runtime behaviors (monitoring, performance analysis) remain intentionally out of scope.

## Scope Clarification

Operational guidance (KQL queries, troubleshooting, health probe response strategies, runtime dashboards) is intentionally excluded. This document focuses on structural deployment integration within MLZ hub-spoke, routing mechanics, listener configuration surface, and composing parameter input for TLS/WAF enablement.

---
Active implementation; README constrained to integration & configuration scope. Report mismatches via issue with commit hash.
