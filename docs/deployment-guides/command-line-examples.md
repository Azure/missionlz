# Mission Landing Zone - Example command line deployment

Powershell or Az Cli commands can be used to deploy MLZ and add-ons from a command line.   To do this a parameter file and the solution or main bicep file are needed, as well as any additional secure parameters like passwords or shared keys.  This document provides some examples for reference, as well as some pre-requistes that will be required.

## Table of Contents

- [Prerequistes](#prerequistes)
- [Preparing Parameter File](#preparing-parameter-file)
- [Powershell](#powershell)

## Prerequistes

The following are prerequists that need to be installed and configured.  Additionally, knowledge of how to use the toolset is assumed.

1. Visual Studio Code
2. Az Cli installed
3. Az POSH module installed
4. Knowledge of how to use bicep to generate ARM Templates and parameter files, both JSON and bicep types.

## Preparing Parameter File

In order to deploy from command line tools, it is important to prepare a parameters file for the deployment.  Ideally, just use the bicep option and do not use JSON.   Addtionally, get all parameters, not just required parameters, this is so default settings can be overridden if needed.

[Use Visual Studio Code to generate a parameter file.](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files?tabs=Bicep)

Once the bicep parameters file is created, go through the file in Visual Studio code and define the values needed for deployment.  The example provided is generated from the mlz.bicep file.  Comments are provided in the bicep below for guidance only.  Additional guidance can be found by using the Template Spec deployment option and using the portal GUI, or referencing the mlz.bicep file directly.

Values that have a default setting that will not be changed, should just be removed from the parameter file.  Some parameters are required to be removed as they are dynamically determined at deployment time by the resource provider, these are:

### Parameter that must be removed from file

```bicep
param deploymentNameSuffix = ? // REMOVE THIS OR DEPLOYMENT WILL FAIL  
```

### MLZ Parameter File Example

```bicep
using './mlz.bicep'

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param azureGatewaySubnetAddressPrefix = '10.0.129.192/26'

// Recommend leaving default, remove.
param bastionDiagnosticsLogs = [
  {
    category: 'BastionAuditLogs'
    enabled: true
  }
]

// Recommend leaving default, remove.
param bastionDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend leaving default, remove.
param bastionHostPublicIPAddressAvailabilityZones = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param bastionHostSubnetAddressPrefix = '10.0.128.192/26'

// Recommend leaving default, remove.
param defenderSkuTier = 'Free'

// Recommend setting to 'true' if the VPN gateway add-on is to be used.
param deployAzureGatewaySubnet = false

// Recommend setting to 'true' if an administrative VM (Linux or Windows) is being deployed.
param deployBastion = false

// Recommend leaving default, remove.
param deployDefender = true

// Recommend leaving default, remove.
param deployDefenderPlans = [
  'VirtualMachines'
]

// Recommend setting to 'true' if using Active Directory or Entra Domain services. The domain controllers should be deployed in this spoke after MLZ is deployed.
param deployIdentity = false

// Set to 'true' if a Linux administrative VM is needed in the hub.
param deployLinuxVirtualMachine = false

// REMOVE THIS OR DEPLOYMENT WILL FAIL.
param deploymentNameSuffix = ?

// Recommend setting to 'true' if traffic analysis needs to be available immediately.
param deployNetworkWatcherTrafficAnalytics = false

// Recommend setting to 'true' if NIST or other policy is selected.
param deployPolicy = false

// Recommend setting to 'true', can be enabled after deployment in the portal.
param deploySentinel = false

// Recommend setting to 'true' if an administrative VM is required in the hub.
param deployWindowsVirtualMachine = false

// Recommend leaving default, remove. The firewall is set to be the DNS server for all hub and spokes; this address is the Azure DNS that the firewall will proxy DNS requests to.
param dnsServers = [
  '168.63.129.16'
]

// Recommend setting to a valid security contact email address.
param emailSecurityContact = ''

// Recommend leaving default, remove.
param enableProxy = true

// Set for naming, allows values enforced. Accepted values: dev, test, or prod.
param environmentAbbreviation = 'dev'

// If the subscription already has an existing network watcher prior to deployment, go in the portal and find it, then go to properties and get the resource ID for it and put it here. Else, remove, and a network watcher will be created by the deployment.
param existingHubNetworkWatcherResourceId = ''

// Same as above, but for the identity spoke if deployed in a separate subscription.
param existingIdentityNetworkWatcherResourceId = ''

// Same as above, but for the operations spoke if deployed in a separate subscription.
param existingOperationsNetworkWatcherResourceId = ''

// Same as above, but for the shared services spoke if deployed in a separate subscription.
param existingSharedServicesNetworkWatcherResourceId = ''

// Recommend leaving default, remove.
param firewallClientPublicIPAddressAvailabilityZones = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param firewallClientSubnetAddressPrefix = '10.0.128.0/26'

// Recommend leaving default, remove.
param firewallDiagnosticsLogs = [
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

// Recommend leaving default, remove.
param firewallDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend leaving default, remove.
param firewallIntrusionDetectionMode = 'Alert'

// Recommend leaving default, remove.
param firewallManagementPublicIPAddressAvailabilityZones = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param firewallManagementSubnetAddressPrefix = '10.0.128.64/26'

// Replace with 'Standard' or 'Basic' based on requirements.
param firewallSkuTier = 'Premium'

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param firewallSupernetIPAddress = '10.0.128.0/18'

// Recommend leaving default, remove.
param firewallThreatIntelMode = 'Alert'

// Recommend leaving default, remove.
param hubNetworkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

// Recommend leaving default, remove.
param hubNetworkSecurityGroupRules = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param hubSubnetAddressPrefix = '10.0.128.128/26'

// Replace subscription().subscriptionId with the actual target subscription for the hub network resources.
param hubSubscriptionId = subscription().subscriptionId

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param hubVirtualNetworkAddressPrefix = '10.0.128.0/23'

// Recommend leaving default, remove.
param hubVirtualNetworkDiagnosticsLogs = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

// Recommend leaving default, remove.
param hubVirtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend leaving default, remove.
param hybridUseBenefit = false

// Recommend leaving default, remove.
param identityNetworkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

// Recommend leaving default, remove.
param identityNetworkSecurityGroupRules = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param identitySubnetAddressPrefix = '10.0.130.0/24'

// Replace subscription().subscriptionId with the actual target subscription for the identity network resources, if deploying an identity spoke.
param identitySubscriptionId = subscription().subscriptionId

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param identityVirtualNetworkAddressPrefix = '10.0.130.0/24'

// Recommend default settings, remove.
param identityVirtualNetworkDiagnosticsLogs = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

// Recommend default settings, remove.
param identityVirtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend default settings, remove.
param keyVaultDiagnosticsLogs = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]

// Recommend default settings, remove.
param keyVaultDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend default settings, remove.
param linuxNetworkInterfacePrivateIPAddressAllocationMethod = 'Dynamic'

// Recommend default settings, remove.
param linuxVmAdminPasswordOrKey = deployLinuxVirtualMachine ? '' : newGuid()

// Set the desired local admin name for Linux VM deployment.
param linuxVmAdminUsername = 'xadmin'

// Recommend default setting, remove.
param linuxVmAuthenticationType = 'password'

// Recommend default setting, remove.
param linuxVmImageOffer = '0001-com-ubuntu-server-focal'

// Recommend default setting, remove.
param linuxVmImagePublisher = 'Canonical'

// Recommend default setting, remove.
param linuxVmImageSku = '20_04-lts-gen2'

// Recommend default setting, remove.
param linuxVmOsDiskCreateOption = 'FromImage'

// Recommend default setting, remove.
param linuxVmOsDiskType = 'Standard_LRS'

// Recommend default setting, remove.
param linuxVmSize = 'Standard_D2s_v3'

// Set value to the appropriate region, like usgovvirginia, or usgovarizona, or other valid Azure location.
param location = deployment().location

// Recommend default setting, remove.
param logAnalyticsWorkspaceCappingDailyQuotaGb = -1

// Recommend default setting, remove.
param logAnalyticsWorkspaceRetentionInDays = 30

// Recommend default setting, remove.
param logAnalyticsWorkspaceSkuName = 'PerGB2018'

// Recommend default setting, remove.
param logStorageSkuName = 'Standard_GRS'

// Recommend default setting, remove.
param networkInterfaceDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend default setting, remove.
param networkWatcherFlowLogsRetentionDays = 30

// Recommend default setting, remove.
param networkWatcherFlowLogsType = 'VirtualNetwork'

// Recommend default setting, remove.
param operationsNetworkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

// Recommend default setting, remove.
param operationsNetworkSecurityGroupRules = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param operationsSubnetAddressPrefix = '10.0.131.0/24'

// Replace subscription().subscriptionId with the actual target subscription for the operations network resources.
param operationsSubscriptionId = subscription().subscriptionId

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param operationsVirtualNetworkAddressPrefix = '10.0.131.0/24'

// Recommend default setting, remove.
param operationsVirtualNetworkDiagnosticsLogs = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

// Recommend default setting, remove.
param operationsVirtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend default setting, remove.
param policy = 'NISTRev4'

// Recommend default setting, remove.
param publicIPAddressDiagnosticsLogs = [
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

// Recommend default setting, remove.
param publicIPAddressDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// define the prefix for naming all objects being created, like "mlz", or other meaningful representation, like "fin", or "gbl".
param resourcePrefix = ''

// Recommend default setting, remove.
param sharedServicesNetworkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

// Recommend default setting, remove.
param sharedServicesNetworkSecurityGroupRules = []

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param sharedServicesSubnetAddressPrefix = '10.0.132.0/24'

// Replace subscription().subscriptionId with the actual target subscription for the shared services network resources.
param sharedServicesSubscriptionId = subscription().subscriptionId

// Default address prefix, can be redefined, but planned first and Azure networking knowledge is required.
param sharedServicesVirtualNetworkAddressPrefix = '10.0.132.0/24'

// Recommend default setting, remove.
param sharedServicesVirtualNetworkDiagnosticsLogs = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

// Recommend default setting, remove.
param sharedServicesVirtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

// Recommend default setting, remove.
param supportedClouds = [
  'AzureCloud'
  'AzureUSGovernment'
]

// Recommend default setting, remove.
param tags = {}

// This will be passed in on deployment execution, remove.
param windowsVmAdminPassword = deployWindowsVirtualMachine ? '' : newGuid()

// Set to the desired local admin name for VM.
param windowsVmAdminUsername = 'xadmin'

// Recommend default setting, remove.
param windowsVmCreateOption = 'FromImage'

// Recommend default setting, remove.
param windowsVmImageOffer = 'WindowsServer'

// Recommend default setting, remove.
param windowsVmImagePublisher = 'MicrosoftWindowsServer'

// Recommend default setting, remove.
param windowsVmImageSku = '2019-datacenter-gensecond'

// Recommend default setting, remove.
param windowsVmNetworkInterfacePrivateIPAddressAllocationMethod = 'Dynamic'

// Recommend default setting, remove.
param windowsVmSize = 'Standard_DS1_v2'

// Recommend default setting, remove.
param windowsVmStorageAccountType = 'StandardSSD_LRS'

// Recommend default setting, remove.
param windowsVmVersion = 'latest'

// Define new collection groups or add rules to existing. The rules provided in this default need to remain for allowing any Azure Monitor agents deployed later in spoke networks to connect to the Log Analytics Workspace.
param firewallRuleCollectionGroups = [
  {
    name: 'MLZ-NetworkCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          name: 'AzureMonitor'
          priority: 150
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowMonitorToLAW'
              ruleType: 'NetworkRule'
              ipProtocols: ['Tcp']
              sourceAddresses: concat(
                [
                  hubVirtualNetworkAddressPrefix // Hub network
                ],
                [
                  sharedServicesVirtualNetworkAddressPrefix // Shared network
                ],
                empty(identityVirtualNetworkAddressPrefix) ? [] : [identityVirtualNetworkAddressPrefix] // Include Identity network only if it has a value
              )
              destinationAddresses: [cidrHost(operationsVirtualNetworkAddressPrefix, 3)] // LAW private endpoint network
              destinationPorts: ['443'] // HTTPS port for Azure Monitor
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: []
            }
          ]
        }
      ]
    }
  }
]
```

## Powershell

This section will detail using POSH to perform the subscription deployment using the parameter file prepared above.  Similar effects can be done using az cli deployment option as well, however password or other items that may need to be secured must be sent as clear text.   For that reason, the az cli option will not be covered in this document.

### Special Note

In order for Powershell to deploy using bicep files (instead of JSON ARM Templates), you will have to include the path to bicep.exe in the system path of the machine executing the deployment.  

The script below will add the path specified into the system path.

```powershell
##Add bicep path to system path
# Define the path to bicep.exe, typcial path is C:\Users\<user>\.azure\bin
$pathToAdd = ""

# Get the current PATH for the user
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

# Check if the path is already in the PATH variable
if ($currentPath -notlike "*$pathToAdd*") {
    # Add the new path to the existing PATH
    $newPath = $currentPath + ";" + $pathToAdd

    # Update the PATH environment variable for the user
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)

    Write-Host "The path '$pathToAdd' has been added to your PATH."
} else {
    Write-Host "The path '$pathToAdd' is already in your PATH."
}
```

### Secure password

MLZ, if a VM is being deployed, requires that a password be sent for use as the local admin password.   To do this securely, the best option is to use POSH to store the password as a secure string and send it as an extra parameter in the deployment command.

```powershell
$securePwd = Read-Host "Enter your password" -AsSecureString
```

Running the above command will prompt for a password to be entered, obfuscated from view, and stored as a securestring to be passed in as a value.

### Run the deployment

- **Name:** is the name of the deployment when running in Azure.   It can be seen on the "hub" subscription deployments page in the Azure portal once executing.
- **Location:** is the valid Azure region the deployment should target, like usgovarizona, or other.
- **TemplateFile:** is the relative or absolute path to the main bicep deployment, like mlz.bicep, or solution.bicep.
- **TemplateParameterFile** is the relative or absolute path to the parameter file being used to feed values to the main bicep code file, overriding defaults as defined.  
- **windowsVMAdminPassword** is a param value in the main bicep file that does not have a default provided.   Using powershell allows the securestring method to keep passwords in clear text from being used.  Other values can be added on as necessary or needed to override individual values that are not in the parameter file itself.


```powershell
#mlz deployment posh
New-AzSubscriptionDeployment `
  -Name "<NameOfDeployment>" `
  -Location "<ValidAzureLocation/Region>" `
  -TemplateFile "<PathTo Mlz.bicep>" `
  -TemplateParameterFile "<PathTo Mlz.bicepparam>" `
  -windowsVmAdminPassword $securePwd
  ```

  CI/CD pipelines methods can be wrapped around this deployment method to implement Infrastructure as Code models.   Details of this are not covered by MLZ documentation.

