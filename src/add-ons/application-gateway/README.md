# Application Gateway (Scenario A: WAF Before Firewall)

This add-on deploys an Azure Application Gateway (WAF_v2) in the Mission Landing Zone (MLZ) Hub Virtual Network with forced routing via Azure Firewall. Scenario A means public inbound HTTP/S is terminated at the Application Gateway (TLS + WAF) before traversing the hub firewall for inspection en route to internal backend workloads.

## Objectives

* Single WAF_v2 Application Gateway in hub VNet `AppGateway` subnet
* TLS termination and WAF (OWASP CRS) in Prevention mode (configurable)
* Forced tunneling via Azure Firewall using UDR on AppGateway subnet
* Scalable multi-application model: add apps by extending `apps` array (idempotent)
* Inherited defaults via `commonDefaults` object; each app overrides independently
* No Front Door integration; Scenario A only
* Key Vault sourced certificates (no secrets in repo)
* Diagnostics to existing Log Analytics workspace

## Traffic Flow

Internet -> Public IP (AppGW) -> TLS Termination + WAF -> UDR Next Hop: Firewall -> Backend (ILB / private endpoints)

## Parameter Model

* `commonDefaults`: baseline settings (backendPort, protocol, probe settings, autoscale, WAF mode, certificate secret id, etc.)
* `apps`: array of application definitions (listener hostnames, backend targets, optional overrides)

Example `apps` element:

```jsonc
{
  "name": "app1",
  "hostNames": ["app1.contoso.gov"],
  "backendTargets": [
    { "type": "fqdn", "value": "app1-ilb.internal.contoso.gov" }
  ],
  "certificateSecretId": "<keyvault-secret-id>",
  "healthProbePath": "/health",
  "customWafRules": [ /* optional (future) */ ],
  "wafPolicyId": "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/app1-specific-policy" // optional override; inherit baseline if omitted
}
```

## Modules

* `solution.bicep`: Orchestrates subnet (with delegation), NSG, route table, WAF policy resolver, AppGW, diagnostics, Key Vault RBAC
* `appgateway-core.bicep`: App Gateway resource (listeners, pools, probes, rules)
* `appgateway-waf-policy.bicep`: Base WAF policy + aggregated custom rules
* `appgateway-subnet.bicep`: Ensure AppGateway subnet & NSG
* `appgateway-route-table.bicep`: UDR forcing next hop to Firewall
* `appgateway-diagnostics.bicep`: Diagnostic settings

Reuses existing `firewall-info.bicep`, `vnet-info.bicep` modules.

## Scaling

Add new app by appending to `apps` array in external `.bicepparam` file and redeploy. Removal deletes resources; document destructive action.

## Security

* TLS 1.2+ enforced; HTTPS only
* WAF in Prevention (override to Detection for tuning)
* Certificates from Key Vault (managed identity access recommended)
* NSG restricts inbound to 443 + required ephemeral infrastructure ports (65200-65535) and AzureLoadBalancer service tag; denies all other inbound
* Network isolation feature `EnableApplicationGatewayNetworkIsolation` must be registered (once per subscription) to allow a 0.0.0.0/0 UDR in the delegated subnet
* Subnet is automatically delegated to `Microsoft.Network/applicationGateways` as part of deployment (required for isolation scenario)

## Logging & Monitoring

Logs: Access, Performance, Firewall -> Log Analytics (diagnostic setting named `diag-<appgw>`). AllMetrics enabled. Provide Kusto samples in future iteration.

## WAF Overrides Per Listener

Each app/listener may supply a `wafOverrides` object to selectively diverge from the baseline gateway WAF policy. Any property omitted inherits the baseline value.

Supported keys:

```jsonc
"wafOverrides": {
  "mode": "Detection",                 // or Prevention
  "requestBodyCheck": true,
  "maxRequestBodySizeInKb": 256,
  "fileUploadLimitInMb": 150,
  "managedRuleSetVersion": "3.2",
  "exclusions": [                       // merged with app-level wafExclusions if present
    { "matchVariable": "RequestHeaderNames", "selectorMatchOperator": "Equals", "selector": "x-ignore" }
  ],
  "ruleGroupOverrides": [               // Advanced pass-through; full schema required
    {
      "ruleGroupName": "REQUEST-930-APPLICATION-ATTACK-LFI",
      "rules": [ { "ruleId": "930100", "state": "Disabled" } ]
    }
  ]
}
```

If you already have a full external WAF policy for a listener, set `wafPolicyId` on the app and omit overrides.


> NOTE: Azure Government WAF_v2 currently supports a single IPv4 public frontend for this scenario. Multi-frontend (multiple IPv4 public IPs) capability was removed from the template; use host-based (multi-site) listeners instead for segmentation.

## Forced Route Entries Output

`forcedRouteEntries` output surfaces each unique internal CIDR (prefix) forced through the Firewall. One route per unique CIDR is created in the dedicated route table.

## Subnet Private Endpoint Policy Toggle

Parameter: `disablePrivateEndpointNetworkPolicies` (default `true`). When true, private endpoint network policies are Disabled on the AppGateway subnet preventing accidental Private Endpoint placement there.

## Example App Definition With Overrides

```jsonc
{
  "name": "app1",
  "hostNames": ["app1.contoso.mil"],
  "backendAddresses": [ { "ipAddress": "10.20.10.4" }, { "ipAddress": "10.20.10.5" } ],
  "certificateSecretId": "https://mykv.vault.usgovcloudapi.net/secrets/app1cert/<version>",
  "addressPrefixes": ["10.20.0.0/16"],
  "wafOverrides": {
    "mode": "Detection",
    "maxRequestBodySizeInKb": 256,
    "exclusions": [ { "matchVariable": "RequestHeaderNames", "selectorMatchOperator": "Equals", "selector": "x-bypass" } ],
    "ruleGroupOverrides": [ { "ruleGroupName": "REQUEST-930-APPLICATION-ATTACK-LFI", "rules": [ { "ruleId": "930100", "state": "Disabled" } ] } ]
  }
}
```

## Out of Scope

* Scenario B (after firewall)
* Azure Front Door
* Private-only frontends

## Next Steps

1. Register network isolation feature (one-time): `az feature register --namespace Microsoft.Network --name EnableApplicationGatewayNetworkIsolation` then (after state=Registered) `az provider register -n Microsoft.Network`
2. Populate parameter file with `commonDefaults` and initial `apps`
3. (Optional) Provide `logAnalyticsWorkspaceResourceId` and set `enableDiagnostics=true`
4. Run what-if: `az deployment sub what-if ...`
5. Deploy after review
6. Extend `apps` as needs grow; priorities auto-assign (100 + 10*n)

## SCCA Mapping (Initial)

* Boundary Protection: Firewall + UDR + NSG
* Web Application Protection: WAF policy
* Audit & Accountability: Centralized diagnostics
* Encryption: TLS termination + optional backend HTTPS

---
Initial scaffolding; will evolve with implementation.
