# Azure Virtual Desktop Solution

[**Home**](../README.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Troubleshooting**](./troubleshooting.md)

## Prerequisites

To successfully deploy this solution, you will need to ensure the following prerequisites have been completed:

### Required

- **Licenses:** ensure you have the [required licensing for AVD](https://learn.microsoft.com/en-us/azure/virtual-desktop/overview#requirements).
- **Artifacts:** the deployment of this solution depends on many artifacts that must be hosted in Azure Blobs, ideally in the MLZ operations storage account.
  - [AVD Agent](https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv)
  - [AVD Agent Boot Loader](https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH)
  - [Azure PowerShell AZ Module](https://github.com/Azure/azure-powershell/releases/download/v10.2.0-August2023/Az-Cmdlets-10.2.0.37547-x64.msi)
  - [PowerShell Scripts](https://github.com/jamasten/AzureVirtualDesktop/tree/main/artifacts)
- **Azure Permissions:** ensure the principal deploying the solution has "Owner" and "Key Vault Administrator" roles assigned on the target Azure subscription. This solution contains many role assignments at different scopes and deploys a key vault with keys and secrets to enhance security.
- **Security Group:** create a security group for your AVD users.
  - AD DS: create the group in ADUC and ensure the group has synchronized to Azure AD.
  - Azure AD: create the group.
  - Azure AD DS: create the group in Azure AD and ensure the group has synchronized to Azure AD DS.
- **Disk Encryption:** the "encryption at host" feature is deployed on the virtual machines to meet Zero Trust compliance. This feature is not enabled in your Azure subscription by default and must be manually enabled. Use the following steps to enable the feature: [Enable Encryption at Host](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal).
- **Enable AVD Private Link** this feature is not enabled on subscriptions by default. Use the following link to enable AVD Private Link on your subscription: [Enable the Feature](https://learn.microsoft.com/azure/virtual-desktop/private-link-setup?tabs=portal%2Cportal-2#enable-the-feature)

### Optional

- **Domain Services:** if you plan to domain or hybrid join the session hosts, ensure Active Directory Domain Services or Entra Domain Services is available in your enviroment and that you are synchronizing the required objects. AD Sites & Services should be configured for the address space of your Azure virtual network if you are extending your on premises Active Directory infrastruture into the cloud.
- **DNS:** if you plan to domain or hybrid join the sessions hosts, you must configure your DNS server in the MLZ Identity virtual network with ONE of the following options to support Private Link:
  - DNS forwarder points to the [Azure VIP, 168.63.129.16](https://learn.microsoft.com/azure/virtual-network/what-is-ip-address-168-63-129-16).
  - Conditional forwarders for the [Azure private DNS zones](https://learn.microsoft.com/azure/private-link/private-endpoint-dns) in the Hub resource group that point to the [Azure VIP, 168.63.129.16](https://learn.microsoft.com/azure/virtual-network/what-is-ip-address-168-63-129-16).
- **Domain Permissions** if using domain services, create a principal to domain join the session hosts and Azure Files, if applicable.
  - Active Directory Domain Services: ensure the principal has the following permissions.
    - "Join the Domain" on the domain
    - "Create Computer" on the parent OU or domain
    - "Delete Computer" on the parent OU or domain
  - Entra Domain Services: ensure the principal is a member of the "AAD DC Administrators" group in Azure AD.
- **FSLogix with Azure NetApp Files:** the following steps must be completed if you plan to use this service.
  - [Register the resource provider](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-register)
  - [Enable the shared AD feature](https://learn.microsoft.com/azure/azure-netapp-files/create-active-directory-connections#shared_ad) - this feature is required if you plan to deploy more than one domain joined NetApp account in the same Azure subscription and region.
- **Marketplace Image:** If you plan to deploy this solution using PowerShell or AzureCLI and use a marketplace image for the virtual machines, use the code below to find the appropriate image:

```powershell
# Determine the Publisher; input the location for your AVD deployment
$Location = ''
(Get-AzVMImagePublisher -Location $Location).PublisherName

# Determine the Offer; common publisher is 'MicrosoftWindowsDesktop' for Win 10/11
$Publisher = ''
(Get-AzVMImageOffer -Location $Location -PublisherName $Publisher).Offer

# Determine the SKU; common offers are 'Windows-10' for Win 10 and 'office-365' for the Win10/11 multi-session with M365 apps
$Offer = ''
(Get-AzVMImageSku -Location $Location -PublisherName $Publisher -Offer $Offer).Skus

# Determine the Image Version; common offers are '21h1-evd-o365pp' and 'win11-21h2-avd-m365'
$Sku = ''
Get-AzVMImage -Location $Location -PublisherName $Publisher -Offer $Offer -Skus $Sku | Select-Object * | Format-List

# Common version is 'latest'
```
