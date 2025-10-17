# Application Gateway (Scenario A: WAF Before Firewall)

This add-on deploys a multi-site Azure Application Gateway (WAF_v2) into the Mission Landing Zone (MLZ) hub Virtual Network with **selective forced routing** through Azure Firewall. *Scenario A* places TLS termination and WAF inspection at the gateway prior to any firewall-controlled egress toward private backend workloads (hub-spoke integration pattern).

## Objectives

* Single WAF_v2 Application Gateway in hub VNet (subnet name default: `AppGateway`).
* TLS termination + centralized WAF policy (OWASP CRS) in Prevention (default) or Detection mode.
* **Selective forced routing**: only declared backend CIDR prefixes are routed via the Firewall (no blanket 0.0.0.0/0 to avoid asymmetric health probe paths).
* Scalable multi‑application (multi‑listener) model: add or remove apps by updating the `apps` array (idempotent redeploy).
* Inherited defaults via a `commonDefaults` object; every app can override any setting (probes, port, protocol, WAF tuning, status codes, host header, etc.).
* Optional per‑listener WAF policies generated automatically when `wafOverrides` or `wafExclusions` are supplied and no explicit `wafPolicyId` is provided.
* Host header override support (`backendHostHeader`) to preserve SNI / certificate matching when resolving private endpoints for public FQDNs.
* Key Vault sourced certificates (user‑assigned identity RBAC assignment can be auto‑created; no secrets stored in repo).
* Optional diagnostics integration (Log Analytics) — not required for functional deployment (operational usage intentionally out of scope here).
* Separation of concerns: subnet, NSG, route table, WAF policy resolution, per‑listener policy generation, and firewall egress rules are modularized for hub-spoke alignment.

## Traffic Flow

Internet -> Public IP (AppGW) -> TLS Termination + WAF -> (Selective UDR Next Hop: Firewall for declared backend prefixes) -> Backend (ILB / Private Endpoint / Internal FQDN)

## Parameter Model

At the top level `solution.bicep` exposes (primary subset):

| Parameter | Purpose |
|-----------|---------|
| `apps` | Array of listener/back‑end definitions (see structure below). |
| `commonDefaults` | Global baseline applied to each app unless overridden (ports, probe timing, acceptable status codes, autoscale, WAF generation defaults, etc.). |
| `existingWafPolicyId` | Attach an existing global WAF policy instead of generating a new one. |
| `userAssignedIdentityResourceId` | Identity granted Key Vault secret get (certificates). |
| `backendAllowPorts` | Baseline allowed egress ports from AppGW subnet to backends (used in firewall rule set). |
| `customAppGatewayFirewallRuleCollectionGroups` | Additional Firewall rule collection groups (merged with baseline). |
| `disablePrivateEndpointNetworkPolicies` | (Default true) Prevents Private Endpoints inside the AppGW subnet. |
| `enableDiagnostics` / `logAnalyticsWorkspaceResourceId` | Control diagnostics creation/association. |
| `createSubnetNsg` | Toggle creation of NSG specifically for AppGW subnet. |

### `apps` Element Structure

```jsonc
{
  "name": "app1",                                  // Listener + derived pool/probe name seed
  "hostNames": ["app1.contoso.gov"],               // One or more host headers -> multi-site listener
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
  "probeMatchStatusCodes": ["200"],                // Optional per-listener override (default often ["200-399"])
  "backendHostHeader": "mlz-ops-webapp1.azurewebsites.us", // Optional Host/SNI override
  "addressPrefixes": ["10.20.0.0/16"],             // Used for forced routes & firewall rules
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

## Modules

* `solution.bicep` – orchestration (naming inference, subnet creation, NSG/route table, WAF policy resolution, diagnostics, firewall rules, per‑listener object shaping, identity RBAC to Key Vault).
* `appgateway-core.bicep` – gateway resource, dynamic listeners, pools, probes, autoscale, generated per‑listener WAF policies.
* `appgateway-subnet.bicep` – authoritative subnet definition with optional NSG & route table association.
* `appgateway-route-table.bicep` – constructs forced routes referencing only declared backend CIDRs (no 0.0.0.0/0).
* `appgateway-diagnostics.bicep` – diagnostic settings binding to LA workspace.
* `modules/appgateway-firewall-rules.bicep` – firewall policy rule collection groups (baseline + custom additions).
* `modules/wafpolicy-resolver.bicep` – resolves existing or creates baseline WAF policy.
* `modules/kv-role-assignment.bicep` – optional Key Vault secrets RBAC assignment for user‑assigned identity.

## Scaling

Add or update apps by editing the `apps` array in a parameter file, then redeploy. Removal is destructive (listener/pool/probe + generated per‑listener WAF policy deleted).

## Security

* TLS 1.2+ enforced; HTTPS‑only listeners.
* WAF baseline in Prevention (override globally or per listener).
* Certificates pulled from Key Vault via user‑assigned identity (RBAC role optional toggle).
* NSG inbound restricted to 443 + AzureLoadBalancer + ephemeral probe ports; all other inbound denied.
* **No** default 0.0.0.0/0 forced route—only declared backend prefixes are routed via Firewall (prevents asymmetric probing failures).
* Host header override allows internal private resolution while preserving public FQDN SNI for backend cert validation.
* Outbound default Internet access disabled on subnet (controlled egress via Firewall).

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
* `healthProbePath`, `probeInterval`, `probeTimeout`, `unhealthyThreshold`, `probeMatchStatusCodes`: Optional fine-grained probe tuning (operational semantics of probe responses are out of scope; only structural description provided).
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
param userAssignedIdentityResourceId = '/subscriptions/<subId>/resourceGroups/<hubRg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<uaiName>'
param resourceAbbreviations = {  // Passed from MLZ core deployment conventions
  applicationGateway: 'agw'
  networkSecurityGroup: 'nsg'
  publicIpAddress: 'pip'
  firewallPolicy: 'fwp'
}
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
  // Per-listener generated WAF defaults inherit global unless overridden here:
  generatedPolicyMode: 'Prevention'
  generatedPolicyManagedRuleSetVersion: '3.2'
}
param apps = [
  {
    name: 'app1'
    hostNames: [ 'app1.example.gov' ]
    certificateSecretId: 'https://kv-example.vault.usgovcloudapi.net/secrets/app1cert/<version>'
    backendAddresses: [ { fqdn: 'app1-pe-appservice.azurewebsites.us' } ]
    backendHostHeader: 'app1.example.gov'      // Preserve public host for backend TLS validation
    healthProbePath: '/'
    addressPrefixes: [ '10.50.1.0/24' ]        // Spoke or private endpoint CIDR
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

// Optional: enable diagnostics (structure only; operational consumption not documented here)
param enableDiagnostics = true
param logAnalyticsWorkspaceResourceId = '/subscriptions/<subId>/resourceGroups/<opsRg>/providers/Microsoft.OperationalInsights/workspaces/<laWorkspace>'
```

Guidance:

* Include only CIDRs in `addressPrefixes` that must traverse Firewall from the gateway.
* Use `wafOverrides` for inline listener-specific tuning; prefer `wafPolicyId` when an external, centrally managed policy already exists.
* Provide consistent Key Vault secret versioned IDs for certificates; the module derives vault name for optional RBAC assignment.

### Step-by-Step Parameter File Construction

1. Core subscription-scope parameters: define `location`, `hubVnetResourceId`, `userAssignedIdentityResourceId`, and `resourceAbbreviations` to align naming with MLZ conventions.
2. Establish `commonDefaults`: decide your baseline backend protocol (`Https` for TLS inspection), port, probe timings, autoscale caps, and (optionally) generated per-listener WAF defaults.
3. Define each app in `apps`: supply a unique `name` (alphanumeric + simple delimiters), its `hostNames`, certificate secret, and backend addresses. Add only necessary overrides—omit fields to inherit `commonDefaults`.
4. Add `addressPrefixes` per app: include ONLY the CIDRs that represent backend network segments requiring Firewall egress (spoke subnet ranges, private endpoint subnet ranges). Avoid overlapping broad CIDRs that subsume smaller ones unless you intend to route all of them.
5. Decide WAF strategy per listener: use `wafOverrides` (inline tuning) OR `wafPolicyId` (external managed policy). Do not combine—external policy takes precedence; omit overrides when specifying `wafPolicyId`.
6. (Optional) Include diagnostics parameters if you need LA workspace integration structurally (this README intentionally excludes consumption guidance).

### Complexity Clarifications

| Aspect | Why It Exists | Key Rule | Pitfalls |
|--------|---------------|----------|----------|
| `hostNames` vs `backendAddresses` | Separate concern: request matching vs target endpoints | Hostnames drive listener creation; backendAddresses populate pool | Duplicating hostnames across two apps causes deployment validation conflicts |
| FQDN vs IP backend entries | Support dynamic (DNS-resolved) vs static targets | Choose one object type per entry | Adding both forms for same server doubles probes & can confuse health states |
| `backendHostHeader` | Preserve expected Host/SNI for backend cert or virtual host routing | Set to public hostname if backend expects public cert; set to internal FQDN if backend cert only internal | Omitting when backend cert CN differs from public host causes TLS/SNI failures |
| `addressPrefixes` | Build selective UDR + firewall egress rules (least privilege) | Only list prefixes that must route via Firewall | Overly broad (e.g. entire hub address space) defeats selective routing and increases risk |
| Per-listener WAF generation | Allow granular tuning without managing many external policies | Provide `wafOverrides` or `wafExclusions` and leave `wafPolicyId` empty | Supplying empty `wafOverrides` object still triggers policy generation—omit entirely if not needed |
| Global vs listener WAF precedence | Avoid ambiguity between baseline and overrides | Listener-level policy (generated or external) applies only to that listener; global policy covers the rest | Mixing partial overrides via both can create inconsistent rule coverage assumptions |
| Certificate coverage | One cert per listener covering all hostNames | Ensure SAN/wildcard covers each entry | Mismatch results in TLS errors for unmatched hostnames |
| Probe status codes array | Structural allowance for non-200 codes without editing module | Use narrow codes (e.g. ["200"]) once backend stable | Broad ranges can mask failing deployments (e.g. 302 redirect loops) |
| Autoscale vs subnet size | Preserve capacity headroom | Size subnet (/26 or larger) for scale target; defaults tuned conservatively | Using a /28 may block future scale increases |
| Key Vault secret ID parsing | Derive vault name for RBAC assignment automatically | Provide full secret URI including version | Using secret without version may complicate rotation alignment |

### Designing the `apps` Array

Keep each `apps` element focused on a single logical application boundary that shares identical request processing and backend behavior. Use separate entries when:

* Backends have different health probe paths or protocols.
* TLS certificates differ (distinct host coverage).
* WAF posture diverges significantly (different exclusions or rule overrides).

Do NOT split the same logical app merely to add more backend addresses—add them to the `backendAddresses` array of the existing app.

### Decision Matrix: FQDN vs IP

Choose FQDN when backend is:
Choose FQDN when backend is:

* App Service (private endpoint) or other PaaS with mutable IP.
* Internal Load Balancer where pool membership may change.
* Service relying on internal DNS-based failover.

Choose IP when backend is:
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
Invalid (both forms for same host intentionally duplicated):

```jsonc
"backendAddresses": [
  { "fqdn": "app1-pe.azurewebsites.us" },
  { "fqdn": "app1-pe.azurewebsites.us" }
]
```

### Listener Naming and Uniqueness

`name` seeds listener, probe, and backend pool names. Keep under typical Azure name length limits (< 80 chars) and avoid uppercase for consistency. Two apps cannot share the same `name` even if hostnames differ.

### WAF Override Minimal Example

If you only need to disable a single rule:

```jsonc
"wafOverrides": {
  "mode": "Prevention",
  "managedRuleSetVersion": "3.2",
  "ruleGroupOverrides": [ { "ruleGroupName": "REQUEST-942-APPLICATION-ATTACK-SQLI", "rules": [ { "ruleId": "942100", "state": "Disabled" } ] } ]
}
```

Exclude unused keys; they inherit from generated defaults or global policy baseline.

### Common Pitfalls & Remedies

| Pitfall | Symptom | Structural Fix |
|---------|---------|----------------|
| Duplicate hostNames across two apps | Deployment validation error | Consolidate into one app or adjust hostnames |
| Missing certificate coverage for all hostNames | TLS handshake failures on unmatched SAN | Reissue cert including all hostNames or split apps |
| Overly broad addressPrefixes (e.g. 10.0.0.0/8) | Unintended routing of unrelated spokes | Replace with granular spoke / subnet CIDRs |
| Mixed WAF overrides + external wafPolicyId | Override silently ignored | Remove overrides when using `wafPolicyId` |
| Using IP for dynamic PaaS | Intermittent backend probe failures after platform scaling | Switch to FQDN target |
| Supplying backendHostHeader that doesn't match backend cert | 502/SSL errors (structural mismatch) | Set host header to certificate CN/SAN value |

---
These clarifications are structural; operational runtime behaviors (monitoring, probing diagnostics, performance analysis) remain intentionally out of scope.

## Scope Clarification

Operational guidance (KQL queries, troubleshooting, health probe response strategies, runtime dashboards) is intentionally excluded. This document focuses solely on structural deployment integration within MLZ hub-spoke, routing mechanics, listener configuration surface, and composing parameter input for TLS/WAF enablement.

---
Active implementation; README constrained to integration & configuration scope.
