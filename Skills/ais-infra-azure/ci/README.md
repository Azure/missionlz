# CI Pipeline Snippets

Ready-to-use GitHub Actions workflow snippets for infrastructure validation.

> **Path filtering**: Use `on.pull_request.paths` at the workflow level to
> trigger only when `infra/` files change. Job-level `if:` conditions cannot
> filter on file paths — `github.event.pull_request.changed_files` is a count,
> not a file list. Example workflow trigger:
>
> ```yaml
> on:
>   pull_request:
>     paths:
>       - 'infra/**'
> ```

## Bicep

```yaml
  infra-validate-bicep:
    name: Bicep Lint & Validate
    runs-on: ubuntu-latest
    # ubuntu-latest includes az CLI with Bicep built-in — no separate setup step needed
    steps:
      - uses: actions/checkout@v4
      - name: Lint all Bicep files
        run: |
          find infra/ -name "*.bicep" | while read f; do
            az bicep lint --file "$f"
          done
      - name: Validate AVM usage
        run: python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --lang bicep
      - name: What-if
        run: |
          az deployment group what-if \
            --resource-group ${{ vars.RESOURCE_GROUP }} \
            --template-file infra/main.bicep \
            --parameters infra/environments/${{ vars.ENVIRONMENT }}.bicepparam
```

## Terraform

```yaml
  infra-validate-terraform:
    name: Terraform Lint & Validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6"
      - uses: terraform-linters/setup-tflint@v4
      - name: Terraform Init
        working-directory: infra
        run: terraform init -backend=false
      - name: Terraform Validate
        working-directory: infra
        run: terraform validate
      - name: TFLint
        working-directory: infra
        run: |
          tflint --init
          tflint --recursive
      - name: Validate AVM usage
        run: python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --lang terraform
      - name: Plan
        working-directory: infra
        run: terraform plan -var-file=environments/${{ vars.ENVIRONMENT }}.tfvars -out=tfplan
```

## Validation Script (optional local helper)

The validation script is a convenience tool for quick local checks before
committing. It is **not a required CI gate** — `az bicep lint`, `tflint`,
and Azure Policy provide stronger enforcement automatically.

Run it locally:

```bash
python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/
```

What it checks (best-effort, not exhaustive):
- AVM module version pins
- Non-AVM modules without an ADR
- Obvious hardcoded secrets
- Required tag keys (where not using a variable reference)
- Committed `.tfstate` files (Terraform)
- Missing remote backend (Terraform)

## Azure Policy Compliance

```yaml
  policy-compliance:
    name: Azure Policy Check
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - name: Check policy compliance
        run: |
          az policy state summarize \
            --resource-group ${{ vars.RESOURCE_GROUP }} \
            --filter "complianceState eq 'NonCompliant'" \
            --output table
```

## Notes

- Replace `${{ vars.RESOURCE_GROUP }}` and `${{ vars.ENVIRONMENT }}` with
  your repository variables
- Trigger jobs by scoping the workflow with `on.pull_request.paths: ['infra/**']`
- For monorepos, scope paths more narrowly (e.g., `services/myapp/infra/**`)
- See `../standards/deployment.md` for full deployment pipeline requirements

### Azure Policy Compliance

```yaml
  policy-compliance:
    name: Azure Policy Check
    runs-on: ubuntu-latest
    needs: [infra-validate-bicep]  # or infra-validate-terraform
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - name: Check policy compliance
        run: |
          az policy state summarize \
            --resource-group ${{ vars.RESOURCE_GROUP }} \
            --filter "complianceState eq 'NonCompliant'" \
            --output table
```

### Notes

- Replace `${{ vars.RESOURCE_GROUP }}` and `${{ vars.ENVIRONMENT }}` with
  your repository variables
- The `if` condition uses `changed_files` — adjust for your workflow trigger
- For monorepos, scope paths more narrowly (e.g., `services/myapp/infra/`)
- See `../standards/deployment.md` for full deployment pipeline requirements
