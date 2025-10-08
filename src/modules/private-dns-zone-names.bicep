targetScope = 'subscription'

// param locations object // This is only needed for Recovery Services which has been disabled for now.

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.azure.', ''), '/', '')
var privateDnsZoneNames = union([
  'privatelink.agentsvc.azure-automation.${privateDnsZoneSuffixes.azureAutomation[?environment().name] ?? 'opinsights.azure.${cloudSuffix}'}' // Automation
  'privatelink.azure-automation.${privateDnsZoneSuffixes.azureAutomation[?environment().name] ?? cloudSuffix}' // Automation
  'privatelink.${privateDnsZoneSuffixes.azureWebSites[?environment().name] ?? 'appservice.${cloudSuffix}'}' // Web Apps & Function Apps
  'scm.privatelink.${privateDnsZoneSuffixes.azureWebSites[?environment().name] ?? 'appservice.${cloudSuffix}'}' // Web Apps & Function Apps
  'privatelink.wvd.${privateDnsZoneSuffixes.azureVirtualDesktop[?environment().name] ?? cloudSuffix}' // Azure Virtual Desktop (Connection & Feed)
  'privatelink-global.wvd.${privateDnsZoneSuffixes.azureVirtualDesktop[?environment().name] ?? cloudSuffix}' // Azure Virtual Desktop (Global)
  'privatelink.file.${environment().suffixes.storage}' // Azure Files
  'privatelink.queue.${environment().suffixes.storage}' // Azure Queues
  'privatelink.table.${environment().suffixes.storage}' // Azure Tables
  'privatelink.blob.${environment().suffixes.storage}' // Azure Blobs
  'privatelink${replace(environment().suffixes.keyvaultDns, 'vault', 'vaultcore')}' // Key Vault
  'privatelink.monitor.azure.${privateDnsZoneSuffixes.azureMonitor[?environment().name] ?? cloudSuffix}' // Azure Monitor
  'privatelink.ods.opinsights.azure.${privateDnsZoneSuffixes.azureMonitor[?environment().name] ?? cloudSuffix}' // Azure Monitor
  'privatelink.oms.opinsights.azure.${privateDnsZoneSuffixes.azureMonitor[?environment().name] ?? cloudSuffix}' // Azure Monitor
  'privatelink${environment().suffixes.sqlServerHostname}'  // Azure SQL Server
], []) // privateDnsZoneNames_Backup) // Recovery Services has been disabled for now.

// The following variable is only needed for Recovery Services which has been disabled for now.
// var privateDnsZoneNames_Backup = [for location in items(locations): 'privatelink.${location.value.recoveryServicesGeo}.backup.windowsazure.${privateDnsZoneSuffixes.azureBackup[environment().name] ?? cloudSuffix}']

var privateDnsZoneSuffixes = {
  azureAutomation: {
    AzureCloud: 'net'
    AzureUSGovernment: 'us'
  }
  azureBackup: {
    AzureCloud: 'com'
    AzureUSGovernment: 'us'
  }
  azureMonitor: {
    AzureCloud: 'com'
    AzureUSGovernment: 'us'
  }
  azureVirtualDesktop: {
    AzureCloud: 'microsoft.com'
    AzureUSGovernment: 'azure.us'
  }
  azureWebSites: {
    AzureCloud: 'azurewebsites.net'
    AzureUSGovernment: 'azurewebsites.us'
  }
}

output names array = privateDnsZoneNames
