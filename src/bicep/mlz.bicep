/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@description('The CIDR Subnet Address Prefix for the Azure Gateway Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param azureGatewaySubnetAddressPrefix string = '10.0.129.192/26'

@description('An array of Bastion Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/bastion/monitor-bastion#collect-data-with-azure-monitor.')
param bastionDiagnosticsLogs array = [
  {
    category: 'BastionAuditLogs'
    enabled: true
  }
]

@description('An array of Bastion Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/bastion/monitor-bastion#collect-data-with-azure-monitor.')
param bastionDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The Azure Bastion Public IP Address Availability Zones. It defaults to "No-Zone" because Availability Zones are not available in every cloud. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku.')
param bastionHostPublicIPAddressAvailabilityZones array = []

@description('The CIDR Subnet Address Prefix for the Azure Bastion Subnet. It must be in the Hub Virtual Network space "hubVirtualNetworkAddressPrefix" parameter value. It must be /27 or larger.')
param bastionHostSubnetAddressPrefix string = '10.0.128.192/26'

@allowed([
  'Standard'
  'Free'
])
@description('[Standard/Free] The SKU for Defender. It defaults to "Free".')
param defenderSkuTier string = 'Free'

@description('When set to "true", provisions Azure Gateway Subnet only. It defaults to "false".')
param deployAzureGatewaySubnet bool = false

@description('When set to "true", provisions Azure Bastion Host using the Standard SKU. It defaults to "false".')
param deployBastion bool = false

@description('When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".')
param deployDefender bool = true

// Allowed Values for paid workload protection Plans.  
// Users must select a plan from portal ui def or manually specify any of the plans that are available in the desired cloud.  
// The portal does not parse the allowed values field for arrays  correctly at this time.
// As a default, the array is set to ['VirtualMachines'].
/*   'Api'
  'AppServices'
  'Arm'
  'CloudPosture'
  //'ContainerRegistry' (deprecated)
  'Containers'
  'CosmosDbs'
  //'Dns' (deprecated)
  'KeyVaults'
  //'KubernetesService' (deprecated)
  'OpenSourceRelationalDatabases'
  'SqlServers'
  'SqlServerVirtualMachines'
  'StorageAccounts'
  'VirtualMachine*/
  
@description('The Paid Workload Protection plans for Defender for Cloud. It defaults to "VirtualMachines". See the following URL for valid settings: https://learn.microsoft.com/rest/api/defenderforcloud-composite/pricings/update?view=rest-defenderforcloud-composite-latest&tabs=HTTP.')
param deployDefenderPlans array = ['VirtualMachines']

@description('Choose to deploy the identity resources. The identity resoures are not required if you plan to use cloud identities.')
param deployIdentity bool = false

@description('When set to "true", provisions Linux Virtual Machine Host only. It defaults to "false".')
param deployLinuxVirtualMachine bool = false

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('When set to true, deploys Network Watcher Traffic Analytics. It defaults to "false".')
param deployNetworkWatcherTrafficAnalytics bool = false

@description('When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".')
param deployPolicy bool = false

@description('When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment. It defaults to "false".')
param deploySentinel bool = false

@description('When set to "true", provisions Windows Virtual Machine Host only. It defaults to "false".')
param deployWindowsVirtualMachine bool = false

@description('The Azure Firewall DNS Proxy will forward all DNS traffic. When this value is set to true, you must provide a value for "servers". This should be a comma separated list of IP addresses to forward DNS traffic')
param dnsServers array = ['168.63.129.16']

@description('The email address for Defender for Cloud alert notifications, in the form of john@contoso.com.')
param emailSecurityContact string = ''

@description('[true/false] The Azure Firewall DNS Proxy will forward all DNS traffic. It defaults to "true".')
param enableProxy bool = true

@allowed([
  'dev'
  'prod'
  'test'
])
@description('The abbreviation for the environment.')
param environmentAbbreviation string = 'dev'

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku.')
param firewallClientPublicIPAddressAvailabilityZones array = []

@description('The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param firewallClientSubnetAddressPrefix string = '10.0.128.0/26'

@description('An array of Firewall Diagnostic Logs categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/firewall/monitor-firewall#enable-diagnostic-logging-through-the-azure-portal.')
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
      enabled: enableProxy
  }
  {
      category: 'AZFWNetworkRule'
      enabled: true
  }
  {
      category: 'AZFWApplicationRule'
      enabled: true
  }
  {
      category: 'AZFWNatRule'
      enabled: true
  }
  {
      category: 'AZFWThreatIntel'
      enabled: true
  }
  {
      category: 'AZFWIdpsSignature'
      enabled: true
  }
  {
      category: 'AZFWDnsQuery'
      enabled: true
  }
  {
      category: 'AZFWFqdnResolveFailure'
      enabled: true
  }
  {
      category: 'AZFWFatFlow'
      enabled: true
  }
  {
      category: 'AZFWFlowTrace'
      enabled: true
  }
  {
      category: 'AZFWApplicationRuleAggregation'
      enabled: true
  }
  {
      category: 'AZFWNetworkRuleAggregation'
      enabled: true
  }
  {
      category: 'AZFWNatRuleAggregation'
      enabled: true
  }
]

@description('An array of Firewall Diagnostic Metrics categories to collect. See the following URL for valid values: https://learn.microsoft.com/azure/firewall/monitor-firewall#enable-diagnostic-logging-through-the-azure-portal.')
param firewallDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@allowed([
  'Alert'
  'Deny'
  'Off'
])
@description('The Azure Firewall Intrusion Detection mode. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".')
param firewallIntrusionDetectionMode string = 'Alert'

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku.')
param firewallManagementPublicIPAddressAvailabilityZones array = []

@description('The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param firewallManagementSubnetAddressPrefix string = '10.0.128.64/26'

@allowed([
  'Standard'
  'Premium'
  'Basic'
])
@description('[Standard/Premium/Basic] The SKU for Azure Firewall. It defaults to "Premium". Selecting a value other than Premium is not recommended for environments that are required to be SCCA compliant.')
param firewallSkuTier string = 'Premium'

@description('Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses')
param firewallSupernetIPAddress string = '10.0.128.0/18'

@allowed([
  'Alert'
  'Deny'
  'Off'
])
@description('[Alert/Deny/Off] The Azure Firewall Threat Intelligence Rule triggered logging behavior. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".')
param firewallThreatIntelMode string = 'Alert'

@description('An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories.')
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

@description('An array of Network Security Group Rules to apply to the Hub Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep&pivots=deployment-language-bicep#securityrulepropertiesformat.')
param hubNetworkSecurityGroupRules array = []

@description('The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.')
param hubSubnetAddressPrefix string = '10.0.128.128/26'

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param hubSubscriptionId string = subscription().subscriptionId

@description('The CIDR Virtual Network Address Prefix for the Hub Virtual Network.')
param hubVirtualNetworkAddressPrefix string = '10.0.128.0/23'

@description('An array of Network Diagnostic Logs to enable for the Hub Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs.')
param hubVirtualNetworkDiagnosticsLogs array = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

@description('An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics.')
param hubVirtualNetworkDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The hybrid use benefit provides a discount on virtual machines when a customer has an on-premises Windows Server license with Software Assurance. It defaults to "false".')
param hybridUseBenefit bool = false

@description('An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories.')
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

@description('An array of Network Security Group Rules to apply to the Identity Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat.')
param identityNetworkSecurityGroupRules array = []

@description('The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.')
param identitySubnetAddressPrefix string = '10.0.130.0/24'

@description('The subscription ID for the Identity Network and resources. It defaults to the deployment subscription.')
param identitySubscriptionId string = subscription().subscriptionId

@description('The CIDR Virtual Network Address Prefix for the Identity Virtual Network.')
param identityVirtualNetworkAddressPrefix string = '10.0.130.0/24'

@description('An array of Network Diagnostic Logs to enable for the Identity Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs.')
param identityVirtualNetworkDiagnosticsLogs array = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

@description('An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics.')
param identityVirtualNetworkDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('An array of Key Vault Diagnostic Logs categories to collect. See the following URL for valid settings: "https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault".')
param keyVaultDiagnosticsLogs array = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]

@description('The Key Vault Diagnostic Metrics to collect. See the following URL for valid settings: "https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault".')
param keyVaultDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@allowed([
  'Static'
  'Dynamic'
])
@description('[Static/Dynamic] The public IP Address allocation method for the Linux virtual machine. It defaults to "Dynamic".')
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

@minLength(12)
@secure()
@description('The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm-.')
param linuxVmAdminPasswordOrKey string = deployLinuxVirtualMachine ? '' : newGuid()

@description('The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".')
param linuxVmAdminUsername string = 'xadmin'

@allowed([
  'sshPublicKey'
  'password'
])
@description('[sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".')
param linuxVmAuthenticationType string = 'password'

@allowed([
  'ubuntuserver'
  '0001-com-ubuntu-server-focal'
  '0001-com-ubuntu-server-jammy'
  'RHEL'
  'Debian-12'
])
@description('[Ubuntu/RHEL/Debian-12] The available Linux Offers')
param linuxVmImageOffer string = '0001-com-ubuntu-server-focal'

@allowed([
  'Canonical'
  'RedHat'
  'Debian'
])
@description('[Canonical for Ubuntu/RedHat/Debian] The available Linux Publishers')
param linuxVmImagePublisher string = 'Canonical'

@description('The SKU of the Linux marketplace image.')
param linuxVmImageSku string = '20_04-lts-gen2'

@description('The disk creation option of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".')
param linuxVmOsDiskCreateOption string = 'FromImage'

@description('The disk type of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_LRS".')
param linuxVmOsDiskType string = 'Standard_LRS'

@description('The size of the Linux virtual machine.')
param linuxVmSize string = 'Standard_D2s_v3'

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@description('The daily quota for Log Analytics Workspace logs in Gigabytes. It defaults to "-1" for no quota.')
param logAnalyticsWorkspaceCappingDailyQuotaGb int = -1

@description('The number of days to retain Log Analytics Workspace logs without Sentinel. It defaults to "30".')
param logAnalyticsWorkspaceRetentionInDays int = 30

@allowed([
  'Free'
  'Standard'
  'Premium'
  'PerNode'
  'PerGB2018'
  'Standalone'
])
@description('The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/logs/resource-manager-workspace.')
param logAnalyticsWorkspaceSkuName string = 'PerGB2018'

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See the following URL for valid settings: https://learn.microsoft.com/rest/api/storagerp/srp_sku_types.')
param logStorageSkuName string = 'Standard_GRS'

@description('An array of metrics to enable on the diagnostic setting for network interfaces.')
param networkInterfaceDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The number of days to retain Network Watcher Flow Logs. It defaults to "30".')  
param networkWatcherFlowLogsRetentionDays int = 30

@allowed([
  'NetworkSecurityGroup'
  'VirtualNetwork'
])
@description('The type of network watcher flow logs to enable. It defaults to "VirtualNetwork" since they provide more data and NSG flow logs will be deprecated in June 2025.')
param networkWatcherFlowLogsType string = 'VirtualNetwork'

@description('The resource ID for an existing network watcher for the desired deployment location. Only one network watcher per location can exist in a subscription. The value can be left empty to create a new network watcher resource.')
param networkWatcherResourceId string = ''

@description('An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories.')
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

@description('An array of Network Security Group rules to apply to the Operations Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat.')
param operationsNetworkSecurityGroupRules array = []

@description('The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.')
param operationsSubnetAddressPrefix string = '10.0.131.0/24'

@description('The subscription ID for the Operations Network and resources. It defaults to the deployment subscription.')
param operationsSubscriptionId string = subscription().subscriptionId

@description('The CIDR Virtual Network Address Prefix for the Operations Virtual Network.')
param operationsVirtualNetworkAddressPrefix string = '10.0.131.0/24'

@description('An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs.')
param operationsVirtualNetworkDiagnosticsLogs array = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

@description('An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics.')
param operationsVirtualNetworkDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@allowed([
  'NISTRev4'
  'NISTRev5'
  'IL5' // AzureUsGoverment only, trying to deploy IL5 in AzureCloud will switch to NISTRev4
  'CMMC'
])
@description('Built-in policy assignments to assign, it defaults to "NISTRev4". IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.')
param policy string = 'NISTRev4'

@description('An array of Public IP Address Diagnostic Logs for the Azure Firewall. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/tutorial-resource-logs?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs.')
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

@description('An array of Public IP Address Diagnostic Metrics for the Azure Firewall. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/tutorial-resource-logs?tabs=DDoSProtectionNotifications.')
param publicIPAddressDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@minLength(1)
@maxLength(6)
@description('A prefix, 1-6 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string

@description('An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories.')
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

@description('An array of Network Security Group rules to apply to the SharedServices Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat.')
param sharedServicesNetworkSecurityGroupRules array = []

@description('The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.')
param sharedServicesSubnetAddressPrefix string = '10.0.132.0/24'

@description('The subscription ID for the Shared Services Network and resources. It defaults to the deployment subscription.')
param sharedServicesSubscriptionId string = subscription().subscriptionId

@description('The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.')
param sharedServicesVirtualNetworkAddressPrefix string = '10.0.132.0/24'

@description('An array of Network Diagnostic Logs to enable for the SharedServices Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs.')
param sharedServicesVirtualNetworkDiagnosticsLogs array = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

@description('An array of Network Diagnostic Metrics to enable for the SharedServices Virtual Network. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics.')
param sharedServicesVirtualNetworkDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The Azure clouds that support specific service features. It defaults to the Azure Cloud and Azure US Government.')
param supportedClouds array = [
  'AzureCloud'
  'AzureUSGovernment'
]

@description('A string dictionary of tags to add to deployed resources. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates.')
param tags object = {}

@minLength(12)
@secure()
@description('The administrator password the Windows Virtual Machine to Azure Bastion remote into. It must be > 12 characters in length. See the following URL for valid settings: https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-.')
param windowsVmAdminPassword string = deployWindowsVirtualMachine ? '' : newGuid()

@description('The administrator username for the Windows Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".')
param windowsVmAdminUsername string = 'xadmin'

@description('The disk creation option of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".')
param windowsVmCreateOption string = 'FromImage'

@description('The offer of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "WindowsServer".')
param windowsVmImageOffer string = 'WindowsServer'

@description('The publisher of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "MicrosoftWindowsServer".')
param windowsVmImagePublisher string = 'MicrosoftWindowsServer'

@allowed([
  '2019-datacenter-gensecond'
  '2022-datacenter-g2'
])
@description('The SKU of the Windows Virtual Machines to Azure Bastion remote into. It defaults to "2019-datacenter".')
param windowsVmImageSku string = '2019-datacenter-gensecond'

@allowed([
  'Static'
  'Dynamic'
])
@description('[Static/Dynamic] The public IP Address allocation method for the Windows virtual machine. It defaults to "Dynamic".')
param windowsVmNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

@description('The size of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "Standard_DS1_v2".')
param windowsVmSize string = 'Standard_DS1_v2'

@description('The storage account type of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "StandardSSD_LRS".')
param windowsVmStorageAccountType string = 'StandardSSD_LRS'

@description('The version of the Windows Virtual Machine to Azure Bastion remote into. It defaults to "latest".')
param windowsVmVersion string = 'latest'

var firewallClientPrivateIpAddress = firewallClientUsableIpAddresses[3]
var firewallClientUsableIpAddresses = [for i in range(0, 4): cidrHost(firewallClientSubnetAddressPrefix, i)]

var networks = union([
  {
    name: 'hub'
    shortName: 'hub'
    deployUniqueResources: true
    subscriptionId: hubSubscriptionId
    nsgDiagLogs: hubNetworkSecurityGroupDiagnosticsLogs
    nsgRules: hubNetworkSecurityGroupRules
    vnetAddressPrefix: hubVirtualNetworkAddressPrefix
    vnetDiagLogs: hubVirtualNetworkDiagnosticsLogs
    vnetDiagMetrics: hubVirtualNetworkDiagnosticsMetrics
    subnetAddressPrefix: hubSubnetAddressPrefix
  }
  {
    name: 'operations'
    shortName: 'ops'
    deployUniqueResources: contains([ hubSubscriptionId ], operationsSubscriptionId) ? false : true
    subscriptionId: operationsSubscriptionId  
    nsgDiagLogs: operationsNetworkSecurityGroupDiagnosticsLogs
    nsgRules: operationsNetworkSecurityGroupRules
    vnetAddressPrefix: operationsVirtualNetworkAddressPrefix
    vnetDiagLogs: operationsVirtualNetworkDiagnosticsLogs
    vnetDiagMetrics: operationsVirtualNetworkDiagnosticsMetrics
    subnetAddressPrefix: operationsSubnetAddressPrefix
  }
  {
    name: 'sharedServices'
    shortName: 'svcs'
    deployUniqueResources: contains([ hubSubscriptionId, operationsSubscriptionId ], sharedServicesSubscriptionId) ? false : true
    subscriptionId: sharedServicesSubscriptionId  
    nsgDiagLogs: sharedServicesNetworkSecurityGroupDiagnosticsLogs
    nsgRules: sharedServicesNetworkSecurityGroupRules
    vnetAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    vnetDiagLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    vnetDiagMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics
    subnetAddressPrefix: sharedServicesSubnetAddressPrefix
  }
], deployIdentity ? [
  {
    name: 'identity'
    shortName: 'id'
    deployUniqueResources: contains([ hubSubscriptionId, operationsSubscriptionId, sharedServicesSubscriptionId ], identitySubscriptionId) ? false : true
    subscriptionId: identitySubscriptionId
    nsgDiagLogs: identityNetworkSecurityGroupDiagnosticsLogs
    nsgRules: identityNetworkSecurityGroupRules
    vnetAddressPrefix: identityVirtualNetworkAddressPrefix
    vnetDiagLogs: identityVirtualNetworkDiagnosticsLogs
    vnetDiagMetrics: identityVirtualNetworkDiagnosticsMetrics
    subnetAddressPrefix: identitySubnetAddressPrefix
  }
] : [])

// LOGIC FOR DEPLOYMENTS

module logic 'modules/logic.bicep' = {
  name: 'get-logic-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    location: location
    networks: networks
    resourcePrefix: resourcePrefix
  }
}

// RESOURCE GROUPS

module resourceGroups 'modules/resource-groups.bicep' = {
  name: 'deploy-resource-groups-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    location: location
    mlzTags: logic.outputs.mlzTags
    serviceToken: logic.outputs.tokens.service
    tiers: logic.outputs.tiers
    tags: tags
  }
}

// NETWORKING

module networking 'modules/networking.bicep' = {
  name: 'deploy-networking-${deploymentNameSuffix}'
  params: {
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    azureGatewaySubnetAddressPrefix: azureGatewaySubnetAddressPrefix
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    deployBastion: deployBastion
    deployAzureGatewaySubnet: deployAzureGatewaySubnet
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallSettings: {
      clientPrivateIpAddress: firewallClientPrivateIpAddress
      clientPublicIPAddressAvailabilityZones: firewallClientPublicIPAddressAvailabilityZones
      clientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
      intrusionDetectionMode: firewallIntrusionDetectionMode
      managementPublicIPAddressAvailabilityZones: firewallManagementPublicIPAddressAvailabilityZones
      managementSubnetAddressPrefix: firewallManagementSubnetAddressPrefix
      skuTier: firewallSkuTier
      supernetIPAddress: firewallSupernetIPAddress
      threatIntelMode: firewallThreatIntelMode
    }
    location: location
    mlzTags: logic.outputs.mlzTags
    networkWatcherResourceId: networkWatcherResourceId
    privateDnsZoneNames: logic.outputs.privateDnsZones
    resourceGroupNames: resourceGroups.outputs.names
    tags: tags
    tiers: logic.outputs.tiers
  }
}

// CUSTOMER MANAGED KEYS

module customerManagedKeys 'modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-hub-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyVaultPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.keyVault
    location: location
    mlzTags: logic.outputs.mlzTags
    resourceAbbreviations: logic.outputs.resourceAbbreviations
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, 'hub'))[0]
    subnetResourceId: networking.outputs.hubSubnetResourceId
    tags: tags
    tier: filter(logic.outputs.tiers, tier => tier.name == 'hub')[0]
    tokens: logic.outputs.tokens
    workloadShortName: 'ops'
  }
}

// MONITORING

module monitoring 'modules/monitoring.bicep' = {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deploySentinel: deploySentinel
    location: location
    logAnalyticsWorkspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
    logAnalyticsWorkspaceRetentionInDays: logAnalyticsWorkspaceRetentionInDays
    logAnalyticsWorkspaceSkuName: logAnalyticsWorkspaceSkuName
    mlzTags: logic.outputs.mlzTags
    ops: filter(logic.outputs.tiers, tier => tier.name == 'operations')[0]
    opsResourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, 'operations'))[0]
    privateDnsZoneResourceIds: networking.outputs.privateDnsZoneResourceIds
    subnetResourceId: networking.outputs.operationsSubnetResourceId
    tags: tags
  }
}

// REMOTE ACCESS

module remoteAccess 'modules/remote-access.bicep' = {
  name: 'deploy-remote-access-${deploymentNameSuffix}'
  params: {
    bastionHostPublicIPAddressAllocationMethod: 'Static'
    bastionHostPublicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    bastionHostPublicIPAddressSkuName: 'Standard'
    bastionHostSubnetResourceId: networking.outputs.bastionHostSubnetResourceId
    deployBastion: deployBastion
    deployLinuxVirtualMachine: deployLinuxVirtualMachine
    deployWindowsVirtualMachine: deployWindowsVirtualMachine
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    hub: filter(logic.outputs.tiers, tier => tier.name == 'hub')[0]
    hubNetworkSecurityGroupResourceId: networking.outputs.hubNetworkSecurityGroupResourceId
    hubResourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, 'hub'))[0]
    hubSubnetResourceId: networking.outputs.hubSubnetResourceId
    hybridUseBenefit: hybridUseBenefit
    linuxNetworkInterfacePrivateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    linuxVmAdminPasswordOrKey: linuxVmAdminPasswordOrKey
    linuxVmAdminUsername: linuxVmAdminUsername
    linuxVmImagePublisher: linuxVmImagePublisher
    linuxVmImageOffer: linuxVmImageOffer
    linuxVmImageSku: linuxVmImageSku
    linuxVmSize: linuxVmSize
    linuxVmAuthenticationType: linuxVmAuthenticationType
    linuxVmOsDiskCreateOption: linuxVmOsDiskCreateOption
    linuxVmOsDiskType: linuxVmOsDiskType
    location: location
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    mlzTags: logic.outputs.mlzTags
    serviceToken: logic.outputs.tokens.service
    supportedClouds: supportedClouds
    tags: tags
    windowsVmAdminPassword: windowsVmAdminPassword
    windowsVmAdminUsername: windowsVmAdminUsername
    windowsVmCreateOption: windowsVmCreateOption
    windowsVmImageOffer: windowsVmImageOffer
    windowsVmImagePublisher: windowsVmImagePublisher
    windowsVmImageSku: windowsVmImageSku
    windowsVmNetworkInterfacePrivateIPAddressAllocationMethod: windowsVmNetworkInterfacePrivateIPAddressAllocationMethod
    windowsVmSize: windowsVmSize
    windowsVmStorageAccountType: windowsVmStorageAccountType
    windowsVmVersion: windowsVmVersion
  }
}

// STORAGE FOR LOGGING

module storage 'modules/storage.bicep' = {
  name: 'deploy-log-storage-${deploymentNameSuffix}'
  params: {
    blobsPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.blob
    //deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    filesPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.file
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    logStorageSkuName: logStorageSkuName
    mlzTags: logic.outputs.mlzTags
    queuesPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.queue
    resourceGroupNames: resourceGroups.outputs.names
    serviceToken: logic.outputs.tokens.service
    storageEncryptionKeyName: customerManagedKeys.outputs.storageKeyName
    tablesPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.table
    tags: tags
    tiers: logic.outputs.tiers
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
  dependsOn: [
    remoteAccess
  ]
}

// DIAGONSTIC LOGGING

module diagnostics 'modules/diagnostics.bicep' = {
  name: 'deploy-resource-diag-${deploymentNameSuffix}'
  params: {
    bastionDiagnosticsLogs: bastionDiagnosticsLogs
    bastionDiagnosticsMetrics: bastionDiagnosticsMetrics
    deployBastion: deployBastion
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    deploymentNameSuffix: deploymentNameSuffix
    firewallDiagnosticsLogs: firewallDiagnosticsLogs
    firewallDiagnosticsMetrics: firewallDiagnosticsMetrics
    keyVaultName: customerManagedKeys.outputs.keyVaultName
    keyVaultDiagnosticLogs: keyVaultDiagnosticsLogs
    keyVaultDiagnosticMetrics: keyVaultDiagnosticsMetrics
    location: location
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    networkInterfaceDiagnosticsMetrics: networkInterfaceDiagnosticsMetrics
    networkInterfaceResourceIds: union(customerManagedKeys.outputs.networkInterfaceResourceIds, monitoring.outputs.networkInterfaceResourceIds, remoteAccess.outputs.networkInterfaceResourceIds, flatten(storage.outputs.networkInterfaceResourceIds))
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherResourceId: networkWatcherResourceId
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
    resourceGroupNames: resourceGroups.outputs.names
    serviceToken: logic.outputs.tokens.service
    storageAccountResourceIds: storage.outputs.storageAccountResourceIds
    supportedClouds: supportedClouds
    tiers: logic.outputs.tiers
  }
}

// POLICY ASSIGNMENTS

module policyAssignments 'modules/policy-assignments.bicep' =
  if (deployPolicy) {
    name: 'assign-policies-${deploymentNameSuffix}'
    params: {
      deploymentNameSuffix: deploymentNameSuffix
      location: location
      logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
      policy: policy
      resourceGroupNames: resourceGroups.outputs.names
      serviceToken: logic.outputs.tokens.service
      tiers: logic.outputs.tiers
    }
  }

// MICROSOFT DEFENDER FOR CLOUD

module defenderforClouds 'modules/defender-for-clouds.bicep' =
  if (deployDefender) {
    name: 'deploy-defender-${deploymentNameSuffix}'
    params: {
      defenderPlans: deployDefenderPlans
      defenderSkuTier: defenderSkuTier
      deploymentNameSuffix: deploymentNameSuffix
      emailSecurityContact: emailSecurityContact
      tiers: logic.outputs.tiers
    }
  }

output azureFirewallResourceId string = networking.outputs.azureFirewallResourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output hubVirtualNetworkResourceId string = networking.outputs.hubVirtualNetworkResourceId
output identitySubnetResourceId string = networking.outputs.identitySubnetResourceId
output locationProperties object = logic.outputs.locationProperties
output logAnalyticsWorkspaceResourceId string = monitoring.outputs.logAnalyticsWorkspaceResourceId
output privateLinkScopeResourceId string = monitoring.outputs.privateLinkScopeResourceId
output sharedServicesSubnetResourceId string = networking.outputs.sharedServicesSubnetResourceId
output tiers array = logic.outputs.tiers
