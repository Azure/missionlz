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
@maxLength(6)
@description('A prefix, 3-6 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string

@allowed([
  'dev'
  'prod'
  'test'
])
@description('The abbreviation for the environment.')
param environmentAbbreviation string = 'dev'

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

@description('Supported Azure Clouds array. It defaults to the Public cloud and the Azure US Government cloud.')
param supportedClouds array = [
  'AzureCloud'
  'AzureUSGovernment'
]

@description('Choose to deploy the identity resources. The identity resoures are not required if you plan to use cloud identities.')
param deployIdentity bool

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}

// NETWORK ADDRESS SPACE PARAMETERS

@description('The CIDR Virtual Network Address Prefix for the Hub Virtual Network.')
param hubVirtualNetworkAddressPrefix string = '10.0.128.0/23'

@description('The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.')
param hubSubnetAddressPrefix string = '10.0.128.128/26'

@description('The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param firewallClientSubnetAddressPrefix string = '10.0.128.0/26'

@description('The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param firewallManagementSubnetAddressPrefix string = '10.0.128.64/26'

@description('The CIDR Virtual Network Address Prefix for the Identity Virtual Network.')
param identityVirtualNetworkAddressPrefix string = '10.0.130.0/24'

@description('The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.')
param identitySubnetAddressPrefix string = '10.0.130.0/24'

@description('The CIDR Virtual Network Address Prefix for the Operations Virtual Network.')
param operationsVirtualNetworkAddressPrefix string = '10.0.131.0/24'

@description('The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.')
param operationsSubnetAddressPrefix string = '10.0.131.0/24'

@description('The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.')
param sharedServicesVirtualNetworkAddressPrefix string = '10.0.132.0/24'

@description('The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.')
param sharedServicesSubnetAddressPrefix string = '10.0.132.0/24'

// FIREWALL PARAMETERS

@allowed([
  'Standard'
  'Premium'
  'Basic'
])
@description('[Standard/Premium/Basic] The SKU for Azure Firewall. It defaults to "Premium". Selecting a value other than Premium is not recommended for environments that are required to be SCCA compliant.')
param firewallSkuTier string

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

@description('[true/false] The Azure Firewall DNS Proxy will forward all DNS traffic. When this value is set to true, you must provide a value for "servers"')
param enableProxy bool = true

@description('''['168.63.129.16'] The Azure Firewall DNS Proxy will forward all DNS traffic. When this value is set to true, you must provide a value for "servers". This should be a comma separated list of IP addresses to forward DNS traffic''')
param dnsServers array = [ '168.63.129.16' ]

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

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param firewallClientPublicIPAddressAvailabilityZones array = []

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param firewallManagementPublicIPAddressAvailabilityZones array = []

@description('Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses')
param firewallSupernetIPAddress string = '10.0.128.0/18'

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
param bastionHostSubnetAddressPrefix string = '10.0.128.192/26'

@description('The Azure Bastion Public IP Address Availability Zones. It defaults to "No-Zone" because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param bastionHostPublicIPAddressAvailabilityZones array = []

@description('The hybrid use benefit provides a discount on virtual machines when a customer has an on-premises Windows Server license with Software Assurance.')
param hybridUseBenefit bool = false

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
param linuxVmImageSku string = '18_04-lts-gen2'

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
param windowsVmSku string = '2019-datacenter-gensecond'

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
  'NISTRev4'
  'NISTRev5'
  'IL5' // AzureUsGoverment only, trying to deploy IL5 in AzureCloud will switch to NISTRev4
  'CMMC'
])
@description('[NISTRev4/NISTRev5/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NISTRev4". IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.')
param policy string = 'NISTRev4'

// MICROSOFT DEFENDER PARAMETERS

@description('When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".')
param deployDefender bool = false

@allowed([
  'Standard'
  'Free'
])
@description('[Standard/Free] The SKU for Defender. It defaults to "Standard".')
param defenderSkuTier string = 'Standard'

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string = ''

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `environmentAbbreviation` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

*/

var locations = (loadJsonContent('data/locations.json'))[environment().name]
var locationAbbreviation = locations[location].abbreviation
var resourceToken = 'resource_token'
var serviceToken = 'service_token'
var networkToken = 'network_token'
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${serviceToken}-${networkToken}-${environmentAbbreviation}-${locationAbbreviation}'

/*

  CALCULATED VALUES

  Here we reference the naming conventions described above,
  then use the "replace()" function to insert unique resource abbreviations and name values into the naming convention.

  `storageAccountNamingConvention` is a unique naming convention:
    
    In an effort to reduce the likelihood of naming collisions, 
    we replace `unique_token` with a uniqueString() calculated by resourcePrefix, environmentAbbreviation, and the subscription ID

*/

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var bastionHostNamingConvention = replace(namingConvention, resourceToken, 'bas')
var diskEncryptionSetNamingConvention = replace(namingConvention, resourceToken, 'des')
var diskNamingConvention = replace(namingConvention, resourceToken, 'disk')
var firewallNamingConvention = replace(namingConvention, resourceToken, 'afw')
var firewallPolicyNamingConvention = replace(namingConvention, resourceToken, 'afwp')
var ipConfigurationNamingConvention = replace(namingConvention, resourceToken, 'ipconf')
var keyVaultNamingConvention = '${replace(replace(namingConvention, resourceToken, 'kv'), '-', '')}unique_token'
var logAnalyticsWorkspaceNamingConvention = replace(namingConvention, resourceToken, 'log')
var networkInterfaceNamingConvention = replace(namingConvention, resourceToken, 'nic')
var networkSecurityGroupNamingConvention = replace(namingConvention, resourceToken, 'nsg')
var networkWatcherNamingConvention = replace(namingConvention, resourceToken, 'nw')
var privateEndpointNamingConvention = replace(namingConvention, resourceToken, 'pe')
var privateLinkScopeName = replace(namingConvention, resourceToken, 'pls')
var publicIpAddressNamingConvention = replace(namingConvention, resourceToken, 'pip')
var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
var routeTableNamingConvention = replace(namingConvention, resourceToken, 'rt')
var storageAccountNamingConvention = toLower('${replace(replace(namingConvention, resourceToken, 'st'), '-', '')}unique_token')
var subnetNamingConvention = replace(namingConvention, resourceToken, 'snet')
var userAssignedIdentityNamingConvention = replace(namingConvention, resourceToken, 'id')
var virtualMachineNamingConvention = replace(namingConvention, resourceToken, 'vm')
var virtualNetworkNamingConvention = replace(namingConvention, resourceToken, 'vnet')

// HUB NAMES

var hubName = 'hub'
var hubShortName = 'hub'
var hubDiskEncryptionSetName = replace(replace(diskEncryptionSetNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubKeyVaultName = take(hubKeyVaultUniqueName, 24)
var hubKeyVaultNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, 'kv'), networkToken, hubName)
var hubKeyVaultPrivateEndpointName = replace(replace(privateEndpointNamingConvention, serviceToken, 'kv'), networkToken, hubName)
var hubKeyVaultShortName = replace(replace(keyVaultNamingConvention, serviceToken, ''), networkToken, hubShortName)
var hubKeyVaultUniqueName = replace(hubKeyVaultShortName, 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, hubSubscriptionId))
var hubLogStorageAccountName = take(hubLogStorageAccountUniqueName, 24)
var hubLogStorageAccountNetworkInterfaceNamePrefix = replace(replace(networkInterfaceNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, hubName)
var hubLogStorageAccountPrivateEndpointNamePrefix = replace(replace(privateEndpointNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, hubName)
var hubLogStorageAccountShortName = replace(replace(storageAccountNamingConvention, serviceToken, ''), networkToken, hubShortName)
var hubLogStorageAccountUniqueName = replace(hubLogStorageAccountShortName, 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, hubSubscriptionId))
var hubNetworkWatcherName = replace(replace(networkWatcherNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubNetworkSecurityGroupName = replace(replace(networkSecurityGroupNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubResourceGroupName = replace(replace(resourceGroupNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubRouteTableName = replace(replace(routeTableNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubSubnetName = replace(replace(subnetNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubUserAssignedIdentityName = replace(replace(userAssignedIdentityNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var hubVirtualNetworkName = replace(replace(virtualNetworkNamingConvention, '-${serviceToken}', ''), networkToken, hubName)

// IDENTITY NAMES

var identityName = 'identity'
var identityShortName = 'id'
var identityLogStorageAccountName = take(identityLogStorageAccountUniqueName, 24)
var identityLogStorageAccountNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, identityName)
var identityLogStorageAccountPrivateEndpointName = replace(replace(privateEndpointNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, identityName)
var identityLogStorageAccountShortName = replace(replace(storageAccountNamingConvention, serviceToken, ''), networkToken, identityShortName)
var identityLogStorageAccountUniqueName = replace(identityLogStorageAccountShortName, 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, identitySubscriptionId))
var identityNetworkSecurityGroupName = replace(replace(networkSecurityGroupNamingConvention, '-${serviceToken}', ''), networkToken, identityName)
var identityNetworkWatcherName = replace(replace(networkWatcherNamingConvention, '-${serviceToken}', ''), networkToken, identityName)
var identityResourceGroupName = replace(replace(resourceGroupNamingConvention, '-${serviceToken}', ''), networkToken, identityName)
var identityRouteTableName = replace(replace(routeTableNamingConvention, '-${serviceToken}', ''), networkToken, identityName)
var identitySubnetName = replace(replace(subnetNamingConvention, '-${serviceToken}', ''), networkToken, identityName)
var identityVirtualNetworkName = replace(replace(virtualNetworkNamingConvention, '-${serviceToken}', ''), networkToken, identityName)

// OPERATIONS NAMES

var operationsName = 'operations'
var operationsShortName = 'ops'
var operationsLogStorageAccountName = take(operationsLogStorageAccountUniqueName, 24)
var operationsLogStorageAccountNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, operationsName)
var operationsLogStorageAccountPrivateEndpointName = replace(replace(privateEndpointNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, operationsName)
var operationsLogStorageAccountShortName = replace(replace(storageAccountNamingConvention, serviceToken, ''), networkToken, operationsShortName)
var operationsLogStorageAccountUniqueName = replace(operationsLogStorageAccountShortName, 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, operationsSubscriptionId))
var operationsNetworkSecurityGroupName = replace(replace(networkSecurityGroupNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)
var operationsNetworkWatcherName = replace(replace(networkWatcherNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)
var operationsPrivateLinkScopeName = replace(replace(privateLinkScopeName, '-${serviceToken}', ''), networkToken, operationsName)
var operationsPrivateLinkScopeNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, 'pls'), networkToken, operationsName)
var operationsPrivateLinkScopePrivateEndpointName = replace(replace(privateEndpointNamingConvention, serviceToken, 'pls'), networkToken, operationsName)
var operationsResourceGroupName = replace(replace(resourceGroupNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)
var operationsRouteTableName = replace(replace(routeTableNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)
var operationsSubnetName = replace(replace(subnetNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)
var operationsVirtualNetworkName = replace(replace(virtualNetworkNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)

// SHARED SERVICES NAMES

var sharedServicesName = 'sharedServices'
var sharedServicesShortName = 'svcs'
var sharedServicesLogStorageAccountName = take(sharedServicesLogStorageAccountUniqueName, 24)
var sharedServicesLogStorageAccountPrivateEndpointName = replace(replace(privateEndpointNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, sharedServicesName)
var sharedServicesLogStorageAccountNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, '${serviceToken}-st'), networkToken, sharedServicesName)
var sharedServicesLogStorageAccountShortName = replace(replace(storageAccountNamingConvention, serviceToken, ''), networkToken, sharedServicesShortName)
var sharedServicesLogStorageAccountUniqueName = replace(sharedServicesLogStorageAccountShortName, 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, sharedServicesSubscriptionId))
var sharedServicesNetworkSecurityGroupName = replace(replace(networkSecurityGroupNamingConvention, '-${serviceToken}', ''), networkToken, sharedServicesName)
var sharedServicesNetworkWatcherName = replace(replace(networkWatcherNamingConvention, '-${serviceToken}', ''), networkToken, sharedServicesName)
var sharedServicesResourceGroupName = replace(replace(resourceGroupNamingConvention, '-${serviceToken}', ''), networkToken, sharedServicesName)
var sharedServicesRouteTableName = replace(replace(routeTableNamingConvention, '-${serviceToken}', ''), networkToken, sharedServicesName)
var sharedServicesSubnetName = replace(replace(subnetNamingConvention, '-${serviceToken}', ''), networkToken, sharedServicesName)
var sharedServicesVirtualNetworkName = replace(replace(virtualNetworkNamingConvention, '-${serviceToken}', ''), networkToken, sharedServicesName)

// LOG ANALYTICS NAMES

var logAnalyticsWorkspaceName = replace(replace(logAnalyticsWorkspaceNamingConvention, '-${serviceToken}', ''), networkToken, operationsName)

// FIREWALL NAMES

var firewallName = replace(replace(firewallNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var firewallPolicyName = replace(replace(firewallPolicyNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var firewallClientIpConfigurationName = replace(replace(ipConfigurationNamingConvention, serviceToken, 'client-afw'), networkToken, hubName)
var firewallClientPublicIPAddressName = replace(replace(publicIpAddressNamingConvention, serviceToken, 'client-afw'), networkToken, hubName)
var firewallManagementIpConfigurationName = replace(replace(ipConfigurationNamingConvention, serviceToken, 'mgmt-afw'), networkToken, hubName)
var firewallManagementPublicIPAddressName = replace(replace(publicIpAddressNamingConvention, serviceToken, 'mgmt-afw'), networkToken, hubName)

// FIREWALL VALUES

var firewallClientUsableIpAddresses = [for i in range(0, 4): cidrHost(firewallClientSubnetAddressPrefix, i)]
var firewallClientPrivateIpAddress = firewallClientUsableIpAddresses[3]
var firewallPublicIpAddressSkuName = 'Standard'
var firewallPublicIpAddressAllocationMethod = 'Static'

// REMOTE ACCESS NAMES

var bastionHostName = replace(replace(bastionHostNamingConvention, '-${serviceToken}', ''), networkToken, hubName)
var bastionHostPublicIPAddressName = replace(replace(publicIpAddressNamingConvention, serviceToken, 'bas'), networkToken, hubName)
var bastionHostIPConfigurationName = replace(replace(ipConfigurationNamingConvention, serviceToken, 'bas'), networkToken, hubName)
var linuxDiskName = replace(replace(diskNamingConvention, serviceToken, 'linux'), networkToken, hubName)
var linuxNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, 'linux'), networkToken, hubName)
var linuxNetworkInterfaceIpConfigurationName = replace(replace(ipConfigurationNamingConvention, serviceToken, 'linux'), networkToken, hubName)
var linuxVmName = replace(replace(virtualMachineNamingConvention, serviceToken, 'linux'), networkToken, hubName)
var windowsDiskName = replace(replace(diskNamingConvention, serviceToken, 'windows'), networkToken, hubName)
var windowsNetworkInterfaceName = replace(replace(networkInterfaceNamingConvention, serviceToken, 'windows'), networkToken, hubName)
var windowsNetworkInterfaceIpConfigurationName = replace(replace(ipConfigurationNamingConvention, serviceToken, 'windows'), networkToken, hubName)
var windowsVmName = replace(replace(virtualMachineNamingConvention, serviceToken, 'windows'), networkToken, hubName)

// BASTION VALUES

var bastionHostPublicIPAddressSkuName = 'Standard'
var bastionHostPublicIPAddressAllocationMethod = 'Static'

// SPOKES

var spokes = union(spokesCommon, spokesIdentity)
var spokesCommon = [
  {
    name: operationsName
    subscriptionId: operationsSubscriptionId
    resourceGroupName: operationsResourceGroupName
    deployUniqueResources: contains([ hubSubscriptionId ], operationsSubscriptionId) ? false : true
    logStorageAccountName: operationsLogStorageAccountName
    logStorageAccountNetworkInterfaceNamePrefix: operationsLogStorageAccountNetworkInterfaceName
    logStorageAccountPrivateEndpointNamePrefix: operationsLogStorageAccountPrivateEndpointName
    virtualNetworkName: operationsVirtualNetworkName
    virtualNetworkAddressPrefix: operationsVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: operationsVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: operationsVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: operationsNetworkSecurityGroupName
    networkSecurityGroupRules: operationsNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: operationsNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: operationsNetworkSecurityGroupDiagnosticsMetrics
    networkWatcherName: operationsNetworkWatcherName
    routeTableName: operationsRouteTableName
    subnetName: operationsSubnetName
    subnetAddressPrefix: operationsSubnetAddressPrefix
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
  }
  {
    name: sharedServicesName
    subscriptionId: sharedServicesSubscriptionId
    resourceGroupName: sharedServicesResourceGroupName
    deployUniqueResources: contains([ hubSubscriptionId, operationsSubscriptionId ], sharedServicesSubscriptionId) ? false : true
    logStorageAccountName: sharedServicesLogStorageAccountName
    logStorageAccountNetworkInterfaceNamePrefix: sharedServicesLogStorageAccountNetworkInterfaceName
    logStorageAccountPrivateEndpointNamePrefix: sharedServicesLogStorageAccountPrivateEndpointName
    virtualNetworkName: sharedServicesVirtualNetworkName
    virtualNetworkAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: sharedServicesNetworkSecurityGroupName
    networkSecurityGroupRules: sharedServicesNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: sharedServicesNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: sharedServicesNetworkSecurityGroupDiagnosticsMetrics
    networkWatcherName: sharedServicesNetworkWatcherName
    routeTableName: sharedServicesRouteTableName
    subnetName: sharedServicesSubnetName
    subnetAddressPrefix: sharedServicesSubnetAddressPrefix
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
  }
]
var spokesIdentity = deployIdentity ? [
  {
    name: identityName
    subscriptionId: identitySubscriptionId
    resourceGroupName: identityResourceGroupName
    deployUniqueResources: contains([ hubSubscriptionId, operationsSubscriptionId, sharedServicesSubscriptionId ], identitySubscriptionId) ? false : true
    logStorageAccountName: identityLogStorageAccountName
    logStorageAccountNetworkInterfaceNamePrefix: identityLogStorageAccountNetworkInterfaceName
    logStorageAccountPrivateEndpointNamePrefix: identityLogStorageAccountPrivateEndpointName
    virtualNetworkName: identityVirtualNetworkName
    virtualNetworkAddressPrefix: identityVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: identityVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: identityVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: identityNetworkSecurityGroupName
    networkSecurityGroupRules: identityNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: identityNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: identityNetworkSecurityGroupDiagnosticsMetrics
    networkWatcherName: identityNetworkWatcherName
    routeTableName: identityRouteTableName
    subnetName: identitySubnetName
    subnetAddressPrefix: identitySubnetAddressPrefix
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
  }
] : []

// TAGS

var defaultTags = {
  resourcePrefix: resourcePrefix
  environmentAbbreviation: environmentAbbreviation
  DeploymentType: 'MissionLandingZoneARM'
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
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    deployRemoteAccess: deployRemoteAccess
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallClientIpConfigurationName: firewallClientIpConfigurationName
    firewallClientPrivateIpAddress: firewallClientPrivateIpAddress
    firewallClientPublicIPAddressAvailabilityZones: firewallClientPublicIPAddressAvailabilityZones
    firewallClientPublicIPAddressName: firewallClientPublicIPAddressName
    firewallClientPublicIPAddressSkuName: firewallPublicIpAddressSkuName
    firewallClientPublicIpAllocationMethod: firewallPublicIpAddressAllocationMethod
    firewallClientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
    firewallClientSubnetName: 'AzureFirewallSubnet' // this must be 'AzureFirewallSubnet'
    firewallIntrusionDetectionMode: firewallIntrusionDetectionMode
    firewallManagementIpConfigurationName: firewallManagementIpConfigurationName
    firewallManagementPublicIPAddressAvailabilityZones: firewallManagementPublicIPAddressAvailabilityZones
    firewallManagementPublicIPAddressName: firewallManagementPublicIPAddressName
    firewallManagementPublicIPAddressSkuName: firewallPublicIpAddressSkuName
    firewallManagementPublicIpAllocationMethod: firewallPublicIpAddressAllocationMethod
    firewallManagementSubnetAddressPrefix: firewallManagementSubnetAddressPrefix
    firewallManagementSubnetName: 'AzureFirewallManagementSubnet' // this must be 'AzureFirewallManagementSubnet'
    firewallName: firewallName
    firewallPolicyName: firewallPolicyName
    firewallSkuTier: firewallSkuTier
    firewallSupernetIPAddress: firewallSupernetIPAddress
    firewallThreatIntelMode: firewallThreatIntelMode
    location: location
    networkSecurityGroupName: hubNetworkSecurityGroupName
    networkSecurityGroupRules: hubNetworkSecurityGroupRules
    networkWatcherName: hubNetworkWatcherName
    routeTableName: hubRouteTableName
    subnetAddressPrefix: hubSubnetAddressPrefix
    subnetName: hubSubnetName
    tags: calculatedTags
    virtualNetworkAddressPrefix: hubVirtualNetworkAddressPrefix
    virtualNetworkName: hubVirtualNetworkName
    vNetDnsServers: [
      firewallClientPrivateIpAddress
    ]
  }
  dependsOn: [
    hubResourceGroup
  ]
}

module spokeNetworks './core/spoke-network.bicep' = [for spoke in spokes: {
  name: 'deploy-vnet-${spoke.name}-${deploymentNameSuffix}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    deployNetworkWatcher: spoke.deployUniqueResources
    firewallSkuTier: firewallSkuTier
    location: location
    networkSecurityGroupName: spoke.networkSecurityGroupName
    networkSecurityGroupRules: spoke.networkSecurityGroupRules
    networkWatcherName: spoke.networkWatcherName
    routeTableName: spoke.routeTableName
    routeTableRouteNextHopIpAddress: firewallClientPrivateIpAddress
    subnetAddressPrefix: spoke.subnetAddressPrefix
    subnetName: spoke.subnetName
    subnetPrivateEndpointNetworkPolicies: spoke.subnetPrivateEndpointNetworkPolicies
    subnetPrivateLinkServiceNetworkPolicies: spoke.subnetPrivateLinkServiceNetworkPolicies
    tags: calculatedTags
    virtualNetworkAddressPrefix: spoke.virtualNetworkAddressPrefix
    virtualNetworkName: spoke.virtualNetworkName
    vNetDnsServers: [ hubNetwork.outputs.firewallPrivateIPAddress ]
  }
  dependsOn: [
    spokeResourceGroups
  ]
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

// PRIVATE DNS

module privateDnsZones './modules/private-dns.bicep' = {
  name: 'deploy-private-dns-zones-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubVirtualNetworkResourceGroupName: hubResourceGroupName
    hubVirtualNetworkSubscriptionId: hubSubscriptionId
    identityVirtualNetworkName: deployIdentity ? spokes[2].virtualNetworkName : ''
    identityVirtualNetworkResourceGroupName: identityResourceGroupName
    identityVirtualNetworkSubscriptionId: identitySubscriptionId
    tags: tags
  }
  dependsOn: [
    spokeNetworks
  ]
}

// CUSTOMER MANAGED KEYS

module customerManagedKeys './core/hub-customer-managed-keys.bicep' = {
  name: 'deploy-cmk-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: hubDiskEncryptionSetName
    keyVaultName: hubKeyVaultName
    keyVaultNetworkInterfaceName: hubKeyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: privateDnsZones.outputs.keyvaultDnsPrivateDnsZoneId
    keyVaultPrivateEndpointName: hubKeyVaultPrivateEndpointName
    location: location
    subnetResourceId: hubNetwork.outputs.subnetResourceId
    tags: calculatedTags
    userAssignedIdentityName: hubUserAssignedIdentityName
  }
}

// AZURE MONITOR

module azureMonitor './modules/azure-monitor.bicep' = if (contains(supportedClouds, environment().name)) {
  name: 'deploy-azure-monitor-${deploymentNameSuffix}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    agentsvcPrivateDnsZoneId: privateDnsZones.outputs.agentsvcPrivateDnsZoneId
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id
    monitorPrivateDnsZoneId: privateDnsZones.outputs.monitorPrivateDnsZoneId
    odsPrivateDnsZoneId: privateDnsZones.outputs.odsPrivateDnsZoneId
    omsPrivateDnsZoneId: privateDnsZones.outputs.omsPrivateDnsZoneId
    privateLinkScopeName: operationsPrivateLinkScopeName
    privateLinkScopeNetworkInterfaceName: operationsPrivateLinkScopeNetworkInterfaceName
    privateLinkScopePrivateEndpointName: operationsPrivateLinkScopePrivateEndpointName
    subnetResourceId: spokeNetworks[0].outputs.subnetResourceId
    tags: tags
  }
  dependsOn: [
    logAnalyticsWorkspace
    privateDnsZones
    spokeNetworks
  ]
}

// REMOTE ACCESS

module remoteAccess './core/remote-access.bicep' = if (deployRemoteAccess) {
  name: 'deploy-remote-access-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    bastionHostIPConfigurationName: bastionHostIPConfigurationName
    bastionHostName: bastionHostName
    bastionHostPublicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    bastionHostPublicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    bastionHostPublicIPAddressName: bastionHostPublicIPAddressName
    bastionHostPublicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    bastionHostSubnetResourceId: hubNetwork.outputs.bastionHostSubnetResourceId
    hubNetworkSecurityGroupResourceId: hubNetwork.outputs.networkSecurityGroupResourceId
    hubSubnetResourceId: hubNetwork.outputs.subnetResourceId
    linuxNetworkInterfaceIpConfigurationName: linuxNetworkInterfaceIpConfigurationName
    linuxNetworkInterfaceName: linuxNetworkInterfaceName
    linuxNetworkInterfacePrivateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    linuxVmAdminPasswordOrKey: linuxVmAdminPasswordOrKey
    linuxVmAdminUsername: linuxVmAdminUsername
    linuxVmAuthenticationType: linuxVmAuthenticationType
    linuxVmImageOffer: linuxVmImageOffer
    linuxVmImagePublisher: linuxVmImagePublisher
    linuxVmImageSku: linuxVmImageSku
    linuxVmImageVersion: linuxVmImageVersion
    linuxVmName: linuxVmName
    linuxVmOsDiskCreateOption: linuxVmOsDiskCreateOption
    linuxVmOsDiskType: linuxVmOsDiskType
    linuxVmSize: linuxVmSize
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    tags: tags
    windowsNetworkInterfaceIpConfigurationName: windowsNetworkInterfaceIpConfigurationName
    windowsNetworkInterfaceName: windowsNetworkInterfaceName
    windowsNetworkInterfacePrivateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod
    windowsVmAdminPassword: windowsVmAdminPassword
    windowsVmAdminUsername: windowsVmAdminUsername
    windowsVmCreateOption: windowsVmCreateOption
    windowsVmName: windowsVmName
    windowsVmOffer: windowsVmOffer
    windowsVmPublisher: windowsVmPublisher
    windowsVmSize: windowsVmSize
    windowsVmSku: windowsVmSku
    windowsVmStorageAccountType: windowsVmStorageAccountType
    windowsVmVersion: windowsVmVersion
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    hybridUseBenefit: hybridUseBenefit
    linuxDiskName: linuxDiskName
    windowsDiskName: windowsDiskName
  }
  dependsOn: [
    azureMonitor
  ]
}

// HUB LOGGING STORAGE

module hubStorage './core/hub-storage.bicep' = {
  name: 'deploy-log-storage-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: privateDnsZones.outputs.blobPrivateDnsZoneId
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    logStorageAccountName: hubLogStorageAccountName
    logStorageAccountNetworkInterfaceNamePrefix: hubLogStorageAccountNetworkInterfaceNamePrefix
    logStorageAccountPrivateEndpointNamePrefix: hubLogStorageAccountPrivateEndpointNamePrefix
    logStorageSkuName: logStorageSkuName
    serviceToken: serviceToken
    storageEncryptionKeyName: customerManagedKeys.outputs.storageKeyName
    subnetResourceId: hubNetwork.outputs.subnetResourceId
    tablesPrivateDnsZoneResourceId: privateDnsZones.outputs.tablePrivateDnsZoneId
    tags: calculatedTags
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
  dependsOn: [
    remoteAccess
  ]
}

// SPOKE LOGGING STORAGE

module spokeStorage './core/spoke-storage.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-log-storage-${spoke.name}-${deploymentNameSuffix}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: privateDnsZones.outputs.blobPrivateDnsZoneId
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    logStorageAccountName: spoke.logStorageAccountName
    logStorageAccountNetworkInterfaceNamePrefix: spoke.logStorageAccountNetworkInterfaceNamePrefix
    logStorageAccountPrivateEndpointNamePrefix: spoke.logStorageAccountPrivateEndpointNamePrefix
    logStorageSkuName: logStorageSkuName
    serviceToken: serviceToken
    storageEncryptionKeyName: customerManagedKeys.outputs.storageKeyName
    subnetResourceId: spokeNetworks[i].outputs.subnetResourceId
    tablesPrivateDnsZoneResourceId: privateDnsZones.outputs.tablePrivateDnsZoneId
    tags: tags
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
  dependsOn: [
    remoteAccess
  ]
}]

// HUB DIAGONSTIC LOGGING

module hubDiagnostics 'core/hub-diagnostics.bicep' = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: 'deploy-diagnostic-logging-hub-${deploymentNameSuffix}'
  params: {
    firewallDiagnosticsLogs: firewallDiagnosticsLogs
    firewallDiagnosticsMetrics: firewallDiagnosticsMetrics
    firewallName: hubNetwork.outputs.firewallName
    hubStorageAccountResourceId: hubStorage.outputs.storageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id
    networkSecurityGroupDiagnosticsLogs: hubNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: hubNetworkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupName: hubNetworkSecurityGroupName
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
    publicIPAddressNames: [
      firewallClientPublicIPAddressName
      firewallManagementPublicIPAddressName
    ]
    virtualNetworkDiagnosticsLogs: hubVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: hubVirtualNetworkDiagnosticsMetrics
    virtualNetworkName: hubNetwork.outputs.virtualNetworkName
  }
}

// SPOKE DIAGONSTIC LOGGING

module spokeDiagnostics 'core/spoke-diagnostics.bicep' = [for (spoke, i) in spokes: {
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  name: 'deploy-diagnostic-logging-${spoke.name}-${deploymentNameSuffix}'
  params: {
    hubStorageAccountResourceId: spokeStorage[i].outputs.ResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id
    networkSecurityGroupDiagnosticsLogs: spoke.NetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: spoke.NetworkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupName: spokeNetworks[i].outputs.networkSecurityGroupName
    virtualNetworkDiagnosticsLogs: spoke.VirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: spoke.VirtualNetworkDiagnosticsMetrics
    virtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
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

module spokeSubscriptionActivityLogging './modules/central-logging.bicep' = [for spoke in spokes: if (spoke.deployUniqueResources) {
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
    spokeStorage
  ]
}

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

// Microsoft Defender for Cloud

module hubDefender './modules/defender.bicep' = if (deployDefender) {
  name: 'set-hub-sub-defender-${deploymentNameSuffix}'
  scope: subscription(hubSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    emailSecurityContact: emailSecurityContact
    defenderSkuTier: defenderSkuTier
  }
}

module spokeDefender './modules/defender.bicep' = [for spoke in spokes: if ((deployDefender) && (spoke.subscriptionId != hubSubscriptionId)) {
  name: 'set-${spoke.name}-sub-defender-${deploymentNameSuffix}'
  scope: subscription(spoke.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    emailSecurityContact: emailSecurityContact
    defenderSkuTier: defenderSkuTier
  }
}]
