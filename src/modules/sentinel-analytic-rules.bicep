targetScope = 'resourceGroup'

@description('Name of the Log Analytics workspace where Microsoft Sentinel is enabled.')
param workspaceName string

@description('Azure region used for deployment scripts.')
param location string

@description('Toggle to deploy Content Hub analytic rules as active scheduled rules.')
param deployAnalyticRules bool = true

@description('URL to the analytic rules manifest JSON file.')
param analyticRulesManifestUrl string = 'https://raw.githubusercontent.com/sedmonds22/sedmonds-azsecurity-templates/main/content/analytic-rules-manifest.json'

// Reference existing workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspaceName
}

// Managed identity for the deployment script
resource analyticRulesIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (deployAnalyticRules) {
  name: 'id-analytic-rules-${uniqueString(resourceGroup().id)}'
  location: location
}

// Role assignment: Microsoft Sentinel Contributor on workspace
resource analyticRulesSentinelRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployAnalyticRules) {
  name: guid(workspace.id, analyticRulesIdentity.id, 'ab8e14d6-4a74-4a29-9ba8-549422addade')
  scope: workspace
  properties: {
    principalId: analyticRulesIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ab8e14d6-4a74-4a29-9ba8-549422addade') // Microsoft Sentinel Contributor
    principalType: 'ServicePrincipal'
  }
}

// Deployment script to deploy Content Hub analytic rules as active scheduled rules
resource analyticRulesScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (deployAnalyticRules) {
  name: 'deploy-analytic-rules-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${analyticRulesIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
    environmentVariables: [
      {
        name: 'WORKSPACE_NAME'
        value: workspaceName
      }
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'SUBSCRIPTION_ID'
        value: subscription().subscriptionId
      }
      {
        name: 'MANIFEST_URL'
        value: analyticRulesManifestUrl
      }
    ]
    scriptContent: '''
      set -uo pipefail

      workspaceName="$WORKSPACE_NAME"
      resourceGroup="$RESOURCE_GROUP"
      subscriptionId="$SUBSCRIPTION_ID"
      manifestUrl="$MANIFEST_URL"
      apiVersion="2024-01-01-preview"

      echo "INFO: Fetching analytic rules manifest from $manifestUrl"
      manifest=$(wget -qO- "$manifestUrl") || {
        echo "ERROR: Failed to fetch manifest from $manifestUrl" >&2
        exit 1
      }

      ruleCount=$(echo "$manifest" | jq -r '.ruleCount // 0')
      echo "INFO: Found $ruleCount rules to deploy"

      # Use temp files for counters (bash subshell issue with pipes)
      echo "0" > /tmp/success_count
      echo "0" > /tmp/skip_count
      echo "0" > /tmp/error_count

      # Write rules to temp file to avoid subshell issue
      echo "$manifest" | jq -c '.rules[]' > /tmp/rules.json

      while read -r rule; do
        ruleId=$(echo "$rule" | jq -r '.id')
        ruleName=$(echo "$rule" | jq -r '.name')
        kind=$(echo "$rule" | jq -r '.kind')

        # Build the resource URL
        resourceUrl="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/alertRules/$ruleId?api-version=$apiVersion"

        # Check if rule already exists
        existingRule=$(az rest --method get --url "$resourceUrl" --only-show-errors 2>/dev/null) && ruleExists=true || ruleExists=false

        if [ "$ruleExists" = "true" ]; then
          echo "SKIP: Rule '$ruleName' already exists"
          echo $(( $(cat /tmp/skip_count) + 1 )) > /tmp/skip_count
          continue
        fi

        # Build the request payload based on rule kind
        if [ "$kind" = "NRT" ]; then
          payload=$(echo "$rule" | jq -c '{
            kind: "NRT",
            properties: {
              displayName: .name,
              description: .description,
              enabled: .enabled,
              severity: .severity,
              query: .query,
              tactics: .tactics,
              techniques: .techniques,
              entityMappings: .entityMappings,
              suppressionDuration: "PT5H",
              suppressionEnabled: false
            }
          }')
        else
          payload=$(echo "$rule" | jq -c '{
            kind: "Scheduled",
            properties: {
              displayName: .name,
              description: .description,
              enabled: .enabled,
              severity: .severity,
              query: .query,
              queryFrequency: .queryFrequency,
              queryPeriod: .queryPeriod,
              triggerOperator: .triggerOperator,
              triggerThreshold: .triggerThreshold,
              tactics: .tactics,
              techniques: .techniques,
              entityMappings: .entityMappings,
              suppressionDuration: "PT5H",
              suppressionEnabled: false
            }
          }')
        fi

        # Write payload to temp file
        echo "$payload" > /tmp/rule_payload.json

        # Create the rule
        response=$(az rest --method put --url "$resourceUrl" --body @/tmp/rule_payload.json --headers "Content-Type=application/json" --only-show-errors 2>&1) && rc=0 || rc=$?

        if [ $rc -eq 0 ]; then
          echo "SUCCESS: Created rule '$ruleName'"
          echo $(( $(cat /tmp/success_count) + 1 )) > /tmp/success_count
        else
          # Check if it's a data connector dependency error (common, not fatal)
          if echo "$response" | grep -qi "BadRequest\|data connector\|table.*not found\|table does not exist"; then
            echo "SKIP: Rule '$ruleName' - required data connector not enabled"
            echo $(( $(cat /tmp/skip_count) + 1 )) > /tmp/skip_count
          else
            echo "ERROR: Failed to create rule '$ruleName': $response" >&2
            echo $(( $(cat /tmp/error_count) + 1 )) > /tmp/error_count
          fi
        fi
      done < /tmp/rules.json

      successCount=$(cat /tmp/success_count)
      skipCount=$(cat /tmp/skip_count)
      errorCount=$(cat /tmp/error_count)

      echo ""
      echo "=========================================="
      echo "Analytic Rules Deployment Summary:"
      echo "  Total rules: $ruleCount"
      echo "  Successfully created: $successCount"
      echo "  Skipped (existing/no data): $skipCount"
      echo "  Errors: $errorCount"
      echo "=========================================="

      # Output results
      echo "{\"total\":$ruleCount,\"created\":$successCount,\"skipped\":$skipCount,\"errors\":$errorCount}" > $AZ_SCRIPTS_OUTPUT_PATH

      # Don't fail the deployment for rule errors - rules may need data connectors enabled first
      exit 0
    '''
  }
  dependsOn: [
    analyticRulesSentinelRole
  ]
}

output analyticRulesDeployed bool = deployAnalyticRules
