/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@description('The name of the virtual network the private dns zones will be connected to')
param vnetName string

@description('The name of the the resource group where the virtual network exists')
param vnetResourceGroup string = resourceGroup().name

@description('The subscription id of the subscription the virtual network exists in')
param vnetSubscriptionId string = subscription().subscriptionId

@description('The tags that will be associated to the resources')
param tags object

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var locations = (loadJsonContent('../data/locations.json'))[environment().name]
var privatelink_agentsvc_azure_automation_name = 'privatelink.agentsvc.azure-automation.${privatelink_azure_automation_suffixes[environment().name] ?? cloudSuffix}'
var privatelink_azure_automation_suffixes = {
  AzureCloud: 'net'
  AzureUSGovernment: 'us'
}
var privatelink_azure_automation_name = 'privatelink.azure-automation.${privatelink_azure_automation_suffixes[environment().name] ?? cloudSuffix}'
var privatelink_avd_suffixes = {
  AzureCloud: 'microsoft.com'
  AzureUSGovernment: 'azure.us'
}
var privatelink_avd_name = 'privatelink.wvd.${privatelink_avd_suffixes[environment().name] ?? cloudSuffix}'
var privatelink_avd_global_name = 'privatelink-global.wvd.${privatelink_avd_suffixes[environment().name] ?? cloudSuffix}'
var privatelink_backup_suffixes = {
  AzureCloud: 'windowsazure.com'
  AzureUSGovernment: 'windowsazure.us'
}
var privatelink_backup_names = [for location in items(locations): 'privatelink.${location.value.recoveryServicesGeo}.backup.${privatelink_backup_suffixes[environment().name] ?? cloudSuffix}']
var privatelink_file_name = 'privatelink.file.${environment().suffixes.storage}'
var privatelink_queue_name = 'privatelink.queue.${environment().suffixes.storage}'
var privatelink_table_name = 'privatelink.table.${environment().suffixes.storage}'
var privatelink_blob_name = 'privatelink.blob.${environment().suffixes.storage}'
var privatelink_keyvaultDns_name = replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
var privatelink_monitor_suffixes = {
  AzureCloud: 'azure.com'
  AzureUSGovernment: 'azure.us'
}
var privatelink_monitor_name = 'privatelink.monitor.${privatelink_monitor_suffixes[environment().name] ?? cloudSuffix}'
var privatelink_ods_opinsights_name = 'privatelink.ods.opinsights.${privatelink_monitor_suffixes[environment().name] ?? cloudSuffix}'
var privatelink_oms_opinsights_name = 'privatelink.oms.opinsights.${privatelink_monitor_suffixes[environment().name] ?? cloudSuffix}'

resource privateDnsZone_avd 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_avd_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_avd_global 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_avd_global_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_backup_rsv 'Microsoft.Network/privateDnsZones@2018-09-01' = [for name in privatelink_backup_names: if (!(contains(name, '..'))) {
  name: name
  location: 'global'
  tags: tags
}]

resource privateDnsZone_file 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_file_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_queue 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_queue_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_table 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_table_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_keyvaultDns 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_keyvaultDns_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_monitor 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_monitor_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_oms_opinsights 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_oms_opinsights_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_ods_opinsights 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_ods_opinsights_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_agentsvc_azure_automation 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_agentsvc_azure_automation_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_azure_automation 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_azure_automation_name
  location: 'global'
  tags: tags
}

resource privateDnsZone_blob 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privatelink_blob_name
  location: 'global'
  tags: tags
}

resource virtualNetworkLink_avd 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_avd_name}-link'
  parent: privateDnsZone_avd
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_file 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_file_name}-link'
  parent: privateDnsZone_file
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_table 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_table_name}-link'
  parent: privateDnsZone_table
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_keyvaultDns 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_keyvaultDns_name}-link'
  parent: privateDnsZone_keyvaultDns
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_queue 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_queue_name}-link'
  parent: privateDnsZone_queue
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_backup_rsv 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (name, i) in privatelink_backup_names: {
  name: '${name}-link'
  parent: privateDnsZone_backup_rsv[i]
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}]

resource virtualNetworkLink_avd_global 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_avd_global_name}-link'
  parent: privateDnsZone_avd_global
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_monitor 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_monitor_name}-link'
  parent: privateDnsZone_monitor
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_oms_opinsights 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_oms_opinsights_name}-link'
  parent: privateDnsZone_oms_opinsights
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_ods_opinsights 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_ods_opinsights_name}-link'
  parent: privateDnsZone_ods_opinsights
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

resource virtualNetworkLink_agentsvc_azure_automation 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_agentsvc_azure_automation_name}-link'
  parent: privateDnsZone_agentsvc_azure_automation
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}

resource virtualNetworkLink_azure_automation 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_azure_automation_name}-link'
  parent: privateDnsZone_azure_automation
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}

resource virtualNetworkLink_blob 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privatelink_blob_name}-link'
  parent: privateDnsZone_blob
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetSubscriptionId, vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
  dependsOn: []
}

output agentsvcPrivateDnsZoneId string = privateDnsZone_agentsvc_azure_automation.id
output automationPrivateDnsZoneId string = privateDnsZone_azure_automation.id
output avdGlobalPrivateDnsZoneId string = privateDnsZone_avd_global.id
output avdPrivateDnsZoneId string = privateDnsZone_avd.id
output backupPrivateDnsZoneIds array = [for (name, i) in privatelink_backup_names: privateDnsZone_backup_rsv[i].id]
output blobPrivateDnsZoneId string = privateDnsZone_blob.id
output filePrivateDnsZoneId string = privateDnsZone_file.id
output keyvaultDnsPrivateDnsZoneId string = privateDnsZone_keyvaultDns.id
output monitorPrivateDnsZoneId string = privateDnsZone_monitor.id
output odsPrivateDnsZoneId string = privateDnsZone_ods_opinsights.id
output omsPrivateDnsZoneId string = privateDnsZone_oms_opinsights.id
output queuePrivateDnsZoneId string = privateDnsZone_queue.id
output storagePrivateDnsZoneId string = privateDnsZone_blob.id
output tablePrivateDnsZoneId string = privateDnsZone_table.id
