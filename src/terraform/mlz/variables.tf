# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################
# Global Configuration
#################################

variable "tf_environment" {
  description = "The Terraform backend environment e.g. public or usgovernment. It defults to public."
  type        = string
  default     = "public"
}

variable "deploymentname" {
  description = "A name for the deployment. It defaults to dev."
  type        = string
  default     = "dev"
}

variable "mlz_tenantid" {
  description = "The Azure Active Directory tenant ID that should be used for the deployment."
  type        = string
  sensitive   = true
}

variable "mlz_location" {
  description = "The Azure region for most Mission LZ resources. It defaults to eastus."
  type        = string
  default     = "eastus"
}

variable "mlz_metadatahost" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
  type        = string
  default     = "management.azure.com"
}

variable "mlz_clientid" {
  description = "The Client ID of the Service Principal to deploy with."
  type        = string
  sensitive   = true
}

variable "mlz_clientsecret" {
  description = "The Client Secret of the Service Principal to deploy with."
  type        = string
  sensitive   = true
}

variable "mlz_objectid" {
  description = "The object ID of a service principal in the Azure Active Directory tenant."
  type        = string
  sensitive   = true
}

variable "create_assignment" {
  description = "Create an Azure Policy assignement for defaul NIST initiative."
  type        = bool
  default     = false
}

#################################
# Hub Configuration
#################################

variable "hub_subid" {
  description = "Subscription ID for the HUB deployment"
  type        = string
  sensitive   = true
}

variable "hub_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "rg-saca-dev"
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vn-saca-dev"
}

variable "hub_vnet_address_space" {
  description = "The address space to be used for the virtual network."
  default     = ["10.0.100.0/24"]
  type        = list(string)
}

#################################
# Firewall configuration section
#################################

variable "hub_client_address_space" {
  description = "The address space to be used for the Firewall virtual network."
  default     = "10.0.100.0/26"
  type        = string
}

variable "hub_management_address_space" {
  description = "The address space to be used for the Firewall virtual network subnet used for management traffic."
  default     = "10.0.100.64/26"
  type        = string
}

variable "firewall_name" {
  description = "Name of the Hub Firewall"
  default     = "mlzFirewall"
  type        = string
}

variable "firewall_policy_name" {
  description = "Name of the firewall policy to apply to the hub firewall"
  default     = "firewallpolicy"
  type        = string
}

variable "client_ipconfig_name" {
  description = "The name of the Firewall Client IP Configuration"
  default     = "mlzFWClientIpCfg"
  type        = string
}

variable "client_publicip_name" {
  description = "The name of the Firewall Client Public IP"
  default     = "mlzFWClientPip"
  type        = string
}

variable "management_ipconfig_name" {
  description = "The name of the Firewall Management IP Configuration"
  default     = "mlzFWMgmtIpCfg"
  type        = string
}

variable "management_publicip_name" {
  description = "The name of the Firewall Management Public IP"
  default     = "mlzFWMgmtPip"
  type        = string
}

#################################
# Bastion Host Configuration
#################################

variable "create_bastion_jumpbox" {
  description = "Create a bastion host and jumpbox VM?"
  type        = bool
  default     = true
}

variable "bastion_host_name" {
  description = "The name of the Bastion Host"
  default     = "mlzBastionHost"
  type        = string
}

variable "bastion_address_space" {
  description = "The address space to be used for the Bastion Host subnet (must be /27 or larger)."
  default     = "10.0.100.128/27"
  type        = string
}

variable "bastion_public_ip_name" {
  description = "The name of the Bastion Host Public IP"
  default     = "mlzBastionHostPip"
  type        = string
}

variable "bastion_ipconfig_name" {
  description = "The name of the Bastion Host IP Configuration"
  default     = "mlzBastionHostIpCfg"
  type        = string
}

#################################
# Jumpbox VM Configuration
#################################

variable "jumpbox_subnet" {
  description = "The subnet for jumpboxes"
  type = object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  })
  default = {
    name              = "mlzJumpboxSubnet"
    address_prefixes  = ["10.0.100.160/27"]
    service_endpoints = ["Microsoft.Storage"]

    enforce_private_link_endpoint_network_policies = false
    enforce_private_link_service_network_policies  = false

    nsg_name = "mlzJumpboxSubnetNsg"
    nsg_rules = {
      "allow_ssh" = {
        name                       = "allow_ssh"
        priority                   = "100"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "22"
        destination_port_range     = ""
        source_address_prefix      = "*"
        destination_address_prefix = ""
      },
      "allow_rdp" = {
        name                       = "allow_rdp"
        priority                   = "200"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "3389"
        destination_port_range     = ""
        source_address_prefix      = "*"
        destination_address_prefix = ""
      }
    }

    routetable_name = "mlzJumpboxSubnetRt"
  }
}

variable "jumpbox_keyvault_name" {
  description = "The name of the jumpbox virtual machine keyvault"
  default     = "mlzJumpboxVmKv"
  type        = string
}

variable "jumpbox_windows_vm_name" {
  description = "The name of the Windows jumpbox virtual machine"
  default     = "mlzJumpboxWindowsVm"
  type        = string
}

variable "jumpbox_windows_vm_size" {
  description = "The size of the Windows jumpbox virtual machine"
  default     = "Standard_DS1_v2"
  type        = string
}

variable "jumpbox_windows_vm_publisher" {
  description = "The publisher of the Windows jumpbox virtual machine source image"
  default     = "MicrosoftWindowsServer"
  type        = string
}

variable "jumpbox_windows_vm_offer" {
  description = "The offer of the Windows jumpbox virtual machine source image"
  default     = "WindowsServer"
  type        = string
}

variable "jumpbox_windows_vm_sku" {
  description = "The SKU of the Windows jumpbox virtual machine source image"
  default     = "2019-datacenter-gensecond"
  type        = string
}

variable "jumpbox_windows_vm_version" {
  description = "The version of the Windows jumpbox virtual machine source image"
  default     = "latest"
  type        = string
}

variable "jumpbox_linux_vm_name" {
  description = "The name of the Linux jumpbox virtual machine"
  default     = "mlzJumpboxLinuxVm"
  type        = string
}

variable "jumpbox_linux_vm_size" {
  description = "The size of the Linux jumpbox virtual machine"
  default     = "Standard_DS1_v2"
  type        = string
}

variable "jumpbox_linux_vm_publisher" {
  description = "The publisher of the Linux jumpbox virtual machine source image"
  default     = "Canonical"
  type        = string
}

variable "jumpbox_linux_vm_offer" {
  description = "The offer of the Linux jumpbox virtual machine source image"
  default     = "UbuntuServer"
  type        = string
}

variable "jumpbox_linux_vm_sku" {
  description = "The SKU of the Linux jumpbox virtual machine source image"
  default     = "18.04-LTS"
  type        = string
}

variable "jumpbox_linux_vm_version" {
  description = "The version of the Linux jumpbox virtual machine source image"
  default     = "latest"
  type        = string
}

#################################
# Tier 0 Configuration
#################################

variable "tier0_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  sensitive   = true
}

variable "tier0_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "rg-t0-dev"
}

variable "tier0_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vn-t0-dev"
}

variable "tier0_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.110.0/26"]
}

variable "tier0_subnets" {
  description = "A complex object that describes subnets."
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  }))
  default = {
    "tier0vms" = {
      name              = "tier0vms"
      address_prefixes  = ["10.0.110.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "tier0vmsnsg"
      nsg_rules = {
        "allow_ssh" = {
          name                       = "allow_ssh"
          priority                   = "100"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "22"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        },
        "allow_rdp" = {
          name                       = "allow_rdp"
          priority                   = "200"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "3389"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        }
      }

      routetable_name = "tier0vmsrt"
    }
  }
}

#################################
# Tier 1 Configuration
#################################

variable "tier1_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  sensitive   = true
}

variable "tier1_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "rg-t1-dev"
}

variable "tier1_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vn-t1-dev"
}

variable "mlz_lawsname" {
  description = "Log Analytics Workspace Name for the deployment"
  type        = string
  default     = "laws-dev"
}

variable "create_sentinel" {
  description = "Create an Azure Sentinel Log Analytics Workspace Solution"
  type        = bool
  default     = true
}

variable "tier1_vnet_address_space" {
  description = "Address space prefixes for the virtual network"
  type        = list(string)
  default     = ["10.0.115.0/26"]
}

variable "tier1_subnets" {
  description = "A complex object that describes subnets."
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  }))
  default = {
    "tier1vms" = {
      name              = "tier1vms"
      address_prefixes  = ["10.0.115.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "tier1vmsnsg"
      nsg_rules = {
        "allow_ssh" = {
          name                       = "allow_ssh"
          priority                   = "100"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "22"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        },
        "allow_rdp" = {
          name                       = "allow_rdp"
          priority                   = "200"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "3389"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        }
      }

      routetable_name = "tier1vmsrt"
    }
  }
}

#################################
# Tier 2 Configuration
#################################

variable "tier2_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  sensitive   = true
}

variable "tier2_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "rg-t2-dev"
}

variable "tier2_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "vn-t2-dev"
}

variable "tier2_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.120.0/26"]
}

variable "tier2_subnets" {
  description = "A complex object that describes subnets."
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  }))
  default = {
    "tier2vms" = {
      name              = "tier2vms"
      address_prefixes  = ["10.0.120.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "tier2vmsnsg"
      nsg_rules = {
        "allow_ssh" = {
          name                       = "allow_ssh"
          priority                   = "100"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "22"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        },
        "allow_rdp" = {
          name                       = "allow_rdp"
          priority                   = "200"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "3389"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        }
      }

      routetable_name = "tier2vmsrt"
    }
  }
}
