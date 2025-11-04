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




## 4. WAF Override Minimal Patterns
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

## 5. Common Pitfalls & Remedies
| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Overrides + explicit policy provided | Overrides ignored | Remove `wafPolicyId` or drop overrides |
| Disabling entire rule group for single FP | Reduced coverage | Use exclusion or rule ID disable |
| Broad exclusion pattern | Hidden attacks | Narrow to exact variable name |
| Large body size unnecessarily | Performance overhead | Keep near required minimum |
| Missing certificate SAN | TLS probe failures | Reissue cert or split listener |
| Outdated exclusion enum (Gov) | Deployment error | Validate with test policy first |


## 7. Governance Considerations
* Store parameter files in source control; review diffs for policy changes (rule disables, exclusions additions).
* External security teams can manage a central global policy consumed via `existingWafPolicyId` while still allowing per-listener synthesis for app teams.

## 8. Versioning & Upgrades
* Track managed rule set version changes in parameter diff reviews.
* Revalidate exclusions after version bump—false positive landscape may change.

## 9. Appendix: Sample Full App Object
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

  ## 10. Certificate Rotation

  Rotate TLS certificates by publishing a **new version** of the existing Key Vault secret and then updating the parameter file to reference that version. Do not replace certificate material inline or upload manually to the gateway—keep rotation declarative.

  ### 10.1 Workflow (Versioned Secret Pattern)

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

  ### 10.2 Rollback

  If validation fails (wrong SAN, chain issue):

  1. Revert parameter file back to old version GUID.
  2. Redeploy.
  3. Confirm old cert is again presented.

  ### 10.3 Why Use Versioned URIs

  | Benefit | Explanation |
  |---------|-------------|
  | Deterministic deployment | The exact cert is locked by version GUID. |
  | Auditable changes | Git diff shows when a certificate changed. |
  | Safe rollback | Previous version still addressable. |
  | Avoid silent drift | Unversioned URIs could swap cert without a template change. |

  ### 10.4 Common Pitfalls

  | Pitfall | Symptom | Fix |
  |---------|---------|-----|
  | Import CER without private key | Deployment fails / listener error | Use PFX containing private key |
  | Delete old version too early | No rollback path | Retain old version until tests pass |
  | Forget to update parameter file | Old cert persists | Bump `certificateSecretId` version explicitly |
  | Use unversioned secret URI | Invisible rotation | Always include version GUID |
  | Chain incomplete | Clients show trust errors | Include full intermediate chain in PFX |

  ### 10.5 Automation Hooks

  If automating issuance (e.g., internal CA or ACME):

  * Have issuance pipeline publish new secret version.
  * Trigger a parameter file update (commit with version GUID) + deployment workflow.
  * Add a post-deploy validation job (HTTPS fetch + parse cert details) before marking rotation successful.

  ### 10.6 Validation Tips

  Minimal PowerShell (optional, not part of template logic):

  ```powershell
  # Fetch certificate served
  $cert = (Invoke-WebRequest https://web1.example.gov -UseBasicParsing).RawContentLength; # placeholder to show request; parse with OpenSSL or browser
  ```

  Prefer dedicated tooling (browser, `openssl s_client`, or platform-specific scripts) for real validation.

  ### 10.7 Key Vault Access Considerations

  The template now assigns the Secrets read permission ("Secrets User" RBAC role) automatically when it can infer the Key Vault from a certificate secret URI. Certificate object permissions alone are insufficient—secret access is required. If the vault cannot be inferred (no apps defined yet), assign manually after initial deploy and redeploy once certificates are in place.

  <!-- Rotation frequency guidance removed (project does not prescribe operational intervals). -->

  ---
