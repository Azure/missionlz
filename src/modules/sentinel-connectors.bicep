targetScope = 'resourceGroup'

@description('Name of the Log Analytics workspace that hosts Microsoft Sentinel.')
param workspaceName string

@description('Tenant ID associated with the Microsoft Sentinel workspace.')
param tenantId string

@description('Toggle to deploy the Azure Activity data connector.')
param enableAzureActivityConnector bool = true

@description('Toggle to deploy the Microsoft Entra ID data connector.')
param enableEntraIdConnector bool = true

@description('Desired state (Enabled/Disabled) for each Microsoft Entra ID log type exposed by the data connector.')
param entraDataTypeStates object = {
  SignInLogs: 'Enabled'
  AuditLogs: 'Enabled'
  NonInteractiveUserSignInLogs: 'Enabled'
  ServicePrincipalSignInLogs: 'Enabled'
  ManagedIdentitySignInLogs: 'Enabled'
  ProvisioningLogs: 'Enabled'
  ADFSSignInLogs: 'Enabled'
  UserRiskEvents: 'Enabled'
  RiskyUsers: 'Enabled'
  RiskyServicePrincipals: 'Enabled'
  alerts: 'Enabled'
}

var normalizedEntraDataTypes = {
  SignInLogs: {
    state: entraDataTypeStates.SignInLogs
  }
  AuditLogs: {
    state: entraDataTypeStates.AuditLogs
  }
  NonInteractiveUserSignInLogs: {
    state: entraDataTypeStates.NonInteractiveUserSignInLogs
  }
  ServicePrincipalSignInLogs: {
    state: entraDataTypeStates.ServicePrincipalSignInLogs
  }
  ManagedIdentitySignInLogs: {
    state: entraDataTypeStates.ManagedIdentitySignInLogs
  }
  ProvisioningLogs: {
    state: entraDataTypeStates.ProvisioningLogs
  }
  ADFSSignInLogs: {
    state: entraDataTypeStates.ADFSSignInLogs
  }
  UserRiskEvents: {
    state: entraDataTypeStates.UserRiskEvents
  }
  RiskyUsers: {
    state: entraDataTypeStates.RiskyUsers
  }
  RiskyServicePrincipals: {
    state: entraDataTypeStates.RiskyServicePrincipals
  }
  alerts: {
    state: entraDataTypeStates.alerts
  }
}

@description('API version to use when configuring the Microsoft Sentinel data connector.')
param connectorApiVersion string = '2022-11-01-preview'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// NOTE: In some environments the Microsoft Entra ID connector is created by the Content Hub solution.
// ARM create/update can fail with: "Upsert failed since a connector with the name AzureActiveDirectory already exists."
// Use a deployment script to upsert idempotently.
var entraConnectorResourceId = '${workspace.id}/providers/Microsoft.SecurityInsights/dataConnectors/AzureActiveDirectory'
var entraConnectorPayload = string({
  location: workspace.location
  kind: 'AzureActiveDirectory'
  properties: {
    tenantId: tenantId
    dataTypes: normalizedEntraDataTypes
  }
})

// Created by sentinel-settings.bicep in the same resource group.
resource sentinelScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'sentinel-script-${uniqueString(resourceGroup().id)}'
}

resource configureEntraConnector 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (enableEntraIdConnector) {
  name: 'configure-entra-connector-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sentinelScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT10M'
    forceUpdateTag: '${tenantId}-${base64(entraConnectorPayload)}'
    environmentVariables: [
      {
        name: 'ENTRA_CONNECTOR_ID'
        value: entraConnectorResourceId
      }
      {
        name: 'ENTRA_CONNECTOR_PAYLOAD'
        value: entraConnectorPayload
      }
      {
        name: 'ENTRA_CONNECTOR_API_VERSION'
        value: connectorApiVersion
      }
    ]
    scriptContent: '''
      set -uo pipefail

      resourceId="$ENTRA_CONNECTOR_ID"
      apiVersion="$ENTRA_CONNECTOR_API_VERSION"
      payload="$ENTRA_CONNECTOR_PAYLOAD"

      etag=$(az rest --method get --url "$resourceId?api-version=$apiVersion" --query etag -o tsv --only-show-errors 2>/dev/null || echo "")

      if [ -n "$etag" ]; then
        response=$(az rest --method put --headers "Content-Type=application/json" "If-Match=$etag" --url "$resourceId?api-version=$apiVersion" --body "$payload" --only-show-errors 2>&1) || rc=$?
      else
        response=$(az rest --method put --headers "Content-Type=application/json" "If-None-Match=*" --url "$resourceId?api-version=$apiVersion" --body "$payload" --only-show-errors 2>&1) || rc=$?
      fi

      if [ -n "${rc:-}" ] && [ "${rc:-0}" -ne 0 ]; then
        if echo "$response" | grep -qi "already exists"; then
          echo "$response" >&2
          exit 0
        fi

        # If the workspace is the Primary workspace in Microsoft 365 Defender / Threat Protection, connector changes may be blocked in Sentinel.
        if echo "$response" | grep -qi "changes to the connector.*disabled\|primary.*workspace\|threat protection portal"; then
          echo "$response" >&2
          exit 0
        fi

        echo "$response" >&2
        exit ${rc:-1}
      fi
    '''
  }
}

// Azure Activity data connector - uses the same idempotent upsert pattern as Entra ID connector
var azureActivityConnectorResourceId = '${workspace.id}/providers/Microsoft.SecurityInsights/dataConnectors/AzureActivityConnector'
var azureActivityConnectorPayload = string({
  location: workspace.location
  kind: 'AzureActivity'
  properties: {
    tenantId: tenantId
    dataTypes: {
      azureActivity: {
        state: 'Enabled'
      }
    }
  }
})

resource configureAzureActivityConnector 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (enableAzureActivityConnector) {
  name: 'configure-activity-connector-${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${sentinelScriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.61.0'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
    timeout: 'PT10M'
    forceUpdateTag: '${tenantId}-activity-${base64(azureActivityConnectorPayload)}'
    environmentVariables: [
      {
        name: 'ACTIVITY_CONNECTOR_ID'
        value: azureActivityConnectorResourceId
      }
      {
        name: 'ACTIVITY_CONNECTOR_PAYLOAD'
        value: azureActivityConnectorPayload
      }
      {
        name: 'ACTIVITY_CONNECTOR_API_VERSION'
        value: connectorApiVersion
      }
    ]
    scriptContent: '''
      set -uo pipefail

      resourceId="$ACTIVITY_CONNECTOR_ID"
      apiVersion="$ACTIVITY_CONNECTOR_API_VERSION"
      payload="$ACTIVITY_CONNECTOR_PAYLOAD"

      etag=$(az rest --method get --url "$resourceId?api-version=$apiVersion" --query etag -o tsv --only-show-errors 2>/dev/null || echo "")

      if [ -n "$etag" ]; then
        response=$(az rest --method put --headers "Content-Type=application/json" "If-Match=$etag" --url "$resourceId?api-version=$apiVersion" --body "$payload" --only-show-errors 2>&1) || rc=$?
      else
        response=$(az rest --method put --headers "Content-Type=application/json" "If-None-Match=*" --url "$resourceId?api-version=$apiVersion" --body "$payload" --only-show-errors 2>&1) || rc=$?
      fi

      if [ -n "${rc:-}" ] && [ "${rc:-0}" -ne 0 ]; then
        if echo "$response" | grep -qi "already exists"; then
          echo "$response" >&2
          exit 0
        fi

        # If the workspace is the Primary workspace in Microsoft 365 Defender / Threat Protection, connector changes may be blocked in Sentinel.
        if echo "$response" | grep -qi "changes to the connector.*disabled\|primary.*workspace\|threat protection portal"; then
          echo "$response" >&2
          exit 0
        fi

        echo "$response" >&2
        exit ${rc:-1}
      fi
    '''
  }
}
