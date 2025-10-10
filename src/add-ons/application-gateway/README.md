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
  "customWafRules": [ /* optional */ ]
}
```

## Modules

* `solution.bicep`: Orchestrates subnet, NSG, route table, WAF policy, AppGW, diagnostics
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
* NSG restricts inbound to 80/443 + necessary service tags

## Logging & Monitoring

Logs: Access, Performance, Firewall -> Log Analytics. Provide Kusto samples in future iteration.

## Out of Scope

* Scenario B (after firewall)
* Azure Front Door
* Private-only frontends

## Next Steps

1. Populate parameter file with `commonDefaults` and initial `apps`
2. Run `az deployment sub what-if` using the `.bicepparam` file
3. Deploy after review
4. Extend `apps` as needs grow

## SCCA Mapping (Initial)

* Boundary Protection: Firewall + UDR + NSG
* Web Application Protection: WAF policy
* Audit & Accountability: Centralized diagnostics
* Encryption: TLS termination + optional backend HTTPS

---
Initial scaffolding; will evolve with implementation.
