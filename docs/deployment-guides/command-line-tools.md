# Mission Landing Zone - Deployment Guide using Command Line Tools

[**Home**](../../README.md) | [**Design**](../design.md) | [**Add-Ons**](../../src/bicep/add-ons/README.md) | [**Resources**](../resources.md)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Planning](#planning)
- [Deploy MLZ](#deploy-mlz)
- [Remove MLZ](#remove-mlz)
- [References](#references)

This guide describes how to deploy Mission Landing Zone (MLZ) using the ARM template at [src/bicep/mlz.json](../src/bicep/mlz.json) using either Azure CLI or Azure PowerShell. The supported clouds for this guide include the Azure Commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret.

MLZ has only one required parameter and provides sensible defaults for the rest, allowing for simple deployments that specify only the parameters that need to differ from the defaults. See the [README.md](../src/bicep/README.md) document in the **src/bicep** folder for a complete list of parameters.

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

### Decide on a Resource Prefix

Resource Groups and resource names are derived from the required parameter `resourcePrefix`. Pick a unqiue resource prefix that is 1-6 alphanumeric characters in length without whitespaces.

### One Subscription or Multiple

MLZ can deploy to a single subscription or multiple subscriptions. A test and evaluation deployment may deploy everything to a single subscription, and a production deployment may place each tier into its own subscription.

The optional parameters related to subscriptions are below. They default to the subscription used for deployment.

Parameter name | Default Value | Description
:------------- | :------------ | :----------
`hubSubscriptionId` | Deployment subscription | Subscription containing the firewall and network hub
`identitySubscriptionId` | Deployment subscription | Tier 0 for identity solutions
`operationsSubscriptionId` | Deployment subscription | Tier 1 for network operations and security tools
`sharedServicesSubscriptionId` | Deployment subscription | Tier 2 for shared services

### Networking

The following parameters affect networking. Each virtual network and subnet has been given a default address prefix to ensure they fall within the default super network. Refer to the [Networking page](../networking.md) for all the default address prefixes.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`hubVirtualNetworkAddressPrefix` | '10.0.128.0/23' | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.
`hubSubnetAddressPrefix` | '10.0.128.128/26' | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.
`firewallClientSubnetAddressPrefix` | '10.0.128.0/26' | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.
`firewallManagementSubnetAddressPrefix` | '10.0.128.64/26' | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.
`identityVirtualNetworkAddressPrefix` | '10.0.130.0/24' | The CIDR Virtual Network Address Prefix for the Identity Virtual Network.
`identitySubnetAddressPrefix` | '10.0.130.0/24' | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.
`operationsVirtualNetworkAddressPrefix` | '10.0.131.0/24' | The CIDR Virtual Network Address Prefix for the Operations Virtual Network.
`operationsSubnetAddressPrefix` | '10.0.131.0/24' | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.
`sharedServicesVirtualNetworkAddressPrefix` | '10.0.132.0/24' | The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.
`sharedServicesSubnetAddressPrefix` | '10.0.132.0/24' | The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.

### Optional Features

MLZ has optional features that can be enabled by setting parameters on the deployment.

#### Azure Policy Initiatives: NISTRev4, NISTRev5, IL5, CMMC

To include one of the built in Azure policy initiatives for NIST 800-53, CMMC Level 3 or DoD IL5 compliance add the `deployPolicy=true` parameter with `policy` assigned to one of the following: `NISTRev4`, `NISTRev5`, `IL5`, or `CMMC`.

The result will be a policy assignment created for each resource group deployed by MLZ that can be viewed in the 'Compliance' view of Azure Policy in the Azure Portal.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deployPolicy` | 'false' | When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".
`policy` | 'NISTRev4' | [NISTRev4/NISTRev5/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NISTRev4". IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.

Under the [src/bicep/modules/policies](../src/bicep/modules/policies) directory are JSON files named for the initiatives with default parameters (except for a Log Analytics workspace ID value `<LAWORKSPACE>` that we substitute at deployment time -- any other parameter can be modified as needed).

#### Microsoft Defender for Cloud

By default [Microsoft Defender for Cloud](https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction) offers a free set of monitoring capabilities that are enabled via an Azure policy when you first set up a subscription and view the Microsoft Defender for Cloud portal blade.

Microsoft Defender for Cloud offers a standard/defender sku which enables a greater depth of awareness including more recomendations and threat analytics. You can enable this higher depth level of security in MLZ by setting the parameter `deployDefender` during deployment. In addition you can include the `emailSecurityContact` parameter to set a contact email for alerts.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deployDefender` | 'false' | When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".
`deployDefenderPlans` | '['VirtualMachines']' | Paid Workload Protection plans for Defender for Cloud. It defaults to "VirtualMachines".
`emailSecurityContact` | '' | Email address of the contact, in the form of <john@doe.com>

The Defender plan for Microsoft Defender for Cloud is enabled by default in the following [Azure Environments](https://learn.microsoft.com/powershell/module/servicemanagement/azure.service/get-azureenvironment?view=azuresmps-4.0.0): `AzureCloud`. To enable this for other Azure Cloud environments, this will need to executed manually. Documentation on how to do this can be found [here](https://learn.microsoft.com/azure/defender-for-cloud/enable-enhanced-security).

#### Azure Sentinel

[Sentinel](https://docs.microsoft.com/en-us/azure/sentinel/overview) is a scalable, cloud-native, security information and event management (SIEM) and security orchestration, automation, and response (SOAR) solution. Sentinel can be enabled by setting the `deploySentinel=true` parameter.

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`deploySentinel` | 'false' | When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace created in this deployment. It defaults to "false".

#### Remote Access

If you want to remotely access the network and the resources you've deployed, you can use [Azure Bastion](https://learn.microsoft.com/azure/bastion/) to remotely access virtual machines within the network without exposing them via Public IP Addresses.

Deploy a Linux or Windows virtual machine as jumpboxes into the network without a Public IP Address using Azure Bastion Host by providing values for these parameters:

Parameter name | Default Value | Description
-------------- | ------------- | -----------
`bastionDiagnosticsLogs` | BastionAuditLogs | The logs enabled in the diagnostic setting for Bastion.
`bastionHostPublicIPAddressAvailabilityZones` | null | The availability zones for the public IP address for Bastion.
`bastionHostSubnetAddressPrefix` | 10.0.128.192/26 | The address prefix for the subnet for Bastion.
`deployBastion` | false | When set to 'true', provisions Azure Bastion Host and virtual machine jumpboxes. It defaults to "false".
`deployLinuxVirtualMachine` | false | When set to 'true', a Linux virtual machine is deployed.
`deployWindowsVirtualMachine` | false | When set to 'true', a Windows virtual machine is deployed.
`linuxNetworkInterfacePrivateIPAddressAllocationMethod` | Dynamic | The allocation method for the private IP address on the Linux virtual machine.
`linuxVmImageOffer` | 0001-com-ubuntu-server-focal | The marketplace image offer for Linux images.
`linuxVmImagePublisher` | Canonical | The marketplace image publisher for Linux images.
`linuxVmImageSku` | 20_04-lts-gen2 | The marketplace image SKU for Linux images.
`linuxVmOsDiskType` | Standard_LRS | The disk SKU of the Linux Virtual Machine.
`linuxVmAdminPasswordOrKey` | new guid | The administrator password or public SSH key for the Linux Virtual Machine to Azure Bastion remote into. See [password requirements for creating a Linux VM](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm-).
`linuxVmAdminUsername` | 'azureuser' | The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`linuxVmAuthenticationType` | 'password' | [sshPublicKey/password] The authentication type for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "password".
`linuxVmSize` | Standard_D2s_v3 | The size for the Linux virtual machine.
`windowsVmAdminPassword` | new guid | The administrator password the Windows Virtual Machine to Azure Bastion remote into. It must be > 12 characters in length. See [password requirements for creating a Windows VM](https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-).
`windowsVmAdminUsername` | 'azureuser' | The administrator username for the Linux Virtual Machine to Azure Bastion remote into. It defaults to "azureuser".
`windowsVmCreateOption` | FromImage | The create option for the disk on the Windows virtual machine.
`windowsVmOffer` | WindowsServer | The marketplace image offer for the Windows virtual machine.
`windowsVmPublisher` | MicrosoftWindowsServer | The marketplace image publisher for the Windows virtual machine.
`windowsVmSize` | Standard_D2s_v3 | The size for the Windows virtual machine.
`windowsVmSku` | 2019-datacenter-gensecond | The marketplace image SKU for the Windows virtual machine.
`windowsVmStorageAccountType` | StandardSSD_LRS | The disk SKU for the Windows virtual machine.
`windowsVmVersion` | latest | The marketplace image version for the Windows virtual machine.

#### Azure Firewall Premium

By default, MLZ deploys **[Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features). Not all regions support Azure Firewall Premium.** Check here to [see if the region you're deploying to supports Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features#supported-regions). If necessary you can set a different firewall SKU or location.

You can manually specify which SKU of Azure Firewall to use for your deployment by specifying the `firewallSkuTier` parameter. This parameter only accepts values of `Premium`, `Standard`, or `Basic`.

Parameter name    | Default Value | Description
:---------------- | :------------ | :----------
`firewallSkuTier` | 'Premium'     | [Standard/Premium/Basic] The SKU for Azure Firewall. It defaults to "Premium".

If you'd like to specify a different region to deploy your resources into, change the location of the deployment. For example, when using the AZ CLI set the deployment command's `--location` argument.

### Naming Conventions

<!-- markdownlint-disable MD013 -->
Mission Landing Zone resources are named according to the naming convention defined in the [src/bicep/modules/naming-convention.bicep](../../src/bicep/modules/naming-convention.bicep) file. There are two different conventions used, depending on the type of resource. One convention is used to signify the relationship between itself and parent resources so the name contains a service token. The other convention is essentially the same, minus the service token. For global resources, like storage accounts, the unique string function is used to create names that will prevent collisions with other Azure customers.
<!-- markdownlint-enable MD013 -->

#### Modifying the Naming Convention

You can modify MLZ's default naming convention to suit your needs by updating the [src/bicep/modules/naming-convention.bicep](../../src/bicep/modules/naming-convention.bicep) file. To avoid breaking the code, be sure to only reorder the components or remove components for the `namingConvention` and `namingConvention_Service` variables.

> [!WARNING]
> If you change a bicep file in the repository, be sure to compile the changes to JSON when you're done.

## Deploy MLZ

Use the `New-AzSubscriptionDeployment` PowerShell cmdlet or the `az deployment sub` AZ CLI command to deploy MLZ across one or many subscriptions.

### Connect to Azure

Before deploying to Azure, you first need to ensure your session is connected to Azure. Use the following examples to connect to any of the supported Azure clouds:

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

To deploy Mission LZ into a single subscription, give your deployment a name and a location and specify the `./mlz.json` template file.

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

Deployment to multiple subscriptions requires specifying the subscription IDs for each tier:

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
