# Application Gateway Add-On – Advanced & Operational Reference

> This file contains deep-dive / operational / tuning guidance intentionally excluded from the primary README (which is limited to IaC contract and invariants).
>
> Nothing here is required to deploy. Use only when performing WAF tuning, troubleshooting, or post-deployment analysis.

## 1. Extended WAF Policy Mechanics

### Resolution Order Per Listener

1. Explicit `wafPolicyId` on app object → listener uses that policy; ignores overrides & exclusions.
2. Else if `wafOverrides` or `wafExclusions` present → synthesized per-listener policy (merges exclusions & overrides).
3. Else → listener inherits global policy (created or adopted via `existingWafPolicyId`).

`perListenerWafPolicyIds` output enumerates the effective policy per listener (blank string indicates inheritance).

### Inline Overrides vs Exclusions

| Aspect | `wafOverrides` | `wafExclusions` |
|--------|----------------|-----------------|
| Purpose | Change policy knobs / rule states | Remove specific variables from rule evaluation |
| Typical Use | Disable individual rule IDs or adjust mode/body limits | Suppress false positive for a specific header/arg/cookie/JSON field |
| Generates per-listener policy? | Yes (if no explicit ID) | Yes (if no explicit ID) |
| Precision | Medium (rule or group scope) | High (single variable/pattern) |

### Practical Guidance

* Prefer an exclusion for a single noisy variable instead of disabling entire rule groups.
* Avoid broad pattern operators (`StartsWith` / `Contains`) unless well justified.
* Keep overrides minimal—only set fields you truly diverge on.

### Government Cloud Note

Some exclusion `matchVariable` enum values may lag. To validate:

1. Create a temporary WAF policy via CLI.
2. Add the candidate exclusion.
3. If deployment succeeds, include it; otherwise choose a supported variable.

## 2. Per-Listener Policy Generation Examples

Minimal override:

```jsonc
"wafOverrides": {
  "mode": "Detection",
  "ruleGroupOverrides": [
    { "ruleGroupName": "REQUEST-942-APPLICATION-ATTACK-SQLI", "rules": [ { "ruleId": "942100", "state": "Disabled" } ] }
  ]
}
```

Suppression of a single header:

```jsonc
"wafExclusions": [
  { "matchVariable": "RequestHeaderNames", "selectorMatchOperator": "Equals", "selector": "X-Trace-Token" }
]
```

Combination (synthesized policy):

```jsonc
"wafOverrides": { "mode": "Prevention" },
"wafExclusions": [
  { "matchVariable": "RequestArgNames", "selectorMatchOperator": "Equals", "selector": "csrfToken" }
]
```

Explicit external policy (overrides ignored):

```jsonc
"wafPolicyId": "/subscriptions/.../ApplicationGatewayWebApplicationFirewallPolicies/external-pci-policy"
```

## 3. Post-Deployment Verification Checklist

| Check | Expectation |
|-------|-------------|
| Public IP | Static & reachable (optional DNS resolves). |
| `listenerNames` | Matches count of `apps` defined. |
| `perListenerWafPolicyIds` | Blank only where no overrides/exclusions/explicit ID. |
| `forcedRouteEntries` | Contains only declared backend CIDRs; no default route. |
| Subnet | NSG + route table associated; outbound Internet disabled flag set. |
| Health probes | All show healthy after certificate/SNI alignment. |
| Firewall policy | Baseline collection + custom groups (if provided). |

## 4. Routine Structural Changes

| Action | Effect |
|--------|-------|
| Add app object | New listener/pool/probe; optionally new per-listener policy. |
| Remove app object | Associated listener/pool/probe and synthesized policy deleted. |
| Add CIDR to `addressPrefixes` | New forced route + potential firewall rule expansion. |
| Remove CIDR | Removes route and adjusts firewall rules (dedup still applied). |
| Change `wafOverrides` | Recreates per-listener policy with new settings. |
| Switch to explicit policy | Per-listener synthesized policy no longer generated. |
| Enable diagnostics | Diagnostic setting created; output populated. |
| Disable diagnostics | Setting removed; output blank. |

## 5. Detailed Listener Configuration Notes

* `hostNames`: Multi-site host matching; each app maps to one multi-site HTTPS listener.
* `backendAddresses`: Use FQDN for dynamic PaaS endpoints; IP for static infrastructure.
* `backendHostHeader`: Set when backend TLS cert expects a different host than public DNS.
* Health probes: Path + timing; narrow status codes after baseline stability.
* Autoscale: Subnet default /26 sized for growth; do not shrink below vendor guidance.

### Valid vs Invalid Backend Sets

Valid mixed:

```jsonc
"backendAddresses": [ { "fqdn": "app1-pe.azurewebsites.us" }, { "ipAddress": "10.20.10.5" } ]
```

Invalid duplicate:

```jsonc
"backendAddresses": [ { "fqdn": "app1-pe.azurewebsites.us" }, { "fqdn": "app1-pe.azurewebsites.us" } ]
```

## 6. Complexity Clarifications (Extended)
| Aspect | Why It Exists | Key Rule | Pitfall |
|--------|---------------|----------|---------|
| host vs backend separation | Listener matching vs pool membership | Hostnames drive routing; addresses build pool | Duplicate hostnames across apps conflict |
| FQDN vs IP entries | Support dynamic PaaS vs static infra | Choose per endpoint stability | Mixing both for same endpoint redundant |
| Selective routing | Prevent broad unintended egress | Only declare necessary CIDRs | Overly broad /8 weakens least privilege |
| Per-listener WAF generation | Localized tuning | Provide overrides/exclusions OR explicit policy ID | Empty overrides still create a policy |
| Global vs listener precedence | Clear hierarchy | Explicit > synthesized > global | Assuming global changes affect explicit listener |
| Body size limits | Inspect payload safely | Increase only as needed | Oversizing invites performance impact |
| Managed rule versioning | Keep up with CRS updates | Pin version consciously | Blind upgrades may re-enable disabled rules |

## 7. Decision Matrix: FQDN vs IP
| Backend Type | Recommended Form |
|--------------|------------------|
| App Service (PE) | FQDN |
| Dynamic ILB fronting variable VMs | FQDN |
| Static appliance | IP |
| Fixed VM NIC | IP |
| DNS-based failover solution | FQDN |

## 8. WAF Override Minimal Patterns
Disable a single rule:
```jsonc
"wafOverrides": {
  "ruleGroupOverrides": [ { "ruleGroupName": "REQUEST-941-APPLICATION-ATTACK-XSS", "rules": [ { "ruleId": "941130", "state": "Disabled" } ] } ]
}
```

Add a custom block rule:
```jsonc
"wafOverrides": {
  "customRules": [
    {
      "name": "BlockBadUA",
      "priority": 100,
      "action": "Block",
      "matchConditions": [
        {
          "matchVariables": [{ "variableName": "RequestHeaders", "selector": "User-Agent" }],
          "operator": "Contains",
          "matchValues": [ "sqlmap" ]
        }
      ]
    }
  ]
}
```

## 9. Common Pitfalls & Remedies
| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Overrides + explicit policy provided | Overrides ignored | Remove `wafPolicyId` or drop overrides |
| Disabling entire rule group for single FP | Reduced coverage | Use exclusion or rule ID disable |
| Broad exclusion pattern | Hidden attacks | Narrow to exact variable name |
| Large body size unnecessarily | Performance overhead | Keep near required minimum |
| Missing certificate SAN | TLS probe failures | Reissue cert or split listener |
| Outdated exclusion enum (Gov) | Deployment error | Validate with test policy first |

## 10. Forced Route Entries Output
`forcedRouteEntries` lists each unique backend CIDR producing a UDR entry (next hop = Firewall private IP). No sentinel default route is ever created.

## 11. Subnet Private Endpoint Network Policy Toggle
Parameter: `disablePrivateEndpointNetworkPolicies` (default `true`). Disables PE network policies for the gateway subnet to avoid accidental endpoint placement conflict.

## 12. Listener Configuration Surface (Full)
Each app defines: multi-site HTTPS listener, backend pool, health probe, optional synthesized WAF policy.

## 13. Scaling & Removal Behavior
* Adding an app: new listener/pool/probe + optional policy.
* Removing an app: associated resources removed cleanly; unrelated listeners untouched.
* Increasing autoscale max: ensure subnet has remaining IP space; /26 default sized for small scale.

## 14. Security Rationale (Extended)
* No default 0.0.0.0/0 UDR → prevents unintended asymmetric probe paths.
* Hardened NSG baseline restricts inbound surface (443 + platform required ranges).
* Outbound Internet disabled at subnet; egress forced only through declared CIDRs via Firewall.
* Key Vault versioned secrets prevent silent cert mutation.
* Per-listener policy synthesis isolates tuning changes—global baseline remains stable.

## 15. Troubleshooting Quick Table
| Symptom | Cause | Action |
|---------|-------|--------|
| Persistent 502 | Host header mismatch | Set `backendHostHeader` to expected value |
| False positives on token | High entropy field | Add targeted exclusion |
| Overrides not applied | `wafPolicyId` also set | Remove explicit ID |
| Unwanted broad egress | CIDR too wide | Narrow `addressPrefixes` |
| Missing diagnostics | Flag/workspace mismatch | Provide both or disable flag |

## 16. Governance Considerations
* Store parameter files in source control; review diffs for policy changes (rule disables, exclusions additions).
* External security teams can manage a central global policy consumed via `existingWafPolicyId` while still allowing per-listener synthesis for app teams.

## 17. Versioning & Upgrades
* Track managed rule set version changes in parameter diff reviews.
* Revalidate exclusions after version bump—false positive landscape may change.

## 18. Appendix: Sample Full App Object
```jsonc
{
  "name": "api",
  "hostNames": ["api.example.gov"],
  "certificateSecretId": "https://kv-example.vault.usgovcloudapi.net/secrets/api-cert/<version>",
  "backendAddresses": [ { "ipAddress": "10.70.5.10" } ],
  "addressPrefixes": ["10.70.5.0/24"],
  "backendHostHeader": "api.example.gov",
  "healthProbePath": "/health",
  "wafOverrides": {
    "mode": "Detection",
    "ruleGroupOverrides": [ { "ruleGroupName": "REQUEST-942-APPLICATION-ATTACK-SQLI", "rules": [ { "ruleId": "942100", "state": "Disabled" } ] } ]
  },
  "wafExclusions": [ { "matchVariable": "RequestArgNames", "selectorMatchOperator": "Equals", "selector": "csrfToken" } ]
}
```

---
Use ADVANCED.md only for operational or tuning tasks; keep README authoritative for contract.

  ## 19. Certificate Rotation

  Rotate TLS certificates by publishing a **new version** of the existing Key Vault secret and then updating the parameter file to reference that version. Do not replace certificate material inline or upload manually to the gateway—keep rotation declarative.

  ### 19.1 Workflow (Versioned Secret Pattern)

  1. Prepare new PFX (include full chain if required by clients).
  2. Import PFX into the same Key Vault secret name (e.g., `web1cert`) creating a new version.
  3. Update your parameter file `certificateSecretId` from:

  ```text
  https://kv-example.vault.usgovcloudapi.net/secrets/web1cert/<oldVersionGuid>
  ```

    to:

  ```text
  https://kv-example.vault.usgovcloudapi.net/secrets/web1cert/<newVersionGuid>
  ```

  4. Redeploy the add-on template.
  5. Validate: perform an HTTPS request and inspect presented certificate (CN/SAN + NotBefore/NotAfter).
  6. Keep prior version until validation complete; delete only after successful rollout.

  ### 19.2 Rollback

  If validation fails (wrong SAN, chain issue):

  1. Revert parameter file back to old version GUID.
  2. Redeploy.
  3. Confirm old cert is again presented.

  ### 19.3 Why Use Versioned URIs

  | Benefit | Explanation |
  |---------|-------------|
  | Deterministic deployment | The exact cert is locked by version GUID. |
  | Auditable changes | Git diff shows when a certificate changed. |
  | Safe rollback | Previous version still addressable. |
  | Avoid silent drift | Unversioned URIs could swap cert without a template change. |

  ### 19.4 Common Pitfalls

  | Pitfall | Symptom | Fix |
  |---------|---------|-----|
  | Import CER without private key | Deployment fails / listener error | Use PFX containing private key |
  | Delete old version too early | No rollback path | Retain old version until tests pass |
  | Forget to update parameter file | Old cert persists | Bump `certificateSecretId` version explicitly |
  | Use unversioned secret URI | Invisible rotation | Always include version GUID |
  | Chain incomplete | Clients show trust errors | Include full intermediate chain in PFX |

  ### 19.5 Automation Hooks

  If automating issuance (e.g., internal CA or ACME):

  * Have issuance pipeline publish new secret version.
  * Trigger a parameter file update (commit with version GUID) + deployment workflow.
  * Add a post-deploy validation job (HTTPS fetch + parse cert details) before marking rotation successful.

  ### 19.6 Validation Tips

  Minimal PowerShell (optional, not part of template logic):

  ```powershell
  # Fetch certificate served
  $cert = (Invoke-WebRequest https://web1.example.gov -UseBasicParsing).RawContentLength; # placeholder to show request; parse with OpenSSL or browser
  ```

  Prefer dedicated tooling (browser, `openssl s_client`, or platform-specific scripts) for real validation.

  ### 19.7 Key Vault Access Considerations

  The template now assigns the Secrets read permission ("Secrets User" RBAC role) automatically when it can infer the Key Vault from a certificate secret URI. Certificate object permissions alone are insufficient—secret access is required. If the vault cannot be inferred (no apps defined yet), assign manually after initial deploy and redeploy once certificates are in place.

  ### 19.8 Rotation Frequency Guidance

  | Rotation Interval | Rationale |
  |-------------------|-----------|
  | 90 days | Common hygiene (aligns with many org policies) |
  | 180 days | Acceptable for internal-only endpoints with strong monitoring |
  | < 30 days | Usually unnecessary overhead unless mandated |

  Document chosen interval in your ops runbook; template itself remains static between rotations except for the version GUID change.

  ---
