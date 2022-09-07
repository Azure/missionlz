# Mission Landing Zone Bicep Template

This folder contains the Bicep template `mlz.bicep` for deploying Mission Landing Zone. See the [Deployment Guide for Bicep](../../docs/deployment-guide-bicep.md) for detailed instructions on how to use the template.

## Parameters

<!-- markdownlint-disable MD034 -->
Parameter name | Required | Description
-------------- | -------- | -----------
`resourcePrefix` | Yes      | A prefix, 3-10 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces
`resourceSuffix` | No       | A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".
`hubSubscriptionId` | No       | The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.
`identitySubscriptionId` | No       | The subscription ID for the Identity Network and resources. It defaults to the deployment subscription.
`operationsSubscriptionId` | No       | The subscription ID for the Operations Network and resources. It defaults to the deployment subscription.
`sharedServicesSubscriptionId` | No       | The subscription ID for the Shared Services Network and resources. It defaults to the deployment subscription.
`location`       | No       | The region to deploy resources into. It defaults to the deployment location.
`deploymentNameSuffix` | No       | A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.
`tags`           | No       | A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.
`hubVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.
`hubSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.
`firewallClientSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallManagementSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.
`identityVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Identity Virtual Network.
`identitySubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.
`operationsVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Operations Virtual Network.
`operationsSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.
`sharedServicesVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.
`sharedServicesSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.
`firewallSkuTier` | No       | [Standard/Premium] The SKU for Azure Firewall. It defaults to "Premium".
`firewallThreatIntelMode` | No       | [Alert/Deny/Off] The Azure Firewall Threat Intelligence Rule triggered logging behavior. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".
`firewallIntrusionDetectionMode` | No       | [Alert/Deny/Off] The Azure Firewall Intrusion Detection mode. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".
`firewallDiagnosticsLogs` | No       | An array of Firewall Diagnostic Logs categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.
`firewallDiagnosticsMetrics` | No       | An array of Firewall Diagnostic Metrics categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.
`firewallClientSubnetServiceEndpoints` | No       | An array of Service Endpoints to enable for the Azure Firewall Client Subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.
`firewallClientPublicIPAddressAvailabilityZones` | No       | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.
`firewallManagementSubnetServiceEndpoints` | No       | An array of Service Endpoints to enable for the Azure Firewall Management Subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.
`firewallManagementPublicIPAddressAvailabilityZones` | No       | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.
`firewallSupernetIPAddress` | No       | Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses
`publicIPAddressDiagnosticsLogs` | No       | An array of Public IP Address Diagnostic Logs for the Azure Firewall. See https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs for valid settings.
`publicIPAddressDiagnosticsMetrics` | No       | An array of Public IP Address Diagnostic Metrics for the Azure Firewall. See https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications for valid settings.
`hubVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`hubVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`hubNetworkSecurityGroupRules` | No       | An array of Network Security Group Rules to apply to the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`hubNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`hubNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Metrics to apply to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`hubSubnetServiceEndpoints` | No       | An array of Service Endpoints to enable for the Hub subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.
`identityVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`identityVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`identityNetworkSecurityGroupRules` | No       | An array of Network Security Group Rules to apply to the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`identityNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`identityNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Metrics to apply to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`identitySubnetServiceEndpoints` | No       | An array of Service Endpoints to enable for the Identity subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.
`operationsVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`operationsVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`operationsNetworkSecurityGroupRules` | No       | An array of Network Security Group rules to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`operationsNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`operationsNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`operationsSubnetServiceEndpoints` | No       | An array of Service Endpoints to enable for the Operations subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.
`sharedServicesVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`sharedServicesVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`sharedServicesNetworkSecurityGroupRules` | No       | An array of Network Security Group rules to apply to the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`sharedServicesNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`sharedServicesNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Diagnostic Metrics to enable for the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`sharedServicesSubnetServiceEndpoints` | No       | An array of Service Endpoints to enable for the SharedServices subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.
`deploySentinel` | No       | When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment. It defaults to "false".
`logAnalyticsWorkspaceCappingDailyQuotaGb` | No       | The daily quota for Log Analytics Workspace logs in Gigabytes. It defaults to "-1" for no quota.
`logAnalyticsWorkspaceRetentionInDays` | No       | The number of days to retain Log Analytics Workspace logs. It defaults to "30".
`logAnalyticsWorkspaceSkuName` | No       | [Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/resource-manager-workspace for valid settings.
`logStorageSkuName` | No       | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.
`deployRemoteAccess` | No       | When set to "true", provisions Azure Bastion Host and virtual machine jumpboxes. It defaults to "false".
`bastionHostSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the Azure Bastion Subnet. It must be in the Hub Virtual Network space "hubVirtualNetworkAddressPrefix" parameter value. It must be /27 or larger.
`bastionHostPublicIPAddressAvailabilityZones` | No       | The Azure Bastion Public IP Address Availability Zones. It defaults to "No-Zone" because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.
`linuxVmAdminUsername` | No       | The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`linuxVmAuthenticationType` | No       | [sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".
`linuxVmAdminPasswordOrKey` | No       | The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.
`linuxVmSize`    | No       | The size of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_B2s".
`linuxVmOsDiskCreateOption` | No       | The disk creation option of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".
`linuxVmOsDiskType` | No       | The disk type of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_LRS".
`linuxVmImagePublisher` | No       | The image publisher of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Canonical".
`linuxVmImageOffer` | No       | The image offer of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "UbuntuServer".
`linuxVmImageSku` | No       | The image SKU of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "18.04-LTS".
`linuxVmImageVersion` | No       | The image version of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "latest".
`linuxNetworkInterfacePrivateIPAddressAllocationMethod` | No       | [Static/Dynamic] The public IP Address allocation method for the Linux virtual machine. It defaults to "Dynamic".
`windowsVmAdminUsername` | No       | The administrator username for the Windows Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`windowsVmAdminPassword` | No       | The administrator password the Windows Virtual Machine to Azure Bastion remote into. It must be > 12 characters in length. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.
`windowsVmSize`  | No       | The size of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "Standard_DS1_v2".
`windowsVmPublisher` | No       | The publisher of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "MicrosoftWindowsServer".
`windowsVmOffer` | No       | The offer of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "WindowsServer".
`windowsVmSku`   | No       | The SKU of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "2019-datacenter".
`windowsVmVersion` | No       | The version of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "latest".
`windowsVmCreateOption` | No       | The disk creation option of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".
`windowsVmStorageAccountType` | No       | The storage account type of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "StandardSSD_LRS".
`windowsNetworkInterfacePrivateIPAddressAllocationMethod` | No       | [Static/Dynamic] The public IP Address allocation method for the Windows virtual machine. It defaults to "Dynamic".
`deployPolicy`   | No       | When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".
`policy`         | No       | [NIST/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NIST". IL5 is only available for AzureUsGovernment and will switch to NIST if tried in AzureCloud.
`deployDefender`     | No       | When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".
`emailSecurityContact` | No       | Email address of the contact, in the form of john@doe.com
<!-- markdownlint-enable MD034 -->

## Outputs

You can use the AZ CLI or PowerShell to retrieve the output values from a deployment, or you can use the Azure Portal to view the output values. See the [Referencing Deployment Output section](../../docs/deployment-guide-bicep.md#reference-deployment-output) in the Deployment Guide for Bicep.

When the output is saved as a json document from the Azure CLI, these are the paths in the document to all the values. (The `[0..2]` notation indicates an array with three elements.)

```plaintext
firewallPrivateIPAddress.value
hub.value.networkSecurityGroupName
hub.value.networkSecurityGroupResourceId
hub.value.resourceGroupName
hub.value.resourceGroupResourceId
hub.value.subnetAddressPrefix
hub.value.subnetName
hub.value.subnetResourceId
hub.value.subscriptionId
hub.value.virtualNetworkName
hub.value.virtualNetworkResourceId
logAnalyticsWorkspaceName.value
logAnalyticsWorkspaceResourceId.value
mlzResourcePrefix.value
spokes.value[0..2].name
spokes.value[0..2].networkSecurityGroupName
spokes.value[0..2].networkSecurityGroupResourceId
spokes.value[0..2].resourceGroupId
spokes.value[0..2].resourceGroupName
spokes.value[0..2].subnetAddressPrefix
spokes.value[0..2].subnetName
spokes.value[0..2].subnetResourceId
spokes.value[0..2].subscriptionId
spokes.value[0..2].virtualNetworkName
spokes.value[0..2].virtualNetworkResourceId
deployPolicy.value
policyName.value
deployDefender.value
emailSecurityContact.value

