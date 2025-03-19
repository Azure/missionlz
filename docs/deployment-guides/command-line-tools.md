# Mission Landing Zone - Deployment Guide using Command Line Tools

[**Home**](../../README.md) | [**Design**](../design.md) | [**Add-Ons**](../../src/bicep/add-ons/README.md) | [**Resources**](../resources.md)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Planning](#planning)
- [Deploy MLZ](#deploy-mlz)
- [Remove MLZ](#remove-mlz)
- [References](#references)

This guide describes how to deploy Mission Landing Zone (MLZ) using the ARM template at [src/bicep/mlz.json](../../src/bicep/mlz.json) using either Azure CLI or Azure PowerShell. The supported clouds for this guide include the Azure Commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret.

MLZ has only one required parameter and provides sensible defaults for the rest, allowing for simple deployments that specify only the parameters that need to differ from the defaults. See the [README.md](../../src/bicep/README.md) document in the **src/bicep** folder for a complete list of parameters.

## Prerequisites

The following prerequisites are required on the target Azure subscription(s):

- [Owner RBAC permissions](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner)
- [Enable Encryption At Host](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal?tabs=azure-powershell#prerequisites)
- Command Line Tools:
  - **Azure PowerShell:** for PowerShell deployments you need a PowerShell terminal with the [Az PowerShell module](https://learn.microsoft.com/powershell/azure/what-is-azure-powershell).
    - [**Azure Cloud Shell:**](https://learn.microsoft.com/azure/cloud-shell/overview) already has the necessary module and can be used without the installation of software.
    - **Local:** you would need to install [Az PowerShell module](https://learn.microsoft.com/powershell/azure/install-azps-windows?view=azps-12.4.0&tabs=powershell&pivots=windows-msi) to execute the deployment on your workstation.
  - **Azure CLI:** for deployments in BASH or a Windows shell, AZ CLI is required.
    - [**Azure Cloud Shell:**](https://learn.microsoft.com/azure/cloud-shell/overview) already has Azure CLI and can be used without the installation of software.
    - **Local:** you would need to install [AZ CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) to execute the deployment on your workstation.

## Planning

### Naming Convention

Resource group and resource names are derived from the following parameters:

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`environmentAbbreviation` | dev | The abbreviation for the target environment.
`resourcePrefix` |  | A prefix, 1-6 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources within your subscription. Ideally, the value should represent a department or project within your organization.

### Deployment Scope

MLZ can deploy to a single subscription or multiple subscriptions. A test and evaluation deployment may deploy everything to a single subscription, and a production deployment may place each tier into its own subscription.

The optional parameters related to subscriptions are below. They default to the subscription used for deployment.

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deployIdentity` | false | Choose to deploy the identity resources. The identity resoures are not required if you plan to use cloud identities.
`hubSubscriptionId` | Deployment subscription | Subscription containing the firewall and network hub
`identitySubscriptionId` | Deployment subscription | Tier 0 for identity solutions
`location` | deployment().location | The region to deploy resources into.
`operationsSubscriptionId` | Deployment subscription | Tier 1 for network operations and security tools
`sharedServicesSubscriptionId` | Deployment subscription | Tier 2 for shared services

### Networking

The following parameters affect the networking resources. For the address prefixes, each virtual network and subnet has been given a default value to ensure they fall within the default super network. Refer to the [Networking page](../networking.md) for all the default address prefixes.

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deployNetworkWatcherTrafficAnalytics` | false | When set to true, deploys Network Watcher Traffic Analytics.
`dnsServers` | ['168.63.129.16'] | The Azure Firewall DNS Proxy will forward all DNS traffic. When this value is set to true, you must provide a value for "servers". This should be a comma separated list of IP addresses to forward DNS traffic.
`existingHubNetworkWatcherResourceId` | '' | The resource ID for an existing network watcher in the Hub tier for the desired deployment location. Only one network watcher per location can exist in a subscription and must be specified if it already exists. If the value is left empty, a new network watcher resource will be created.
`existingIdentityNetworkWatcherResourceId` | '' | The resource ID for an existing network watcher in the Identity tier for the desired deployment location. Only one network watcher per location can exist in a subscription and must be specified if it already exists. If the value is left empty, a new network watcher resource will be created.
`existingOperationsNetworkWatcherResourceId` | '' | The resource ID for an existing network watcher in the Operations tier for the desired deployment location. Only one network watcher per location can exist in a subscription and must be specified if it already exists. If the value is left empty, a new network watcher resource will be created.
`existingSharedServicesNetworkWatcherResourceId` | '' | The resource ID for an existing network watcher in the Shared Services tier for the desired deployment location. Only one network watcher per location can exist in a subscription and must be specified if it already exists. If the value is left empty, a new network watcher resource will be created.
`hubNetworkSecurityGroupRules` | [] | An array of Network Security Group Rules to apply to the Hub Virtual Network. [Reference](https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep&pivots=deployment-language-bicep#securityrulepropertiesformat)
`hubSubnetAddressPrefix` | 10.0.128.128/26 | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.
`hubVirtualNetworkAddressPrefix` | 10.0.128.0/23 | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.
`identityNetworkSecurityGroupRules` | [] | An array of Network Security Group Rules to apply to the Identity Virtual Network. [Reference](https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat)
`identitySubnetAddressPrefix` | 10.0.130.0/24 | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.
`identityVirtualNetworkAddressPrefix` | 10.0.130.0/24 | The CIDR Virtual Network Address Prefix for the Identity Virtual Network.
`operationsNetworkSecurityGroupRules` | [] | An array of Network Security Group rules to apply to the Operations Virtual Network. [Reference](https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat)
`operationsSubnetAddressPrefix` | 10.0.131.0/24 | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.
`operationsVirtualNetworkAddressPrefix` | 10.0.131.0/24 | The CIDR Virtual Network Address Prefix for the Operations Virtual Network.
`sharedServicesNetworkSecurityGroupRules` | [] | An array of Network Security Group rules to apply to the SharedServices Virtual Network. [Reference](https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat)
`sharedServicesSubnetAddressPrefix` | 10.0.132.0/24 | The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.
`sharedServicesVirtualNetworkAddressPrefix` | 10.0.132.0/24 | The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.

#### Azure Firewall

By default, MLZ deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features). Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://learn.microsoft.com/azure/firewall/premium-features#supported-regions). If necessary you can set a different firewall SKU or location.

You can manually specify which SKU of Azure Firewall to use for your deployment by specifying the `firewallSkuTier` parameter. This parameter only accepts values of `Premium`, `Standard`, or `Basic`.

Parameter Name    | Default Value | Description
:---------------- | :------------ | :----------
`enableProxy` | true | The Azure Firewall DNS Proxy will forward all DNS traffic.
`firewallClientPublicIPAddressAvailabilityZones` | [] | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. [Reference](https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku)
`firewallClientSubnetAddressPrefix` | 10.0.128.0/26 | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallIntrusionDetectionMode` | Alert | The Azure Firewall Intrusion Detection mode.
`firewallManagementPublicIPAddressAvailabilityZones` | [] | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. [Reference](https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku)
`firewallManagementSubnetAddressPrefix` | 10.0.128.64/26 | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallSkuTier` | Premium | The SKU for Azure Firewall. Selecting a value other than Premium is not recommended for environments that are required to be SCCA compliant.
`firewallSupernetIPAddress` | 10.0.128.0/18 | Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses.
`firewallThreatIntelMode` | Alert | [Alert/Deny/Off] The Azure Firewall Threat Intelligence Rule triggered logging behavior.

### Monitoring

Set the following settings to enable the capture of resource logs and metrics:

Parameter Name    | Default Value | Description
:---------------- | :------------ | :----------
`firewallDiagnosticsLogs` | AzureFirewallApplicationRule, AzureFirewallNetworkRule, AzureFirewallDnsProxy, AZFWNetworkRule, AZFWApplicationRule, AZFWNatRule, AZFWThreatIntel, AZFWIdpsSignature, AZFWDnsQuery, AZFWFqdnResolveFailure, AZFWFatFlow, AZFWFlowTrace, AZFWApplicationRuleAggregation, AZFWNetworkRuleAggregation, AZFWNatRuleAggregation | An array of Firewall Diagnostic Logs categories to collect.
`firewallDiagnosticsMetrics` | AllMetrics | An array of Firewall Diagnostic Metrics categories to collect. [Reference](https://learn.microsoft.com/azure/firewall/monitor-firewall#enable-diagnostic-logging-through-the-azure-portal)
`hubNetworkSecurityGroupDiagnosticsLogs` | NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter | An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. [Reference](https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories)
`hubVirtualNetworkDiagnosticsLogs` | VMProtectionAlerts | An array of Network Diagnostic Logs to enable for the Hub Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs)
`hubVirtualNetworkDiagnosticsMetrics` | AllMetrics | An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics)
`identityNetworkSecurityGroupDiagnosticsLogs` | NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter | An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. [Reference](https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories)
`identityVirtualNetworkDiagnosticsLogs` | VMProtectionAlerts | An array of Network Diagnostic Logs to enable for the Identity Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs)
`identityVirtualNetworkDiagnosticsMetrics` | AllMetrics | An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics)
`keyVaultDiagnosticsLogs` | AuditEvent, AzurePolicyEvaluationDetails | An array of Key Vault Diagnostic Logs categories to collect. [Reference](https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault)
`keyVaultDiagnosticsMetrics` | AllMetrics | The Key Vault Diagnostic Metrics to collect. [Reference](https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault)
`logAnalyticsWorkspaceCappingDailyQuotaGb` | -1 | The daily quota for Log Analytics Workspace logs in Gigabytes. It defaults to "-1" for no quota.
`logAnalyticsWorkspaceRetentionInDays` | 30 | The number of days to retain Log Analytics Workspace logs without Sentinel.
`logAnalyticsWorkspaceSkuName` | PerGB2018 | The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". [Reference](https://learn.microsoft.com/azure/azure-monitor/logs/resource-manager-workspace)
`logStorageSkuName` | Standard_GRS | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". [Reference](https://learn.microsoft.com/rest/api/storagerp/srp_sku_types)
`networkInterfaceDiagnosticsMetrics` | AllMetrics | An array of metrics to enable on the diagnostic setting for network interfaces.
`networkWatcherFlowLogsRetentionDays` | 30 | The number of days to retain Network Watcher Flow Logs.
`networkWatcherFlowLogsType` | VirtualNetwork | The type of network watcher flow logs to enable. It defaults to "VirtualNetwork" since they provide more data and NSG flow logs will be deprecated in June 2025.
`operationsNetworkSecurityGroupDiagnosticsLogs` | NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter | An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. [Reference](https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories)
`operationsVirtualNetworkDiagnosticsLogs` | VMProtectionAlerts | An array of Network Diagnostic Logs to enable for the Operations Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs)
`operationsVirtualNetworkDiagnosticsMetrics` | AllMetrics | An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics)
`publicIPAddressDiagnosticsLogs` | DDoSProtectionNotifications, DDoSMitigationFlowLogs, DDoSMitigationReports | An array of Public IP Address Diagnostic Logs for the Azure Firewall. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/tutorial-resource-logs?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs)
`publicIPAddressDiagnosticsMetrics` | AllMetrics | An array of Public IP Address Diagnostic Metrics for the Azure Firewall. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/tutorial-resource-logs?tabs=DDoSProtectionNotifications)
`sharedServicesNetworkSecurityGroupDiagnosticsLogs` | NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter | An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. [Reference](https://learn.microsoft.com/azure/virtual-network/virtual-network-nsg-manage-log#log-categories)
`sharedServicesVirtualNetworkDiagnosticsLogs` | VMProtectionAlerts | An array of Network Diagnostic Logs to enable for the SharedServices Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs)
`sharedServicesVirtualNetworkDiagnosticsMetrics` | AllMetrics | An array of Network Diagnostic Metrics to enable for the SharedServices Virtual Network. [Reference](https://learn.microsoft.com/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics)

### Azure Policy Initiatives: NISTRev4, NISTRev5, DoD IL5, & CMMC

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the `deployPolicy=true` parameter with `policy` assigned to one of the following: `NISTRev4`, `NISTRev5`, `IL5`, or `CMMC`.

The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deployPolicy` | 'false' | When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".
`policy` | NISTRev4 | [NISTRev4/NISTRev5/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NISTRev4". IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.

Under the [src/bicep/modules/policies](../src/bicep/modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

### Microsoft Defender for Cloud

By default [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when you first set up a subscription and view the Microsoft Defender for Cloud portal blade.

Microsoft Defender for Cloud offers a standard/defender sku which enables a greater depth of awareness including more recomendations and threat analytics. You can enable this higher depth level of security in MLZ by setting the parameter `deployDefender` during deployment. In addition you can include the `emailSecurityContact` parameter to set a contact email for alerts.

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deployDefender` | false | When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".
`deployDefenderPlans` | ['VirtualMachines'] | Paid Workload Protection plans for Defender for Cloud. It defaults to "VirtualMachines".
`defenderSkuTier` | Free | The SKU for Defender for Cloud
`emailSecurityContact` | '' | Email address of the contact, in the form of <john@doe.com>

The Defender plan for Microsoft Defender for Cloud is enabled by default in the following [Azure Environments](https://learn.microsoft.com/powershell/module/servicemanagement/azure.service/get-azureenvironment?view=azuresmps-4.0.0): `AzureCloud`. To enable this for other Azure Cloud environments, this will need to executed manually. Documentation on how to do this can be found [here](https://learn.microsoft.com/azure/defender-for-cloud/enable-enhanced-security).

### Azure Sentinel

[Sentinel](https://learn.microsoft.com/azure/sentinel/overview) is a scalable, cloud-native, security information and event management (SIEM) and security orchestration, automation, and response (SOAR) solution. Sentinel can be enabled using the following setting:

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deploySentinel` | false | When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment.

### Remote Access

#### Azure Gateway Subnet

Create a gateway subnet for the Hub virtual network. Deploying this subnet simplifies the deployment of a virtual network gateway to support a site-to-site VPN or express route connection. Set the following settings to deploy the Gateway Subnet:

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`azureGatewaySubnetAddressPrefix` | 10.0.129.192/26 | The CIDR Subnet Address Prefix for the Azure Gateway Subnet. It must be in the Hub Virtual Network space. It must be /26.
`deployAzureGatewaySubnet` | false | When set to "true", provisions Azure Gateway Subnet only.

#### Azure Bastion

Remotely access the network and resources without exposing them via public endpoints using [Azure Bastion](https://learn.microsoft.com/azure/bastion/). Set the following parameters to configure the Azure Bastion service:

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`bastionDiagnosticsLogs` | BastionAuditLogs | The logs enabled in the diagnostic setting for Bastion.
`bastionDiagnosticsMetrics` | AllMetrics | The metrics enabled in the diagnostic setting for Bastion.
`bastionHostPublicIPAddressAvailabilityZones` | null | The availability zones for the public IP address for Bastion.
`bastionHostSubnetAddressPrefix` | 10.0.128.192/26 | The address prefix for the subnet for Bastion.
`deployBastion` | false | When set to 'true', provisions Azure Bastion Host and virtual machine jumpboxes. It defaults to "false".

#### Windows Jumpbox

Deploy a Windows virtual machine as a jumpbox into the Hub network. The VM must be accessed using Azure Bastion. Set the following values to configure the Windows jumpbox:

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deployWindowsVirtualMachine` | false | When set to 'true', a Windows virtual machine is deployed.
`hybridUseBenefit` | false | The hybrid use benefit provides a discount on virtual machines when a customer has an on-premises Windows Server license with Software Assurance.
`windowsVmAdminPassword` | new guid | The administrator password the Windows virtual machine to Azure Bastion remote into. It must be > 12 characters in length. See [password requirements for creating a Windows VM](https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-).
`windowsVmAdminUsername` | xadmin | The administrator username for the Windows virtual machine for remote access.
`windowsVmCreateOption` | FromImage | The create option for the disk on the Windows virtual machine.
`windowsVmImageOffer` | WindowsServer | The marketplace image offer for the Windows virtual machine.
`windowsVmImagePublisher` | MicrosoftWindowsServer | The marketplace image publisher for the Windows virtual machine.
`windowsVmImageSku` | 2019-datacenter-gensecond | The marketplace image SKU for the Windows virtual machine.
`windowsVmNetworkInterfacePrivateIPAddressAllocationMethod` | Dynamic | The public IP Address allocation method for the Windows virtual machine.
`windowsVmSize` | Standard_D2s_v3 | The size for the Windows virtual machine.
`windowsVmStorageAccountType` | StandardSSD_LRS | The disk SKU for the Windows virtual machine.
`windowsVmVersion` | latest | The marketplace image version for the Windows virtual machine.

#### Linux Jumpbox

Deploy a Linux virtual machine as a jumpbox into the Hub network. The VM must be accessed using Azure Bastion. Set the following values to configure the Linux jumpbox:

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`deployLinuxVirtualMachine` | false | When set to 'true', a Linux virtual machine is deployed.
`linuxNetworkInterfacePrivateIPAddressAllocationMethod` | Dynamic | The allocation method for the private IP address on the Linux virtual machine.
`linuxVmAdminPasswordOrKey` | new guid | The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See [password requirements for creating a Linux VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm-).
`linuxVmAdminUsername` | xadmin | The administrator username for the Linux Virtual Machine to Azure Bastion remote into.
`linuxVmAuthenticationType` | 'password' | [sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".
`linuxVmImageOffer` | 0001-com-ubuntu-server-focal | The marketplace image offer for Linux images.
`linuxVmImagePublisher` | Canonical | The marketplace image publisher for Linux images.
`linuxVmImageSku` | 20_04-lts-gen2 | The marketplace image SKU for Linux images.
`linuxVmOsDiskCreateOption` | FromImage | The disk creation option of the Linux Virtual Machine for remote access.
`linuxVmOsDiskType` | Standard_LRS | The disk SKU of the Linux Virtual Machine.
`linuxVmSize` | Standard_D2s_v3 | The size for the Linux virtual machine.

#### Other Settings

Parameter Name | Default Value | Description
:------------- | :------------ | :----------
`supportedClouds` | AzureCloud, AzureUSGovernment | The Azure clouds that support specific service features.
`tags` | {} | A string dictionary of tags to add to deployed resources. [Reference](https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates)

### Modifying the Naming Conventions

MLZ resources are named according to the naming conventions defined in the following bicep file: [src/bicep/modules/naming-convention.bicep](../../src/bicep/modules/naming-convention.bicep)

There are two conventions used, depending on the type of resource. One convention is used to signify the relationship between itself and parent resources so the name contains a service token. The other convention is the same except it lacks the service token. Global resources, like storage accounts, use the unique string function to create names that will prevent collisions with other Azure customers.

When modifying the naming conventions, be sure to only reorder the components or remove components for the `namingConvention` and `namingConvention_Service` variables.

> [!WARNING]
> When changing any bicep files, be sure to compile the changes to JSON.

## Deploy MLZ

Use the `New-AzSubscriptionDeployment` PowerShell cmdlet or the `az deployment sub` AZ CLI command to deploy MLZ across one or many subscriptions.

### Connect to Azure

Before executing an Azure deployment, first ensure you are connected. Use the following examples to connect to any of the supported Azure clouds:

```PowerShell
# PowerShell
Connect-AzAccount -Environment '<Azure Cloud Name>' -UseDeviceAuthentication
```

```BASH
# AZ CLI
az cloud set -n '<Azure Cloud Name>'
az login
```

### Single Subscription Deployment

To deploy MLZ into a single subscription, specify the values for the resource prefix, location, and template file.

```PowerShell
# PowerShell
New-AzSubscriptionDeployment `
  -Location 'eastus' `
  -TemplateFile '.\mlz.json' `
  -resourcePrefix 'mlz' 
```

```BASH
# AZ CLI
az deployment sub create \
  --location 'eastus' \
  --template-file './mlz.json' \
  --parameters resourcePrefix='mlz'
```

### Multiple Subscription Deployment

To deploy MLZ into multiple subscriptions, specifiy the value for the resource prefix, location, template file, and each tier's subscription ID:

```PowerShell
# PowerShell
New-AzSubscriptionDeployment `
  -Location 'eastus' `
  -TemplateFile '.\mlz.json' `
  -resourcePrefix 'mlz' `
  -hubSubscriptionId $hubSubscriptionId `
  -identitySubscriptionId $identitySubscriptionId `
  -operationsSubscriptionId $operationsSubscriptionId `
  -sharedServicesSubscriptionId $sharedServicesSubscriptionId
```

```Bash
# AZ CLI
az deployment sub create \
  --subscription $deploymentSubscription \
  --location 'eastus' \
  --template-file './mlz.json' \
  --parameters \
      resourcePrefix='mlz' \
      hubSubscriptionId=$hubSubscriptionId \
      identitySubscriptionId=$identitySubscriptionId \
      operationsSubscriptionId=$operationsSubscriptionId \
      sharedServicesSubscriptionId=$sharedServicesSubscriptionId
```

#### Reference Deployment Output

After you've deployed Mission Landing Zone you can integrate [add-ons](../../src/bicep/add-ons/README.md) with the output of MLZ. PowerShell, Azure CLI, and JMESpath queries allow you to retrieve outputs from a deployment and pass them as parameters into another deployment.

- **PowerShell:** use the `Get-AzSubscriptionDeployment` cmdlet.
- **Azure CLI:** use the `az deployment sub show` command with a `--query` argument to retrieve information about the resources you deployed.

In this example, MLZ was deployed using a deployment name of `myMissionLandingZone`. The deployment name is the `name` parameter you set on `az deployment sub create` or `New-AzSubscriptionDeployment`.

When an MLZ deployment is complete, you can see all the resources provisioned in that deployment by querying the `outputs` property:

```PowerShell
# PowerShell
(Get-AzSubscriptionDeployment -Name myMissionLandingZone).outputs | ConvertTo-Json
```

```BASH
# AZ CLI
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs"
```

If you need a single property value you can retrieve it like this:

```BASH
# AZ CLI
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs.firewallPrivateIPAddress.value"
```

```PowerShell
# PowerShell
(Get-AzSubscriptionDeployment -Name myMissionLandingZone).outputs.firewallPrivateIPAddress
```

If you want to export the data for use in other ARM template deployments, like the [shared variable file pattern](https://learn.microsoft.com/azure/azure-resource-manager/bicep/patterns-shared-variable-file), you can export the outputs to a json file.

```PowerShell
# PowerShell
(Get-AzSubscriptionDeployment -Name myMissionLandingZone).outputs `
  | ConvertTo-Json `
  | Out-File -FilePath .\deploymentVariables.json
```

```BASH
# AZ CLI
az deployment sub show \
  --name "myMissionLandingZone" \
  --query "properties.outputs" > ./deploymentVariables.json
```

## Remove MLZ

The Bicep/ARM deployment of Mission Landing Zone can be deleted with these steps:

1. Delete all resource groups.
1. Delete the diagnostic settings deployed at the subscription level.
1. If Microsoft Defender for Cloud was deployed (parameter `deployDefender=true` was used) then remove subscription-level policy assignments and downgrade the Microsoft Defender for Cloud pricing tiers.

> [!WARNING]
> If you deploy and delete Mission Landing Zone in the same subscription multiple times without deleting the subscription-level diagnostic settings, the sixth deployment will fail. Azure has a limit of five diagnostic settings per subscription. The error will be similar to this: `"The limit of 5 diagnostic settings was reached."`

To delete the diagnostic settings from the Azure Portal: choose the subscription blade, then Activity log in the left panel. At the top of the Activity log screen click the Diagnostics settings button. From there you can click the Edit setting link and delete the diagnostic setting.

To delete the diagnotic settings in script, use the AZ CLI or PowerShell. An AZ CLI example is below:

```BASH
# View diagnostic settings in the current subscription
az monitor diagnostic-settings subscription list --query value[] --output table

# Delete a diagnostic setting
az monitor diagnostic-settings subscription delete --name <diagnostic setting name>
```

To delete the subscription-level policy assignments in the Azure portal:

1. Navigate to the Policy page and select the Assignments tab in the left navigation bar.
1. At the top, in the Scope box, choose the subscription(s) that contain the policy assignments you want to remove.
1. In the table click the ellipsis menu ("...") and choose "Delete assignment".

To delete the subscription-level policy assignments using the AZ CLI:

```BASH
# View the policy assignments for the current subscription
az policy assignment list -o table --query "[].{Name:name, DisplayName:displayName, Scope:scope}"

# Remove a policy assignment in the current subscription scope.
az policy assignment delete --name "<name of policy assignment>"
```

To downgrade the Microsoft Defender for Cloud pricing level in the Azure portal:

1. Navigate to the Microsoft Defender for Cloud page, then click the "Environment settings" tab in the left navigation panel.
1. In the tree/grid select the subscription you want to manage.
1. Click the large box near the top of the page that says "Enhanced security off".
1. Click the save button.

To downgrade the Microsoft Defender for Cloud pricing level using the AZ CLI:

```BASH
# List the pricing tiers
az security pricing list -o table --query "value[].{Name:name, Tier:pricingTier}"

# Change a pricing tier to the default free tier
az security pricing create --name "<name of tier>" --tier Free
```

> [!NOTE]
> The Azure portal allows changing all pricing tiers with a single setting, but the AZ CLI requires each setting to be managed individually.

## References

- [Azure CLI - az deployment](https://learn.microsoft.com/cli/azure/deployment?view=azure-cli-latest)
- [Azure PowerShell](https://learn.microsoft.com/powershell/azure/what-is-azure-powershell)
- [Bicep documentation](https://aka.ms/bicep/)
- [JMESPath queries](https://jmespath.org/)
