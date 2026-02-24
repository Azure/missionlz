targetScope = 'resourceGroup'

@description('Name of the Log Analytics workspace where Microsoft Sentinel is enabled.')
param workspaceName string

@description('Azure region used for ancillary operations such as deployment scripts.')
param location string

@description('Toggle to configure the Entity Behavior Analytics setting.')
param enableEntityBehavior bool = true

@description('Skip provisioning the Entity Behavior Analytics setting when it already exists to avoid concurrency conflicts.')
param deployEntityBehaviorSetting bool = true

@description('Use the deployment script to upsert Entity Behavior. Set to true for idempotent updates (recommended). Set to false for native Bicep (new deployments only).')
param useEntityBehaviorScript bool = true

@description('Toggle to configure UEBA data sources and ensure they participate in the ML fusion models.')
param enableUeba bool = true

@description('Skip provisioning the UEBA setting when it already exists to avoid concurrency conflicts.')
param deployUebaSetting bool = true

@description('Use the deployment script to upsert UEBA. Set to true for idempotent updates (recommended). Set to false for native Bicep (new deployments only).')
param useUebaScript bool = true

@description('Data sources that enrich UEBA insights.')
param uebaDataSources array = [
  'SigninLogs'
  'AuditLogs'
  'AzureActivity'
]

@description('Toggle to ensure Microsoft Sentinel anomaly detection remains enabled.')
param enableAnomalies bool = true

@description('Toggle to configure Microsoft Entra ID diagnostic settings.')
param enableEntraDiagnostics bool = true

@description('Name of the Microsoft Entra ID diagnostic setting.')
param entraDiagnosticName string = 'diag-entra'

@description('Resource ID of the Log Analytics workspace for Entra diagnostics.')
param entraWorkspaceResourceId string = ''

@description('Log categories to enable for Microsoft Entra ID diagnostics.')
param entraLogCategories array = [
  'AuditLogs'
  'SignInLogs'
  'NonInteractiveUserSignInLogs'
  'ServicePrincipalSignInLogs'
  'ManagedIdentitySignInLogs'
  'ProvisioningLogs'
  'ADFSSignInLogs'
  'RiskyUsers'
  'RiskyServicePrincipals'
  'UserRiskEvents'
  'ServicePrincipalRiskEvents'
]

@description('Optional override for the Azure Security Insights service principal object ID if discovery via Microsoft Graph is restricted.')
param sentinelAutomationPrincipalId string = ''

@description('Toggle to run the deployment script that discovers and assigns the Sentinel automation service principal. Disable when you plan to handle the automation role manually later.')
param deploySentinelAutomationScript bool = true

var sentinelAutomationContributorRoleDefinitionGuid = 'f4c81013-99ee-4d62-a7ee-b3f1f648599a'
var workspaceContributorRoleDefinitionGuid = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var shouldRunAutomationScript = deploySentinelAutomationScript
var shouldConfigureEntitySettingViaScript = enableEntityBehavior && deployEntityBehaviorSetting && useEntityBehaviorScript
var shouldConfigureEntitySettingNative = enableEntityBehavior && deployEntityBehaviorSetting && !useEntityBehaviorScript
var shouldConfigureUebaSettingViaScript = enableUeba && deployUebaSetting && useUebaScript
var shouldConfigureUebaSettingNative = enableUeba && deployUebaSetting && !useUebaScript
var shouldConfigureAnomaliesSetting = enableAnomalies
// Keep backward compat variables for role assignments
var shouldConfigureEntitySetting = enableEntityBehavior && deployEntityBehaviorSetting
var shouldConfigureUebaSetting = enableUeba && deployUebaSetting
var shouldConfigureEntraDiagnostics = enableEntraDiagnostics && !empty(entraWorkspaceResourceId)

// Entra diagnostic settings payload
var entraLogsConfig = [for category in entraLogCategories: {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: false
    days: 0
  }
}]
var entraDiagnosticPayload = string({
  properties: {
    workspaceId: entraWorkspaceResourceId
    logs: entraLogsConfig
  }
})

var entityBehaviorSettingResourceId = extensionResourceId(workspace.id, 'Microsoft.SecurityInsights/settings', 'EntityAnalytics')
var entityBehaviorSettingPayload = string({
  kind: 'EntityAnalytics'
  properties: {
    entityProviders: [
      'AzureActiveDirectory'
    ]
  }
})

var uebaSettingResourceId = extensionResourceId(workspace.id, 'Microsoft.SecurityInsights/settings', 'Ueba')
var uebaSettingPayload = string({
  kind: 'Ueba'
  properties: {
    dataSources: uebaDataSources
  }
})

var anomaliesSettingResourceId = extensionResourceId(workspace.id, 'Microsoft.SecurityInsights/settings', 'Anomalies')
var anomaliesSettingPayload = string({
  kind: 'Anomalies'
  properties: {}
})

resource automationScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'sentinel-script-${uniqueString(resourceGroup().id)}'
  location: location
}

resource automationScriptIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (shouldRunAutomationScript || shouldConfigureEntitySetting) {
  name: guid(resourceGroup().id, automationScriptIdentity.name, 'automation-script-rbac')
  properties: {
    principalId: automationScriptIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830') // User Access Administrator
  }
}

resource automationScriptSentinelRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (shouldConfigureEntitySetting || shouldConfigureUebaSetting || shouldConfigureAnomaliesSetting) {
  name: guid(workspace.id, automationScriptIdentity.name, 'automation-script-sentinel-rbac')
  scope: workspace
  properties: {
    principalId: automationScriptIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', workspaceContributorRoleDefinitionGuid)
  }
}

resource automationPrincipalLookup 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (shouldRunAutomationScript) {
  name: 'lookup-asi-sp-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${automationScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT15M'
    forceUpdateTag: empty(sentinelAutomationPrincipalId) ? 'auto' : sentinelAutomationPrincipalId
    environmentVariables: [
      {
        name: 'SENTINEL_SP_OBJECT_ID_OVERRIDE'
        value: sentinelAutomationPrincipalId
      }
      {
        name: 'SENTINEL_AUTOMATION_SCOPE'
        value: resourceGroup().id
      }
      {
        name: 'SENTINEL_AUTOMATION_ROLE_ID'
        value: sentinelAutomationContributorRoleDefinitionGuid
      }
    ]
    scriptContent: '''
      set -uo pipefail
      
      # Well-known Application ID for Azure Security Insights (constant across all tenants)
      AZURE_SECURITY_INSIGHTS_APP_ID="98785600-1bb7-4fb9-b9fa-19afe2c8a360"
      
      principalId="$SENTINEL_SP_OBJECT_ID_OVERRIDE"
      
      if [ -z "$principalId" ]; then
        # Try to look up by App ID first (more reliable)
        principalId=$(az ad sp show --id "$AZURE_SECURITY_INSIGHTS_APP_ID" --query "id" -o tsv 2>/dev/null || echo "")
        
        # Fallback to display name lookup
        if [ -z "$principalId" ]; then
          principalId=$(az ad sp list --display-name "Azure Security Insights" --query "[0].id" -o tsv 2>/dev/null || echo "")
        fi
      fi

      if [ -z "$principalId" ]; then
        echo "INFO: Could not discover Azure Security Insights service principal." >&2
        echo "INFO: This is expected if the identity lacks Directory.Read.All permissions." >&2
        echo "INFO: Sentinel automation role can be assigned manually later if needed." >&2
        echo "INFO: Use the Finalize-SentinelAutomation.ps1 script after deployment." >&2
        echo "{\"sentinelSpObjectId\": \"\", \"status\": \"skipped\"}" > $AZ_SCRIPTS_OUTPUT_PATH
        exit 0
      fi

      scope="$SENTINEL_AUTOMATION_SCOPE"
      roleDefinitionId="$SENTINEL_AUTOMATION_ROLE_ID"

      existingAssignment=$(az role assignment list --scope "$scope" --assignee-object-id "$principalId" --role "$roleDefinitionId" --query "[0].id" -o tsv 2>/dev/null || echo "")

      if [ -z "$existingAssignment" ]; then
        az role assignment create --assignee-object-id "$principalId" --assignee-principal-type ServicePrincipal --role "$roleDefinitionId" --scope "$scope" --only-show-errors 2>&1 || true
      fi

      echo "{\"sentinelSpObjectId\": \"$principalId\", \"status\": \"configured\"}" > $AZ_SCRIPTS_OUTPUT_PATH
    '''
  }
}
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2024-01-01-preview' = {
  name: 'default'
  scope: workspace
  properties: {
    customerManagedKey: false
  }
}

// Native Bicep resource for Entity Analytics - deploys with user credentials (recommended)
resource entityAnalyticsSetting 'Microsoft.SecurityInsights/settings@2024-01-01-preview' = if (shouldConfigureEntitySettingNative) {
  name: 'EntityAnalytics'
  kind: 'EntityAnalytics'
  scope: workspace
  properties: {
    entityProviders: [
      'AzureActiveDirectory'
    ]
  }
  dependsOn: [
    sentinel
  ]
}

// Native Bicep resource for UEBA - deploys with user credentials (recommended)
resource uebaSetting 'Microsoft.SecurityInsights/settings@2024-01-01-preview' = if (shouldConfigureUebaSettingNative) {
  name: 'Ueba'
  kind: 'Ueba'
  scope: workspace
  properties: {
    dataSources: uebaDataSources
  }
  dependsOn: [
    sentinel
    entityAnalyticsSetting
  ]
}

resource entityBehaviorSettingScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (shouldConfigureEntitySettingViaScript) {
  name: 'configure-entity-behavior-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${automationScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT10M'
    environmentVariables: [
      {
        name: 'ENTITY_SETTING_ID'
        value: entityBehaviorSettingResourceId
      }
      {
        name: 'ENTITY_SETTING_PAYLOAD'
        value: entityBehaviorSettingPayload
      }
    ]
    scriptContent: '''
      set -uo pipefail

      resourceId="$ENTITY_SETTING_ID"
      apiVersion="2024-01-01-preview"
      
      # Write payload to file to avoid shell escaping issues
      echo "$ENTITY_SETTING_PAYLOAD" > /tmp/payload.json

      etag=$(az rest --method get --url "$resourceId?api-version=$apiVersion" --query etag -o tsv --only-show-errors 2>/dev/null || echo "")

      if [ -n "$etag" ]; then
        response=$(az rest --method put --headers "Content-Type=application/json" "If-Match=$etag" --url "$resourceId?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?
      else
        response=$(az rest --method put --headers "Content-Type=application/json" "If-None-Match=*" --url "$resourceId?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?
      fi

      if [ -n "${rc:-}" ] && [ "${rc:-0}" -ne 0 ]; then
        if echo "$response" | grep -qi "Only 'Security Administrator' and 'Global Administrator'\|User does not have required admin roles\|Unauthorized"; then
          echo "INFO: Entity Analytics setting requires Global Administrator or Security Administrator role. Skipping." >&2
          echo "$response" >&2
          echo '{"status":"skipped_permissions"}' > $AZ_SCRIPTS_OUTPUT_PATH
          exit 0
        fi

        # If the workspace is the Primary workspace in Microsoft 365 Defender / Threat Protection, setting changes may be blocked.
        if echo "$response" | grep -qi "changes.*disabled\|primary.*workspace\|threat protection portal"; then
          echo "INFO: Entity Analytics setting is managed by the primary workspace (Microsoft Threat Protection)." >&2
          echo "$response" >&2
          echo '{"status":"skipped_primary_workspace"}' > $AZ_SCRIPTS_OUTPUT_PATH
          exit 0
        fi

        echo "ERROR: Failed to configure Entity Analytics setting" >&2
        echo "$response" >&2
        exit ${rc:-1}
      fi

      echo "SUCCESS: Entity Analytics setting configured" >&2
      echo '{"status":"configured"}' > $AZ_SCRIPTS_OUTPUT_PATH
    '''
  }
  dependsOn: [
    sentinel
    automationScriptIdentityRoleAssignment
    automationScriptSentinelRoleAssignment
  ]
}

resource uebaSettingScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (shouldConfigureUebaSettingViaScript) {
  name: 'configure-ueba-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${automationScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT10M'
    environmentVariables: [
      {
        name: 'UEBA_SETTING_ID'
        value: uebaSettingResourceId
      }
      {
        name: 'UEBA_SETTING_PAYLOAD'
        value: uebaSettingPayload
      }
    ]
    scriptContent: '''
      set -uo pipefail

      resourceId="$UEBA_SETTING_ID"
      apiVersion="2024-01-01-preview"
      
      # Write payload to file to avoid shell escaping issues
      echo "$UEBA_SETTING_PAYLOAD" > /tmp/payload.json

      etag=$(az rest --method get --url "$resourceId?api-version=$apiVersion" --query etag -o tsv --only-show-errors 2>/dev/null || echo "")

      if [ -n "$etag" ]; then
        response=$(az rest --method put --headers "Content-Type=application/json" "If-Match=$etag" --url "$resourceId?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?
      else
        response=$(az rest --method put --headers "Content-Type=application/json" "If-None-Match=*" --url "$resourceId?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?
      fi

      if [ -n "${rc:-}" ] && [ "${rc:-0}" -ne 0 ]; then
        if echo "$response" | grep -q "requires 'EntityAnalytics' to be enabled"; then
          echo "INFO: UEBA requires Entity Analytics to be enabled first." >&2
          echo "$response" >&2
          echo '{"status":"skipped_entity_required"}' > $AZ_SCRIPTS_OUTPUT_PATH
          exit 0
        fi

        if echo "$response" | grep -qi "Only 'Security Administrator' and 'Global Administrator'\|User does not have required admin roles\|Unauthorized"; then
          echo "INFO: UEBA setting requires Global Administrator or Security Administrator role. Skipping." >&2
          echo "$response" >&2
          echo '{"status":"skipped_permissions"}' > $AZ_SCRIPTS_OUTPUT_PATH
          exit 0
        fi

        # If the workspace is the Primary workspace in Microsoft 365 Defender / Threat Protection, setting changes may be blocked.
        if echo "$response" | grep -qi "changes.*disabled\|primary.*workspace\|threat protection portal"; then
          echo "INFO: UEBA setting is managed by the primary workspace (Microsoft Threat Protection)." >&2
          echo "$response" >&2
          echo '{"status":"skipped_primary_workspace"}' > $AZ_SCRIPTS_OUTPUT_PATH
          exit 0
        fi

        echo "ERROR: Failed to configure UEBA setting" >&2
        echo "$response" >&2
        exit ${rc:-1}
      fi

      echo "SUCCESS: UEBA setting configured" >&2
      echo '{"status":"configured"}' > $AZ_SCRIPTS_OUTPUT_PATH
    '''
  }
  dependsOn: [
    sentinel
    automationScriptSentinelRoleAssignment
  ]
}

resource anomaliesSettingScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (shouldConfigureAnomaliesSetting) {
  name: 'configure-anomalies-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${automationScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT10M'
    environmentVariables: [
      {
        name: 'ANOMALIES_SETTING_ID'
        value: anomaliesSettingResourceId
      }
      {
        name: 'ANOMALIES_SETTING_PAYLOAD'
        value: anomaliesSettingPayload
      }
    ]
    scriptContent: '''
      set -uo pipefail

      resourceId="$ANOMALIES_SETTING_ID"
      apiVersion="2024-01-01-preview"
      
      # Write payload to file to avoid shell escaping issues
      echo "$ANOMALIES_SETTING_PAYLOAD" > /tmp/payload.json

      etag=$(az rest --method get --url "$resourceId?api-version=$apiVersion" --query etag -o tsv --only-show-errors 2>/dev/null || echo "")

      if [ -n "$etag" ]; then
        response=$(az rest --method put --headers "Content-Type=application/json" "If-Match=$etag" --url "$resourceId?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?
      else
        response=$(az rest --method put --headers "Content-Type=application/json" "If-None-Match=*" --url "$resourceId?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?
      fi

      if [ -n "${rc:-}" ] && [ "${rc:-0}" -ne 0 ]; then
        if echo "$response" | grep -q "Only 'Security Administrator' and 'Global Administrator'"; then
          echo "INFO: Anomalies setting requires Global Administrator or Security Administrator role." >&2
          echo "$response" >&2
          exit 0
        fi

        # If the workspace is the Primary workspace in Microsoft 365 Defender / Threat Protection, setting changes may be blocked.
        if echo "$response" | grep -qi "changes.*disabled\|primary.*workspace\|threat protection portal"; then
          echo "INFO: Anomalies setting is managed by the primary workspace (Microsoft Threat Protection)." >&2
          echo "$response" >&2
          exit 0
        fi

        echo "ERROR: Failed to configure Anomalies setting" >&2
        echo "$response" >&2
        exit ${rc:-1}
      fi

      echo "SUCCESS: Anomalies setting configured" >&2
      echo '{"status":"configured"}' > $AZ_SCRIPTS_OUTPUT_PATH
    '''
  }
  dependsOn: [
    sentinel
    automationScriptSentinelRoleAssignment
  ]
}

// Microsoft Entra ID diagnostic settings deployment script
resource entraDiagnosticsScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (shouldConfigureEntraDiagnostics) {
  name: 'configure-entra-diagnostics-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${automationScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT10M'
    environmentVariables: [
      {
        name: 'ENTRA_DIAGNOSTIC_NAME'
        value: entraDiagnosticName
      }
      {
        name: 'ENTRA_DIAGNOSTIC_PAYLOAD'
        value: entraDiagnosticPayload
      }
    ]
    scriptContent: '''
      set -uo pipefail

      diagnosticName="$ENTRA_DIAGNOSTIC_NAME"
      apiVersion="2017-04-01-preview"
      
      # Write payload to file to avoid shell escaping issues
      echo "$ENTRA_DIAGNOSTIC_PAYLOAD" > /tmp/payload.json

      # Check if diagnostic setting already exists
      existing=$(az rest --method get --url "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/$diagnosticName?api-version=$apiVersion" --query name -o tsv --only-show-errors 2>/dev/null || echo "")

      if [ -n "$existing" ]; then
        echo "INFO: Entra diagnostic setting '$diagnosticName' already exists, updating..." >&2
      fi

      # Create or update the diagnostic setting
      response=$(az rest --method put --url "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/$diagnosticName?api-version=$apiVersion" --body @/tmp/payload.json --only-show-errors 2>&1) || rc=$?

      if [ -n "${rc:-}" ] && [ "${rc:-0}" -ne 0 ]; then
        # Check for permission errors - requires Global Admin or Security Admin
        if echo "$response" | grep -qi "authorization\|forbidden\|global administrator\|security administrator\|permission"; then
          echo "WARNING: Entra ID diagnostic settings require Global Administrator or Security Administrator role." >&2
          echo "INFO: You can configure this manually in Azure AD > Diagnostic settings > Add diagnostic setting" >&2
          echo "$response" >&2
          exit 0
        fi

        # Check for conflict (already exists with different config)
        if echo "$response" | grep -qi "conflict\|already exists"; then
          echo "INFO: Entra diagnostic setting already exists." >&2
          exit 0
        fi

        echo "ERROR: Failed to configure Entra ID diagnostics" >&2
        echo "$response" >&2
        exit ${rc:-1}
      fi

      echo "SUCCESS: Entra ID diagnostic setting '$diagnosticName' configured" >&2
      echo '{"status":"configured","name":"'"$diagnosticName"'"}' > $AZ_SCRIPTS_OUTPUT_PATH
    '''
  }
  dependsOn: [
    automationScriptIdentityRoleAssignment
  ]
}

output sentinelResourceId string = sentinel.id
