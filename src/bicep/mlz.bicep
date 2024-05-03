/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

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

@description('Choose whether to deploy network watcher for the desired deployment location. Only one network watcher per location can exist in a subscription.')
param deployNetworkWatcher bool = false

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
param dnsServers array = ['168.63.129.16']

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
param identityNetworkSecurityGroupRules array = []

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

// KEY VAULT PARAMETERS
@description('An array of Key Vault Diagnostic Logs categories to collect. See "https://learn.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault" for valid values.')
param KeyVaultDiagnosticsLogs array = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]

// OPERATIONS PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param operationsVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param operationsVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param operationsNetworkSecurityGroupRules array = []

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
param sharedServicesNetworkSecurityGroupRules array = []

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

@description('The number of days to retain Log Analytics Workspace logs without Sentinel. It defaults to "30".')
param logAnalyticsWorkspaceNoSentinelRetentionInDays int = 30

@description('The number of days to retain logs in Sentinel-linked Workspace. It defaults to "90".')
param logAnalyticsSentinelWorkspaceRetentionInDays int = 90

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

@description('When set to "true", provisions Azure Bastion Host only. It defaults to "false".')
param deployBastion bool = false

@description('When set to "true", provisions Windows Virtual Machine Host only. It defaults to "false".')
param deployWindowsVirtualMachine bool = false

@description('When set to "true", provisions Linux Virtual Machine Host only. It defaults to "false".')
param deployLinuxVirtualMachine bool = false

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
param linuxVmAdminPasswordOrKey string = deployLinuxVirtualMachine ? '' : newGuid()

@description('The size of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_B2s".')
param linuxVmSize string = 'Standard_B2s'

@description('The disk creation option of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "FromImage".')
param linuxVmOsDiskCreateOption string = 'FromImage'

@description('The disk type of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Standard_LRS".')
param linuxVmOsDiskType string = 'Standard_LRS'

@description('The image publisher of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "Canonical".')
param linuxVmImagePublisher string = 'Canonical'

@description('The image offer of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "UbuntuServer".')
param linuxVmImageOffer string = '0001-com-ubuntu-server-focal'

@description('The image SKU of the Linux Virtual Machine to Azure Bastion remote into. It defaults to "18.04-LTS".')
param linuxVmImageSku string = '20_04-lts-gen2'

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
param windowsVmAdminPassword string = deployWindowsVirtualMachine ? '' : newGuid()

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

// MICROSOFT DEFENDER FOR CLOUD PARAMETERS

@description('When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".')
param deployDefender bool = true

@allowed([
  'Standard'
  'Free'
])
@description('[Standard/Free] The SKU for Defender. It defaults to "Free".')
param defenderSkuTier string = 'Free'

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string = ''

//Allowed Values for paid workload protection Plans.  
//Even if the customer wants the free tier, we must specify a plan from this list. This is why we specify VirtualMachines as a default value.
@allowed([
  'Api'
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
  'VirtualMachines'
])
@description('Paid Workload Protection plans for Defender for Cloud')
param deployDefenderPlans array = ['VirtualMachines']

var environmentName = {
  dev: 'Development'
  prod: 'Production'
  test: 'Test'
}
var mlzTags = {
  environment: environmentName[environmentAbbreviation]
  landingZoneName: 'MissionLandingZone'
  landingZoneVersion: loadTextContent('data/version.txt')
  resourcePrefix: resourcePrefix
}
var firewallClientPrivateIpAddress = firewallClientUsableIpAddresses[3]
var firewallClientUsableIpAddresses = [for i in range(0, 4): cidrHost(firewallClientSubnetAddressPrefix, i)]

var logAnalyticsWorkspaceRetentionInDays = deploySentinel
  ? logAnalyticsSentinelWorkspaceRetentionInDays
  : logAnalyticsWorkspaceNoSentinelRetentionInDays

// NAMING CONVENTION

module namingConvention 'modules/naming-convention.bicep' = {
  name: 'get-naming-convention-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    location: location
    resourcePrefix: resourcePrefix
  }
}

// LOGIC FOR DEPLOYMENTS

module logic 'modules/logic.bicep' = {
  name: 'get-logic-${deploymentNameSuffix}'
  params: {
    deployIdentity: deployIdentity
    environmentAbbreviation: environmentAbbreviation
    hubSubscriptionId: hubSubscriptionId
    identitySubnetAddressPrefix: identitySubnetAddressPrefix
    identitySubscriptionId: identitySubscriptionId
    operationsSubnetAddressPrefix: operationsSubnetAddressPrefix
    operationsSubscriptionId: operationsSubscriptionId
    resourcePrefix: resourcePrefix
    resources: namingConvention.outputs.resources
    sharedServicesSubscriptionId: sharedServicesSubscriptionId
    tokens: namingConvention.outputs.tokens
    identityNetworkSecurityGroupDiagnosticsLogs: identityNetworkSecurityGroupDiagnosticsLogs
    identityNetworkSecurityGroupDiagnosticsMetrics: identityNetworkSecurityGroupDiagnosticsMetrics
    identityNetworkSecurityGroupRules: identityNetworkSecurityGroupRules
    identityVirtualNetworkAddressPrefix: identityVirtualNetworkAddressPrefix
    identityVirtualNetworkDiagnosticsLogs: identityVirtualNetworkDiagnosticsLogs
    identityVirtualNetworkDiagnosticsMetrics: identityVirtualNetworkDiagnosticsMetrics
    operationsNetworkSecurityGroupDiagnosticsLogs: operationsNetworkSecurityGroupDiagnosticsLogs
    operationsNetworkSecurityGroupDiagnosticsMetrics: operationsNetworkSecurityGroupDiagnosticsMetrics
    operationsNetworkSecurityGroupRules: operationsNetworkSecurityGroupRules
    operationsVirtualNetworkAddressPrefix: operationsVirtualNetworkAddressPrefix
    operationsVirtualNetworkDiagnosticsLogs: operationsVirtualNetworkDiagnosticsLogs
    operationsVirtualNetworkDiagnosticsMetrics: operationsVirtualNetworkDiagnosticsMetrics
    sharedServicesNetworkSecurityGroupDiagnosticsLogs: sharedServicesNetworkSecurityGroupDiagnosticsLogs
    sharedServicesNetworkSecurityGroupDiagnosticsMetrics: sharedServicesNetworkSecurityGroupDiagnosticsMetrics
    sharedServicesNetworkSecurityGroupRules: sharedServicesNetworkSecurityGroupRules
    sharedServicesSubnetAddressPrefix: sharedServicesSubnetAddressPrefix
    sharedServicesVirtualNetworkAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    sharedServicesVirtualNetworkDiagnosticsLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    sharedServicesVirtualNetworkDiagnosticsMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics
  }
}

// RESOURCE GROUPS

module resourceGroups 'modules/resource-groups.bicep' = {
  name: 'deploy-resource-groups-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    location: location
    mlzTags: mlzTags
    networks: logic.outputs.networks
    tags: tags
  }
}

// NETWORKING

module networking 'modules/networking.bicep' = {
  name: 'deploy-networking-${deploymentNameSuffix}'
  params: {
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcher: deployNetworkWatcher
    deployBastion: deployBastion
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallSettings: {
      clientPrivateIpAddress: firewallClientPrivateIpAddress
      clientPublicIPAddressAvailabilityZones: firewallClientPublicIPAddressAvailabilityZones
      clientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
      intrusionDetectionMode: firewallIntrusionDetectionMode
      managementPublicIPAddressAvailabilityZones: firewallManagementPublicIPAddressAvailabilityZones
      managementSubnetAddressPrefix: firewallManagementSubnetAddressPrefix
      publicIpAddressAllocationMethod: 'Static'
      publicIpAddressSkuName: 'Standard'
      skuTier: firewallSkuTier
      supernetIPAddress: firewallSupernetIPAddress
      threatIntelMode: firewallThreatIntelMode
    }
    hubNetworkSecurityGroupRules: hubNetworkSecurityGroupRules
    hubSubnetAddressPrefix: hubSubnetAddressPrefix
    hubVirtualNetworkAddressPrefix: hubVirtualNetworkAddressPrefix
    location: location
    mlzTags: mlzTags
    networks: logic.outputs.networks
    tags: tags
  }
  dependsOn: [
    resourceGroups
  ]
}

// CUSTOMER MANAGED KEYS

module customerManagedKeys 'modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-hub-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    keyVaultPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.keyVault
    location: location
    mlzTags: mlzTags
    networkProperties: first(filter(logic.outputs.networks, network => network.name == 'hub'))
    subnetResourceId: networking.outputs.hubSubnetResourceId
    tags: tags
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
    mlzTags: mlzTags
    operationsProperties: first(filter(logic.outputs.networks, network => network.name == 'operations'))
    privateDnsZoneResourceIds: networking.outputs.privateDnsZoneResourceIds
    subnetResourceId: networking.outputs.operationsSubnetResourceId
    tags: tags
  }
  dependsOn: [
    networking
  ]
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
      hubNetworkSecurityGroupResourceId: networking.outputs.hubNetworkSecurityGroupResourceId
      hubProperties: first(filter(logic.outputs.networks, network => network.name == 'hub'))
      hubSubnetResourceId: networking.outputs.hubSubnetResourceId
      hybridUseBenefit: hybridUseBenefit
      linuxNetworkInterfacePrivateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
      linuxVmAdminPasswordOrKey: linuxVmAdminPasswordOrKey
      linuxVmAdminUsername: linuxVmAdminUsername
      linuxVmAuthenticationType: linuxVmAuthenticationType
      linuxVmImageOffer: linuxVmImageOffer
      linuxVmImagePublisher: linuxVmImagePublisher
      linuxVmImageSku: linuxVmImageSku
      linuxVmImageVersion: linuxVmImageVersion
      linuxVmOsDiskCreateOption: linuxVmOsDiskCreateOption
      linuxVmOsDiskType: linuxVmOsDiskType
      linuxVmSize: linuxVmSize
      location: location
      logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
      mlzTags: mlzTags
      tags: tags
      windowsNetworkInterfacePrivateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod
      windowsVmAdminPassword: windowsVmAdminPassword
      windowsVmAdminUsername: windowsVmAdminUsername
      windowsVmCreateOption: windowsVmCreateOption
      windowsVmOffer: windowsVmOffer
      windowsVmPublisher: windowsVmPublisher
      windowsVmSize: windowsVmSize
      windowsVmSku: windowsVmSku
      windowsVmStorageAccountType: windowsVmStorageAccountType
      windowsVmVersion: windowsVmVersion
    }
    dependsOn: [
      monitoring
    ]
  }

// STORAGE FOR LOGGING

module storage 'modules/storage.bicep' = {
  name: 'deploy-log-storage-${deploymentNameSuffix}'
  params: {
    blobsPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.blob
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    logStorageSkuName: logStorageSkuName
    mlzTags: mlzTags
    networks: logic.outputs.networks
    serviceToken: namingConvention.outputs.tokens.service
    storageEncryptionKeyName: customerManagedKeys.outputs.storageKeyName
    tablesPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.table
    tags: tags
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
    deploymentNameSuffix: deploymentNameSuffix
    firewallDiagnosticsLogs: firewallDiagnosticsLogs
    firewallDiagnosticsMetrics: firewallDiagnosticsMetrics
    KeyVaultName: customerManagedKeys.outputs.KeyVaultName
    keyVaultDiagnosticLogs: KeyVaultDiagnosticsLogs
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    networks: logic.outputs.networks
    networkSecurityGroupDiagnosticsLogs: hubNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: hubNetworkSecurityGroupDiagnosticsMetrics
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
    storageAccountResourceIds: storage.outputs.storageAccountResourceIds
    supportedClouds: supportedClouds
    virtualNetworkDiagnosticsLogs: hubVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: hubVirtualNetworkDiagnosticsMetrics
  }
  dependsOn: [
    networking
  ]
}

// POLICY ASSIGNMENTS

module policyAssignments 'modules/policy-assignments.bicep' =
  if (deployPolicy) {
    name: 'assign-policies-${deploymentNameSuffix}'
    params: {
      deploymentNameSuffix: deploymentNameSuffix
      location: location
      logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
      networks: logic.outputs.networks
      policy: policy
    }
  }

// MICROSOFT DEFENDER FOR CLOUD

module defenderforClouds 'modules/defenderforClouds.bicep' =
  if (deployDefender) {
    name: 'deploy-defender-${deploymentNameSuffix}'
    params: {
      defenderSkuTier: defenderSkuTier
      deploymentNameSuffix: deploymentNameSuffix
      emailSecurityContact: emailSecurityContact
      logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
      networks: logic.outputs.networks
      defenderPlans: deployDefenderPlans
    }
  }

output azureFirewallResourceId string = networking.outputs.azureFirewallResourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output hubSubnetResourceId string = networking.outputs.hubSubnetResourceId
output hubVirtualNetworkResourceId string = networking.outputs.hubVirtualNetworkResourceId
output identitySubnetResourceId string = networking.outputs.identitySubnetResourceId
output logAnalyticsWorkspaceResourceId string = monitoring.outputs.logAnalyticsWorkspaceResourceId
output networks array = logic.outputs.networks
