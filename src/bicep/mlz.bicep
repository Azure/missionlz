/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

/*

  PARAMETERS

  Here are all the parameters a user can override.

  These are the required parameters that Mission LZ does not provide a default for:
    - resourcePrefix

*/

// REQUIRED PARAMETERS

@minLength(3)
@maxLength(10)
@description('A prefix, 3-10 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string

@minLength(3)
@maxLength(6)
@description('A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourceSuffix string = 'mlz'

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param hubSubscriptionId string = subscription().subscriptionId

@description('The subscription ID for the Identity Network and resources. It defaults to the deployment subscription.')
param identitySubscriptionId string = subscription().subscriptionId

@description('The subscription ID for the Operations Network and resources. It defaults to the deployment subscription.')
param operationsSubscriptionId string = subscription().subscriptionId

@description('The subscription ID for the Shared Services Network and resources. It defaults to the deployment subscription.')
param sharedServicesSubscriptionId string = subscription().subscriptionId

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}

// NETWORK ADDRESS SPACE PARAMETERS

@description('The CIDR Virtual Network Address Prefix for the Hub Virtual Network.')
param hubVirtualNetworkAddressPrefix string = '10.0.100.0/24'

@description('The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.')
param hubSubnetAddressPrefix string = '10.0.100.128/27'

@description('The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param firewallClientSubnetAddressPrefix string = '10.0.100.0/26'

@description('The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param firewallManagementSubnetAddressPrefix string = '10.0.100.64/26'

@description('The CIDR Virtual Network Address Prefix for the Identity Virtual Network.')
param identityVirtualNetworkAddressPrefix string = '10.0.110.0/26'

@description('The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.')
param identitySubnetAddressPrefix string = '10.0.110.0/27'

@description('The CIDR Virtual Network Address Prefix for the Operations Virtual Network.')
param operationsVirtualNetworkAddressPrefix string = '10.0.115.0/26'

@description('The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.')
param operationsSubnetAddressPrefix string = '10.0.115.0/27'

@description('The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.')
param sharedServicesVirtualNetworkAddressPrefix string = '10.0.120.0/26'

@description('The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.')
param sharedServicesSubnetAddressPrefix string = '10.0.120.0/27'

// FIREWALL PARAMETERS

@allowed([
  'Standard'
  'Premium'
])
@description('[Standard/Premium] The SKU for Azure Firewall. It defaults to "Premium".')
param firewallSkuTier string = 'Premium'

@allowed([
  'Alert'
  'Deny'
  'Off'
])
@description('[Alert/Deny/Off] The Azure Firewall Threat Intelligence Rule triggered logging behavior. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".')
param firewallThreatIntelMode string = 'Alert'

@allowed([
  'Alert'
  'Deny'
  'Off'
])
@description('[Alert/Deny/Off] The Azure Firewall Intrusion Detection mode. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".')
param firewallIntrusionDetectionMode string = 'Alert'

@description('An array of Firewall Diagnostic Logs categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.')
param firewallDiagnosticsLogs array = [
  {
    category: 'AzureFirewallApplicationRule'
    enabled: true
  }
  {
    category: 'AzureFirewallNetworkRule'
    enabled: true
  }
  {
    category: 'AzureFirewallDnsProxy'
    enabled: true
  }
]

@description('An array of Firewall Diagnostic Metrics categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.')
param firewallDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('An array of Service Endpoints to enable for the Azure Firewall Client Subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param firewallClientSubnetServiceEndpoints array = []

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param firewallClientPublicIPAddressAvailabilityZones array = []

@description('An array of Service Endpoints to enable for the Azure Firewall Management Subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param firewallManagementSubnetServiceEndpoints array = []

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param firewallManagementPublicIPAddressAvailabilityZones array = []

@description('Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses')
param firewallSupernetIPAddress string = '10.0.96.0/19'

@description('An array of Public IP Address Diagnostic Logs for the Azure Firewall. See https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs for valid settings.')
param publicIPAddressDiagnosticsLogs array = [
  {
    category: 'DDoSProtectionNotifications'
    enabled: true
  }
  {
    category: 'DDoSMitigationFlowLogs'
    enabled: true
  }
  {
    category: 'DDoSMitigationReports'
    enabled: true
  }
]

@description('An array of Public IP Address Diagnostic Metrics for the Azure Firewall. See https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications for valid settings.')
param publicIPAddressDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// HUB NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param hubVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param hubVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group Rules to apply to the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param hubNetworkSecurityGroupRules array = []

@description('An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param hubNetworkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

@description('An array of Network Security Group Metrics to apply to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param hubNetworkSecurityGroupDiagnosticsMetrics array = []

@description('An array of Service Endpoints to enable for the Hub subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param hubSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// IDENTITY PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param identityVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param identityVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group Rules to apply to the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param identityNetworkSecurityGroupRules array = [
  {
    name: 'Allow-Traffic-From-Spokes'
    properties: {
      access: 'Allow'
      description: 'Allow traffic from spokes'
      destinationAddressPrefix: identityVirtualNetworkAddressPrefix
      destinationPortRanges: [
        '22'
        '80'
        '443'
        '3389'
      ]
      direction: 'Inbound'
      priority: 200
      protocol: '*'
      sourceAddressPrefixes: [
        operationsVirtualNetworkAddressPrefix
        sharedServicesVirtualNetworkAddressPrefix
      ]
      sourcePortRange: '*'
    }
    type: 'string'
  }
]

@description('An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param identityNetworkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

@description('An array of Network Security Group Metrics to apply to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param identityNetworkSecurityGroupDiagnosticsMetrics array = []

@description('An array of Service Endpoints to enable for the Identity subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param identitySubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// OPERATIONS PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param operationsVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param operationsVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param operationsNetworkSecurityGroupRules array = [
  {
  name: 'Allow-Traffic-From-Spokes'
  properties: {
    access: 'Allow'
    description: 'Allow traffic from spokes'
    destinationAddressPrefix: operationsVirtualNetworkAddressPrefix
    destinationPortRanges: [
      '22'
      '80'
      '443'
      '3389'
    ]
    direction: 'Inbound'
    priority: 200
    protocol: '*'
    sourceAddressPrefixes: [
      identityVirtualNetworkAddressPrefix
      sharedServicesVirtualNetworkAddressPrefix
    ]
    sourcePortRange: '*'
  }
  type: 'string'
}
]

@description('An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param operationsNetworkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

@description('An array of Network Security Group Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param operationsNetworkSecurityGroupDiagnosticsMetrics array = []

@description('An array of Service Endpoints to enable for the Operations subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param operationsSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// SHARED SERVICES PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param sharedServicesVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param sharedServicesVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param sharedServicesNetworkSecurityGroupRules array = [
  {
    name: 'Allow-Traffic-From-Spokes'
    properties: {
      access: 'Allow'
      description: 'Allow traffic from spokes'
      destinationAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
      destinationPortRanges: [
        '22'
        '80'
        '443'
        '3389'
      ]
      direction: 'Inbound'
      priority: 200
      protocol: '*'
      sourceAddressPrefixes: [
        operationsVirtualNetworkAddressPrefix
        identityVirtualNetworkAddressPrefix
      ]
      sourcePortRange: '*'
    }
    type: 'string'
  }
]

@description('An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param sharedServicesNetworkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

@description('An array of Network Security Group Diagnostic Metrics to enable for the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param sharedServicesNetworkSecurityGroupDiagnosticsMetrics array = []

@description('An array of Service Endpoints to enable for the SharedServices subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param sharedServicesSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// LOGGING PARAMETERS

@description('When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment. It defaults to "false".')
param deploySentinel bool = false

@description('The daily quota for Log Analytics Workspace logs in Gigabytes. It defaults to "-1" for no quota.')
param logAnalyticsWorkspaceCappingDailyQuotaGb int = -1

@description('The number of days to retain Log Analytics Workspace logs. It defaults to "30".')
param logAnalyticsWorkspaceRetentionInDays int = 30

@allowed([
  'Free'
  'Standard'
  'Premium'
  'PerNode'
  'PerGB2018'
  'Standalone'
])
@description('[Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/resource-manager-workspace for valid settings.')
param logAnalyticsWorkspaceSkuName string = 'PerGB2018'

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param logStorageSkuName string = 'Standard_GRS'

// REMOTE ACCESS PARAMETERS

@description('When set to "true", provisions Azure Bastion Host and virtual machine jumpboxes. It defaults to "false".')
param deployRemoteAccess bool = false

@description('The CIDR Subnet Address Prefix for the Azure Bastion Subnet. It must be in the Hub Virtual Network space "hubVirtualNetworkAddressPrefix" parameter value. It must be /27 or larger.')
param bastionHostSubnetAddressPrefix string = '10.0.100.160/27'

@description('The Azure Bastion Public IP Address Availability Zones. It defaults to "No-Zone" because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param bastionHostPublicIPAddressAvailabilityZones array = []

// LINUX VIRTUAL MACHINE PARAMETERS

@description('The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".')
param linuxVmAdminUsername string = 'azureuser'

@allowed([
  'sshPublicKey'
  'password'
])
@description('[sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".')
param linuxVmAuthenticationType string = 'password'

@description('The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.')
@secure()
@minLength(12)
param linuxVmAdminPasswordOrKey string = deployRemoteAccess ? '' : newGuid()

@description('The size of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_B2s".')
param linuxVmSize string = 'Standard_B2s'

@description('The disk creation option of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".')
param linuxVmOsDiskCreateOption string = 'FromImage'

@description('The disk type of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_LRS".')
param linuxVmOsDiskType string = 'Standard_LRS'

@description('The image publisher of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Canonical".')
param linuxVmImagePublisher string = 'Canonical'

@description('The image offer of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "UbuntuServer".')
param linuxVmImageOffer string = 'UbuntuServer'

@description('The image SKU of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "18.04-LTS".')
param linuxVmImageSku string = '18.04-LTS'

@description('The image version of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "latest".')
param linuxVmImageVersion string = 'latest'

@allowed([
  'Static'
  'Dynamic'
])
@description('[Static/Dynamic] The public IP Address allocation method for the Linux virtual machine. It defaults to "Dynamic".')
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

// WINDOWS VIRTUAL MACHINE PARAMETERS

@description('The administrator username for the Windows Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".')
param windowsVmAdminUsername string = 'azureuser'

@description('The administrator password the Windows Virtual Machine to Azure Bastion remote into. It must be > 12 characters in length. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm- for password requirements.')
@secure()
@minLength(12)
param windowsVmAdminPassword string = deployRemoteAccess ? '' : newGuid()

@description('The size of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "Standard_DS1_v2".')
param windowsVmSize string = 'Standard_DS1_v2'

@description('The publisher of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "MicrosoftWindowsServer".')
param windowsVmPublisher string = 'MicrosoftWindowsServer'

@description('The offer of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "WindowsServer".')
param windowsVmOffer string = 'WindowsServer'

@description('The SKU of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "2019-datacenter".')
param windowsVmSku string = '2019-datacenter'

@description('The version of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "latest".')
param windowsVmVersion string = 'latest'

@description('The disk creation option of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".')
param windowsVmCreateOption string = 'FromImage'

@description('The storage account type of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "StandardSSD_LRS".')
param windowsVmStorageAccountType string = 'StandardSSD_LRS'

@allowed([
  'Static'
  'Dynamic'
])
@description('[Static/Dynamic] The public IP Address allocation method for the Windows virtual machine. It defaults to "Dynamic".')
param windowsNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

// POLICY PARAMETERS

@description('When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".')
param deployPolicy bool = false

@allowed([
  'NIST'
  'IL5' // AzureUsGoverment only, trying to deploy IL5 in AzureCloud will switch to NIST
  'CMMC'
])
@description('[NIST/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NIST". IL5 is only available for AzureUsGovernment and will switch to NIST if tried in AzureCloud.')
param policy string = 'NIST'

// MICROSOFT DEFENDER PARAMETERS

@description('When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".')
param deployDefender bool = false

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string = ''

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `resourceSuffix` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

*/

var resourceToken = 'resource_token'
var nameToken = 'name_token'
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'

/*

  CALCULATED VALUES

  Here we reference the naming conventions described above,
  then use the "replace()" function to insert unique resource abbreviations and name values into the naming convention.

  `storageAccountNamingConvention` is a unique naming convention:
    
    In an effort to reduce the likelihood of naming collisions, 
    we replace `unique_storage_token` with a uniqueString() calculated by resourcePrefix, resourceSuffix, and the subscription ID

*/

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var bastionHostNamingConvention = replace(namingConvention, resourceToken, 'bas')
var firewallNamingConvention = replace(namingConvention, resourceToken, 'afw')
var firewallPolicyNamingConvention = replace(namingConvention, resourceToken, 'afwp')
var ipConfigurationNamingConvention = replace(namingConvention, resourceToken, 'ipconf')
var logAnalyticsWorkspaceNamingConvention = replace(namingConvention, resourceToken, 'log')
var networkInterfaceNamingConvention = replace(namingConvention, resourceToken, 'nic')
var networkSecurityGroupNamingConvention = replace(namingConvention, resourceToken, 'nsg')
var publicIpAddressNamingConvention = replace(namingConvention, resourceToken, 'pip')
var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
var storageAccountNamingConvention = toLower('${resourcePrefix}st${nameToken}unique_storage_token')
var subnetNamingConvention = replace(namingConvention, resourceToken, 'snet')
var virtualMachineNamingConvention = replace(namingConvention, resourceToken, 'vm')
var virtualNetworkNamingConvention = replace(namingConvention, resourceToken, 'vnet')

// HUB NAMES

var hubName = 'hub'
var hubShortName = 'hub'
var hubResourceGroupName = replace(resourceGroupNamingConvention, nameToken, hubName)
var hubLogStorageAccountShortName = replace(storageAccountNamingConvention, nameToken, hubShortName)
var hubLogStorageAccountUniqueName = replace(hubLogStorageAccountShortName, 'unique_storage_token', uniqueString(resourcePrefix, resourceSuffix, hubSubscriptionId))
var hubLogStorageAccountName = take(hubLogStorageAccountUniqueName, 23)
var hubVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, hubName)
var hubNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, nameToken, hubName)
var hubSubnetName = replace(subnetNamingConvention, nameToken, hubName)

// IDENTITY NAMES

var identityName = 'identity'
var identityShortName = 'id'
var identityResourceGroupName = replace(resourceGroupNamingConvention, nameToken, identityName)
var identityLogStorageAccountShortName = replace(storageAccountNamingConvention, nameToken, identityShortName)
var identityLogStorageAccountUniqueName = replace(identityLogStorageAccountShortName, 'unique_storage_token', uniqueString(resourcePrefix, resourceSuffix, identitySubscriptionId))
var identityLogStorageAccountName = take(identityLogStorageAccountUniqueName, 23)
var identityVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, identityName)
var identityNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, nameToken, identityName)
var identitySubnetName = replace(subnetNamingConvention, nameToken, identityName)

// OPERATIONS NAMES

var operationsName = 'operations'
var operationsShortName = 'ops'
var operationsResourceGroupName = replace(resourceGroupNamingConvention, nameToken, operationsName)
var operationsLogStorageAccountShortName = replace(storageAccountNamingConvention, nameToken, operationsShortName)
var operationsLogStorageAccountUniqueName = replace(operationsLogStorageAccountShortName, 'unique_storage_token', uniqueString(resourcePrefix, resourceSuffix, operationsSubscriptionId))
var operationsLogStorageAccountName = take(operationsLogStorageAccountUniqueName, 23)
var operationsVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, operationsName)
var operationsNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, nameToken, operationsName)
var operationsSubnetName = replace(subnetNamingConvention, nameToken, operationsName)

// SHARED SERVICES NAMES

var sharedServicesName = 'sharedServices'
var sharedServicesShortName = 'svcs'
var sharedServicesResourceGroupName = replace(resourceGroupNamingConvention, nameToken, sharedServicesName)
var sharedServicesLogStorageAccountShortName = replace(storageAccountNamingConvention, nameToken, sharedServicesShortName)
var sharedServicesLogStorageAccountUniqueName = replace(sharedServicesLogStorageAccountShortName, 'unique_storage_token', uniqueString(resourcePrefix, resourceSuffix, sharedServicesSubscriptionId))
var sharedServicesLogStorageAccountName = take(sharedServicesLogStorageAccountUniqueName, 23)
var sharedServicesVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, sharedServicesName)
var sharedServicesNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, nameToken, sharedServicesName)
var sharedServicesSubnetName = replace(subnetNamingConvention, nameToken, sharedServicesName)

// LOG ANALYTICS NAMES

var logAnalyticsWorkspaceName = replace(logAnalyticsWorkspaceNamingConvention, nameToken, operationsName)

// FIREWALL NAMES

var firewallName = replace(firewallNamingConvention, nameToken, hubName)
var firewallPolicyName = replace(firewallPolicyNamingConvention, nameToken, hubName)
var firewallClientIpConfigurationName = replace(ipConfigurationNamingConvention, nameToken, 'afw-client')
var firewallClientPublicIPAddressName = replace(publicIpAddressNamingConvention, nameToken, 'afw-client')
var firewallManagementIpConfigurationName = replace(ipConfigurationNamingConvention, nameToken, 'afw-mgmt')
var firewallManagementPublicIPAddressName = replace(publicIpAddressNamingConvention, nameToken, 'afw-mgmt')

// FIREWALL VALUES

var firewallPublicIpAddressSkuName = 'Standard'
var firewallPublicIpAddressAllocationMethod = 'Static'

// BASTION NAMES

var bastionHostName = replace(bastionHostNamingConvention, nameToken, hubName)
var bastionHostPublicIPAddressName = replace(publicIpAddressNamingConvention, nameToken, 'bas')
var bastionHostIPConfigurationName = replace(ipConfigurationNamingConvention, nameToken, 'bas')
var linuxNetworkInterfaceName = replace(networkInterfaceNamingConvention, nameToken, 'bas-linux')
var linuxNetworkInterfaceIpConfigurationName = replace(ipConfigurationNamingConvention, nameToken, 'bas-linux')
var linuxVmName = replace(virtualMachineNamingConvention, nameToken, 'bas-linux')
var windowsNetworkInterfaceName = replace(networkInterfaceNamingConvention, nameToken, 'bas-windows')
var windowsNetworkInterfaceIpConfigurationName = replace(ipConfigurationNamingConvention, nameToken, 'bas-windows')
var windowsVmName = replace(virtualMachineNamingConvention, nameToken, 'bas-windows')

// BASTION VALUES

var bastionHostPublicIPAddressSkuName = 'Standard'
var bastionHostPublicIPAddressAllocationMethod = 'Static'

// SPOKES

var spokes = [
  {
    name: identityName
    subscriptionId: identitySubscriptionId
    resourceGroupName: identityResourceGroupName
    logStorageAccountName: identityLogStorageAccountName
    virtualNetworkName: identityVirtualNetworkName
    virtualNetworkAddressPrefix: identityVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: identityVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: identityVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: identityNetworkSecurityGroupName
    networkSecurityGroupRules: identityNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: identityNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: identityNetworkSecurityGroupDiagnosticsMetrics
    subnetName: identitySubnetName
    subnetAddressPrefix: identitySubnetAddressPrefix
    subnetServiceEndpoints: identitySubnetServiceEndpoints
  }
  {
    name: operationsName
    subscriptionId: operationsSubscriptionId
    resourceGroupName: operationsResourceGroupName
    logStorageAccountName: operationsLogStorageAccountName
    virtualNetworkName: operationsVirtualNetworkName
    virtualNetworkAddressPrefix: operationsVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: operationsVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: operationsVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: operationsNetworkSecurityGroupName
    networkSecurityGroupRules: operationsNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: operationsNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: operationsNetworkSecurityGroupDiagnosticsMetrics
    subnetName: operationsSubnetName
    subnetAddressPrefix: operationsSubnetAddressPrefix
    subnetServiceEndpoints: operationsSubnetServiceEndpoints
  }
  {
    name: sharedServicesName
    subscriptionId: sharedServicesSubscriptionId
    resourceGroupName: sharedServicesResourceGroupName
    logStorageAccountName: sharedServicesLogStorageAccountName
    virtualNetworkName: sharedServicesVirtualNetworkName
    virtualNetworkAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: sharedServicesNetworkSecurityGroupName
    networkSecurityGroupRules: sharedServicesNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: sharedServicesNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: sharedServicesNetworkSecurityGroupDiagnosticsMetrics
    subnetName: sharedServicesSubnetName
    subnetAddressPrefix: sharedServicesSubnetAddressPrefix
    subnetServiceEndpoints: sharedServicesSubnetServiceEndpoints
  }
]

// TAGS

var defaultTags = {
  'resourcePrefix': resourcePrefix
  'resourceSuffix': resourceSuffix
  'DeploymentType': 'MissionLandingZoneARM'
}

var calculatedTags = union(tags, defaultTags)

/*

  RESOURCES

  Here we create deployable resources.

*/

// RESOURCE GROUPS

module hubResourceGroup './modules/resource-group.bicep' = {
  name: 'deploy-rg-hub-${deploymentNameSuffix}'
  scope: subscription(hubSubscriptionId)
  params: {
    name: hubResourceGroupName
    location: location
    tags: calculatedTags
  }
}

module spokeResourceGroups './modules/resource-group.bicep' = [for spoke in spokes: {
  name: 'deploy-rg-${spoke.name}-${deploymentNameSuffix}'
  scope: subscription(spoke.subscriptionId)
  params: {
    name: spoke.resourceGroupName
    location: location
    tags: calculatedTags
  }
}]

// LOG ANALYTICS WORKSPACE

module logAnalyticsWorkspace './modules/log-analytics-workspace.bicep' = {
  name: 'deploy-laws-${deploymentNameSuffix}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: calculatedTags
    deploySentinel: deploySentinel
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
  dependsOn: [
    spokeResourceGroups
  ]
}

// HUB AND SPOKE NETWORKS

module hubNetwork './core/hub-network.bicep' = {
  name: 'deploy-vnet-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    location: location
    tags: calculatedTags

    logStorageAccountName: hubLogStorageAccountName
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    virtualNetworkName: hubVirtualNetworkName
    virtualNetworkAddressPrefix: hubVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: hubVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: hubVirtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: hubNetworkSecurityGroupName
    networkSecurityGroupRules: hubNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: hubNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: hubNetworkSecurityGroupDiagnosticsMetrics

    subnetName: hubSubnetName
    subnetAddressPrefix: hubSubnetAddressPrefix
    subnetServiceEndpoints: hubSubnetServiceEndpoints

    firewallName: firewallName
    firewallSkuTier: firewallSkuTier
    firewallPolicyName: firewallPolicyName
    firewallThreatIntelMode: firewallThreatIntelMode
    firewallIntrusionDetectionMode: firewallIntrusionDetectionMode
    firewallDiagnosticsLogs: firewallDiagnosticsLogs
    firewallDiagnosticsMetrics: firewallDiagnosticsMetrics
    firewallClientIpConfigurationName: firewallClientIpConfigurationName
    firewallClientSubnetName: 'AzureFirewallSubnet' // this must be 'AzureFirewallSubnet'
    firewallClientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
    firewallClientSubnetServiceEndpoints: firewallClientSubnetServiceEndpoints
    firewallClientPublicIPAddressName: firewallClientPublicIPAddressName
    firewallClientPublicIPAddressSkuName: firewallPublicIpAddressSkuName
    firewallClientPublicIpAllocationMethod: firewallPublicIpAddressAllocationMethod
    firewallClientPublicIPAddressAvailabilityZones: firewallClientPublicIPAddressAvailabilityZones
    firewallManagementIpConfigurationName: firewallManagementIpConfigurationName
    firewallManagementSubnetName: 'AzureFirewallManagementSubnet' // this must be 'AzureFirewallManagementSubnet'
    firewallManagementSubnetAddressPrefix: firewallManagementSubnetAddressPrefix
    firewallManagementSubnetServiceEndpoints: firewallManagementSubnetServiceEndpoints
    firewallManagementPublicIPAddressName: firewallManagementPublicIPAddressName
    firewallManagementPublicIPAddressSkuName: firewallPublicIpAddressSkuName
    firewallManagementPublicIpAllocationMethod: firewallPublicIpAddressAllocationMethod
    firewallManagementPublicIPAddressAvailabilityZones: firewallManagementPublicIPAddressAvailabilityZones
    firewallSupernetIPAddress: firewallSupernetIPAddress

    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
  }
}

module spokeNetworks './core/spoke-network.bicep' = [for spoke in spokes: {
  name: 'deploy-vnet-${spoke.name}-${deploymentNameSuffix}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    location: location
    tags: calculatedTags

    logStorageAccountName: spoke.logStorageAccountName
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    firewallPrivateIPAddress: hubNetwork.outputs.firewallPrivateIPAddress

    virtualNetworkName: spoke.virtualNetworkName
    virtualNetworkAddressPrefix: spoke.virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: spoke.virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: spoke.virtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: spoke.networkSecurityGroupName
    networkSecurityGroupRules: spoke.networkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: spoke.networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: spoke.networkSecurityGroupDiagnosticsMetrics

    subnetName: spoke.subnetName
    subnetAddressPrefix: spoke.subnetAddressPrefix
    subnetServiceEndpoints: spoke.subnetServiceEndpoints
  }
}]

// VIRTUAL NETWORK PEERINGS

module hubVirtualNetworkPeerings './core/hub-network-peerings.bicep' = {
  name: 'deploy-vnet-peerings-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    spokes: [for (spoke, i) in spokes: {
      type: spoke.name
      virtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
      virtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
    }]
  }
}

module spokeVirtualNetworkPeerings './core/spoke-network-peering.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-${spoke.name}-${deploymentNameSuffix}'
  scope: subscription(spoke.subscriptionId)
  params: {
    spokeName: spoke.name
    spokeResourceGroupName: spoke.resourceGroupName
    spokeVirtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
  }
}]

// POLICY ASSIGNMENTS

module hubPolicyAssignment './modules/policy-assignment.bicep' = if (deployPolicy) {
  name: 'assign-policy-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspace.outputs.resourceGroupName
    operationsSubscriptionId: operationsSubscriptionId
    location: location
  }
}

module spokePolicyAssignments './modules/policy-assignment.bicep' = [for spoke in spokes: if (deployPolicy) {
  name: 'assign-policy-${spoke.name}-${deploymentNameSuffix}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspace.outputs.resourceGroupName
    operationsSubscriptionId: operationsSubscriptionId
    location: location
  }
}]

// CENTRAL LOGGING

module hubSubscriptionActivityLogging './modules/central-logging.bicep' = {
  name: 'activity-logs-hub-${deploymentNameSuffix}'
  scope: subscription(hubSubscriptionId)
  params: {
    diagnosticSettingName: 'log-hub-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
  dependsOn: [
    hubNetwork
  ]
}

module spokeSubscriptionActivityLogging './modules/central-logging.bicep' = [for spoke in spokes: if (spoke.subscriptionId != hubSubscriptionId) {
  name: 'activity-logs-${spoke.name}-${deploymentNameSuffix}'
  scope: subscription(spoke.subscriptionId)
  params: {
    diagnosticSettingName: 'log-${spoke.name}-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
  dependsOn: [
    spokeNetworks
  ]
}]

module logAnalyticsDiagnosticLogging './modules/log-analytics-diagnostic-logging.bicep' = {
  name: 'deploy-diagnostic-logging-${deploymentNameSuffix}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    diagnosticStorageAccountName: operationsLogStorageAccountName
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
  dependsOn: [
    hubNetwork
    spokeNetworks
  ]
}

// Microsoft Defender for Cloud

module hubDefender './modules/defender.bicep' = if (deployDefender) {
  name: 'set-hub-sub-defender-${deploymentNameSuffix}'
  scope: subscription(hubSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    emailSecurityContact: emailSecurityContact
  }
}

module spokeDefender './modules/defender.bicep' = [for spoke in spokes: if ((deployDefender) && (spoke.subscriptionId != hubSubscriptionId)) {
  name: 'set-${spoke.name}-sub-defender'
  scope: subscription(spoke.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    emailSecurityContact: emailSecurityContact
  }
}]

// REMOTE ACCESS

module remoteAccess './core/remote-access.bicep' = if (deployRemoteAccess) {
  name: 'deploy-remote-access-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)

  params: {
    location: location

    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubSubnetResourceId: hubNetwork.outputs.subnetResourceId
    hubNetworkSecurityGroupResourceId: hubNetwork.outputs.networkSecurityGroupResourceId

    bastionHostName: bastionHostName
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    bastionHostPublicIPAddressName: bastionHostPublicIPAddressName
    bastionHostPublicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    bastionHostPublicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    bastionHostPublicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    bastionHostIPConfigurationName: bastionHostIPConfigurationName

    linuxNetworkInterfaceName: linuxNetworkInterfaceName
    linuxNetworkInterfaceIpConfigurationName: linuxNetworkInterfaceIpConfigurationName
    linuxNetworkInterfacePrivateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod

    linuxVmName: linuxVmName
    linuxVmSize: linuxVmSize
    linuxVmOsDiskCreateOption: linuxVmOsDiskCreateOption
    linuxVmOsDiskType: linuxVmOsDiskType
    linuxVmImagePublisher: linuxVmImagePublisher
    linuxVmImageOffer: linuxVmImageOffer
    linuxVmImageSku: linuxVmImageSku
    linuxVmImageVersion: linuxVmImageVersion
    linuxVmAdminUsername: linuxVmAdminUsername
    linuxVmAuthenticationType: linuxVmAuthenticationType
    linuxVmAdminPasswordOrKey: linuxVmAdminPasswordOrKey

    windowsNetworkInterfaceName: windowsNetworkInterfaceName
    windowsNetworkInterfaceIpConfigurationName: windowsNetworkInterfaceIpConfigurationName
    windowsNetworkInterfacePrivateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod

    windowsVmName: windowsVmName
    windowsVmSize: windowsVmSize
    windowsVmAdminUsername: windowsVmAdminUsername
    windowsVmAdminPassword: windowsVmAdminPassword
    windowsVmPublisher: windowsVmPublisher
    windowsVmOffer: windowsVmOffer
    windowsVmSku: windowsVmSku
    windowsVmVersion: windowsVmVersion
    windowsVmCreateOption: windowsVmCreateOption
    windowsVmStorageAccountType: windowsVmStorageAccountType

    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

/*

  OUTPUTS

  Here, we emit objects to be used post-deployment.
  
  A user can reference these outputs with the `az deployment sub show` command like this:

    az deployment sub show --name <your deployment name> --query properties.outputs

  With that output as JSON you could pass it as arguments to another deployment using the Shared Variable File Pattern:
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file
  
  The output is a JSON object, you can use your favorite tool, like PowerShell or jq, to parse the values you need.

*/

output mlzResourcePrefix string = resourcePrefix

output firewallPrivateIPAddress string = hubNetwork.outputs.firewallPrivateIPAddress

output hub object = {
  subscriptionId: hubSubscriptionId
  resourceGroupName: hubResourceGroup.outputs.name
  resourceGroupResourceId: hubResourceGroup.outputs.id
  virtualNetworkName: hubNetwork.outputs.virtualNetworkName
  virtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
  subnetName: hubNetwork.outputs.subnetName
  subnetResourceId: hubNetwork.outputs.subnetResourceId
  subnetAddressPrefix: hubNetwork.outputs.subnetAddressPrefix
  networkSecurityGroupName: hubNetwork.outputs.networkSecurityGroupName
  networkSecurityGroupResourceId: hubNetwork.outputs.networkSecurityGroupResourceId
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.id

output diagnosticStorageAccountName string = operationsLogStorageAccountName

output spokes array = [for (spoke, i) in spokes: {
  name: spoke.name
  subscriptionId: spoke.subscriptionId
  resourceGroupName: spokeResourceGroups[i].outputs.name
  resourceGroupId: spokeResourceGroups[i].outputs.id
  virtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
  virtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
  subnetName: spokeNetworks[i].outputs.subnetName
  subnetResourceId: spokeNetworks[i].outputs.subnetResourceId
  subnetAddressPrefix: spokeNetworks[i].outputs.subnetAddressPrefix
  networkSecurityGroupName: spokeNetworks[i].outputs.networkSecurityGroupName
  networkSecurityGroupResourceId: spokeNetworks[i].outputs.networkSecurityGroupResourceId
}]
