# Mission Landing Zone Bicep Template

This folder contains the Bicep template `mlz.bicep` for deploying Mission Landing Zone. See the [Deployment Guide for Bicep](../../docs/deployment-guide-bicep.md) for detailed instructions on how to use the template.

## Parameters

<!-- markdownlint-disable MD034 -->
Parameter name | Required | Description
-------------- | -------- | -----------
`azureGatewaySubnetAddressPrefix` | No | The CIDR Subnet Address Prefix for the Azure Gateway Subnet. It must be in the Hub Virtual Network space. It must be /26.
`bastionDiagnosticsLogs` | No | An array of Bastion Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/bastion/monitor-bastion#collect-data-with-azure-monitor.
`bastionHostPublicIPAddressAvailabilityZones` | No       | The Azure Bastion Public IP Address Availability Zones. It defaults to "No-Zone" because Availability Zones are not available in every cloud. See https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.
`bastionHostSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the Azure Bastion Subnet. It must be in the Hub Virtual Network space "hubVirtualNetworkAddressPrefix" parameter value. It must be /27 or larger.
`defenderSkuTier`    | No       | The SKU for Defender for Cloud. There are two options, Free and Standard. It defaults to "Free".
`deployAzureGatewaySubnet` | No | When set to "true", the AzureGatewaySubnet is added to the HUB virtual network. It defaults to "false".
`deployBastion`      | No       | When set to "true", provisions Azure Bastion Host using the Standard SKU. It defaults to "false".
`deployDefender`     | No       | When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".
`deployDefenderPlans`  | No       | The Paid Workload Protection plans for Defender for Cloud. It defaults to "VirtualMachines". See the following URL for valid settings: https://learn.microsoft.com/rest/api/defenderforcloud-composite/pricings/update?view=rest-defenderforcloud-composite-latest&tabs=HTTP.
`deployIdentity`       | No       | Choose to deploy the identity resources. The identity resoures are not required if you plan to use cloud identities.
`deployLinuxVirtualMachine` | No | When set to "true", provisions Linux Virtual Machine Host only. It defaults to "false".
`deploymentNameSuffix` | No       | A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.
`deployNetworkWatcherTrafficAnalytics` | No | When set to true, deploys Network Watcher Traffic Analytics. It defaults to "false".
`deployPolicy`   | No       | When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".
`deploySentinel` | No       | When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment. It defaults to "false".
`deployWindowsVirtualMachine` | No | When set to "true", provisions Windows Virtual Machine Host only. It defaults to "false".
`dnsServers` | No | The DNS servers set on either the virtual networks or the Azure Firewall DNS Proxy, depending on the selected Azure Firewall SKU. It defaults to the Azure virtual public IP address for DNS, ['168.63.129.16'].
`emailSecurityContact` | No       | The email address for Defender for Cloud alert notifications, in the form of john@contoso.com.
`enableProxy` | No | The Azure Firewall DNS Proxy will forward all DNS traffic. It defaults to "true".
`environmentAbbreviation` | No       | A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".
`firewallClientPublicIPAddressAvailabilityZones` | No       | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.
`firewallClientSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallDiagnosticsLogs` | No       | An array of Firewall Diagnostic Logs categories to collect. See "https://learn.microsoft.com/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.
`firewallDiagnosticsMetrics` | No       | An array of Firewall Diagnostic Metrics categories to collect. See "https://learn.microsoft.com/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.
`firewallIntrusionDetectionMode` | No       | [Alert/Deny/Off] The Azure Firewall Intrusion Detection mode. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".
`firewallManagementPublicIPAddressAvailabilityZones` | No       | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.
`firewallManagementSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallSkuTier` | No       | [Premium/Standard] The SKU for Azure Firewall. It defaults to "Premium".
`firewallSupernetIPAddress` | No       | Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses.
`firewallThreatIntelMode` | No       | [Alert/Deny/Off] The Azure Firewall Threat Intelligence Rule triggered logging behavior. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".
`hubNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. See https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`hubNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Metrics to apply to enable for the Hub Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`hubNetworkSecurityGroupRules` | No       | An array of Network Security Group Rules to apply to the Hub Virtual Network. See https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`hubSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.
`hubSubscriptionId` | No       | The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.
`hubVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.
`hubVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the Hub Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`hubVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`hybridUseBenefit` | No | The hybrid use benefit provides a discount on virtual machines when a customer has an on-premises Windows Server license with Software Assurance. It defaults to "false".
`identityNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. See https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`identityNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Metrics to apply to enable for the Identity Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`identityNetworkSecurityGroupRules` | No       | An array of Network Security Group Rules to apply to the Identity Virtual Network. See https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`identitySubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.
`identitySubscriptionId` | No       | The subscription ID for the Identity Network and resources. It defaults to the deployment subscription.
`identityVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Identity Virtual Network.
`identityVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the Identity Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`identityVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`keyVaultDiagnosticsLogs` | No | An array of Key Vault Diagnostic Logs categories to collect. See the following URL for valid settings: "https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault".
`linuxNetworkInterfacePrivateIPAddressAllocationMethod` | No       | [Static/Dynamic] The public IP Address allocation method for the Linux virtual machine. It defaults to "Dynamic".
`linuxVmAdminPasswordOrKey` | No       | The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See https://learn.microsoft.com/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.
`linuxVmAdminUsername` | No       | The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`linuxVmAuthenticationType` | No       | [sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".
`linuxVmImageOffer` | No       | The image offer of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "UbuntuServer".
`linuxVmImagePublisher` | No       | The image publisher of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Canonical".
`linuxVmImageSku` | No       | The image SKU of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "18.04-LTS".
`linuxVmOsDiskCreateOption` | No       | The disk creation option of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".
`linuxVmOsDiskType` | No       | The disk type of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_LRS".
`linuxVmSize`    | No       | The size of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_B2s".
`location` | No       | The region to deploy resources into. It defaults to the deployment location.
`logAnalyticsWorkspaceCappingDailyQuotaGb` | No       | The daily quota for Log Analytics Workspace logs in Gigabytes. It defaults to "-1" for no quota.
`logAnalyticsWorkspaceRetentionInDays` | No       | The number of days to retain Log Analytics Workspace logs. It defaults to "30".
`logAnalyticsWorkspaceSkuName` | No       | [Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://learn.microsoft.com/azure/azure-monitor/logs/resource-manager-workspace for valid settings.
`logStorageSkuName` | No       | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://learn.microsoft.com/rest/api/storagerp/srp_sku_types for valid settings.
`networkWatcherFlowLogsRetentionDays` | No | The number of days to retain Network Watcher Flow Logs. It defaults to "30".
`networkWatcherFlowLogsType` | No | The type of network watcher flow logs to enable. It defaults to "VirtualNetwork" since they provide more data and NSG flow logs will be deprecated in June 2025.
`networkWatcherResourceId` | No | The resource ID for an existing network watcher for the desired deployment location. Only one network watcher per location can exist in a subscription. The value can be left empty to create a new network watcher resource.
`operationsNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. See https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`operationsNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Diagnostic Metrics to enable for the Operations Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`operationsNetworkSecurityGroupRules` | No       | An array of Network Security Group rules to apply to the Operations Virtual Network. See https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`operationsSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.
`operationsSubscriptionId` | No       | The subscription ID for the Operations Network and resources. It defaults to the deployment subscription.
`operationsVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Operations Virtual Network.
`operationsVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`operationsVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`policy`         | No       | [NIST/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NIST". IL5 is only available for AzureUsGovernment and will switch to NIST if tried in AzureCloud.
`publicIPAddressDiagnosticsLogs` | No       | An array of Public IP Address Diagnostic Logs for the Azure Firewall. See https://learn.microsoft.com/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs for valid settings.
`publicIPAddressDiagnosticsMetrics` | No       | An array of Public IP Address Diagnostic Metrics for the Azure Firewall. See https://learn.microsoft.com/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications for valid settings.
`resourcePrefix` | Yes      | A prefix, 3-10 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces.
`sharedServicesNetworkSecurityGroupDiagnosticsLogs` | No       | An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. See https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.
`sharedServicesNetworkSecurityGroupDiagnosticsMetrics` | No       | An array of Network Security Group Diagnostic Metrics to enable for the SharedServices Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`sharedServicesNetworkSecurityGroupRules` | No       | An array of Network Security Group rules to apply to the SharedServices Virtual Network. See https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.
`sharedServicesSubnetAddressPrefix` | No       | The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.
`sharedServicesSubscriptionId` | No       | The subscription ID for the Shared Services Network and resources. It defaults to the deployment subscription.
`sharedServicesVirtualNetworkAddressPrefix` | No       | The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.
`sharedServicesVirtualNetworkDiagnosticsLogs` | No       | An array of Network Diagnostic Logs to enable for the SharedServices Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.
`sharedServicesVirtualNetworkDiagnosticsMetrics` | No       | An array of Network Diagnostic Metrics to enable for the SharedServices Virtual Network. See https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.
`supportedClouds` | No | The Azure clouds that support specific service features. It defaults to the Azure Cloud and Azure US Government.
`tags`           | No       | A string dictionary of tags to add to deployed resources. See https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.
`windowsVmAdminPassword` | No       | The administrator password the Windows Virtual Machine to Azure Bastion remote into. It must be > 12 characters in length. See https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.
`windowsVmAdminUsername` | No       | The administrator username for the Windows Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`windowsVmCreateOption` | No       | The disk creation option of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".
`windowsVmImageOffer` | No       | The offer of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "WindowsServer".
`windowsVmImagePublisher` | No       | The publisher of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "MicrosoftWindowsServer".
`windowsVmImageSku`   | No       | The SKU of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "2019-datacenter".
`windowsVmNetworkInterfacePrivateIPAddressAllocationMethod` | No       | [Static/Dynamic] The public IP Address allocation method for the Windows virtual machine. It defaults to "Dynamic".
`windowsVmSize`  | No       | The size of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "Standard_DS1_v2".
`windowsVmStorageAccountType` | No       | The storage account type of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "StandardSSD_LRS".
`windowsVmVersion` | No       | The version of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "latest".
<!-- markdownlint-enable MD034 -->

## Outputs

You can use Azure CLI, PowerShell, or the Portal to retrieve the output values from a deployment. See the [Referencing Deployment Output section](../../docs/deployment-guide-bicep.md#reference-deployment-output) in the Deployment Guide for Bicep to create a deployment variables file. When the outputs are saved to a file, the following outputs will be provided with their values:

```plaintext
azureFirewallResourceId
diskEncryptionSetResourceId
hubVirtualNetworkResourceId
identitySubnetResourceId
locationProperties
logAnalyticsWorkspaceResourceId
privateLinkScopeResourceId
sharedServicesSubnetResourceId
tiers
```
