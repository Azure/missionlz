# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################
# Global Configuration
#################################

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  default     = "public"
}

variable "metadata_host" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
  type        = string
  default     = "management.azure.com"
}

variable "location" {
  description = "The Azure region for most Mission LZ resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "A map of key value pairs to apply as tags to resources provisioned in this deployment"
  type        = map(string)
  default = {
    "DeploymentType" : "MissionLandingZoneTF"
  }
}

#################################
# Hub Configuration
#################################

variable "hub_subid" {
  description = "Subscription ID for the Hub deployment"
  type        = string
}

variable "hub_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "hub-rg"
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "hub-vnet"
}

variable "hub_vnet_address_space" {
  description = "The address space to be used for the virtual network."
  type        = list(string)
  default     = ["10.0.100.0/24"]
}

#################################
# Firewall configuration section
#################################

variable "hub_client_address_space" {
  description = "The address space to be used for the Firewall virtual network."
  type        = string
  default     = "10.0.100.0/26"
}

variable "hub_management_address_space" {
  description = "The address space to be used for the Firewall virtual network subnet used for management traffic."
  type        = string
  default     = "10.0.100.64/26"
}

variable "firewall_name" {
  description = "Name of the Hub Firewall"
  type        = string
  default     = "firewall"
}

variable "firewall_policy_name" {
  description = "Name of the firewall policy to apply to the hub firewall"
  type        = string
  default     = "firewall-policy"
}

variable "client_ipconfig_name" {
  description = "The name of the Firewall Client IP Configuration"
  type        = string
  default     = "firewall-client-ip-config"
}

variable "client_publicip_name" {
  description = "The name of the Firewall Client Public IP"
  type        = string
  default     = "firewall-client-public-ip"
}

variable "management_ipconfig_name" {
  description = "The name of the Firewall Management IP Configuration"
  type        = string
  default     = "firewall-management-ip-config"
}

variable "management_publicip_name" {
  description = "The name of the Firewall Management Public IP"
  type        = string
  default     = "firewall-management-public-ip"
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
  type        = string
  default     = "bastionHost"
}

variable "bastion_address_space" {
  description = "The address space to be used for the Bastion Host subnet (must be /27 or larger)."
  type        = string
  default     = "10.0.100.128/27"
}

variable "bastion_public_ip_name" {
  description = "The name of the Bastion Host Public IP"
  type        = string
  default     = "bastionHostPublicIPAddress"
}

variable "bastion_ipconfig_name" {
  description = "The name of the Bastion Host IP Configuration"
  type        = string
  default     = "bastionHostIPConfiguration"
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
    name              = "jumpbox-subnet"
    address_prefixes  = ["10.0.100.160/27"]
    service_endpoints = ["Microsoft.Storage"]

    enforce_private_link_endpoint_network_policies = false
    enforce_private_link_service_network_policies  = false

    nsg_name = "jumpbox-subnet-nsg"
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

    routetable_name = "jumpbox-routetable"
  }
}

variable "jumpbox_keyvault_name" {
  description = "The name of the jumpbox virtual machine keyvault"
  type        = string
  default     = "jumpboxKeyvault"
}

variable "jumpbox_windows_vm_name" {
  description = "The name of the Windows jumpbox virtual machine"
  type        = string
  default     = "jumpboxWindowsVm"
}

variable "jumpbox_windows_vm_size" {
  description = "The size of the Windows jumpbox virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "jumpbox_windows_vm_publisher" {
  description = "The publisher of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "jumpbox_windows_vm_offer" {
  description = "The offer of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "WindowsServer"
}

variable "jumpbox_windows_vm_sku" {
  description = "The SKU of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "2019-datacenter-gensecond"
}

variable "jumpbox_windows_vm_version" {
  description = "The version of the Windows jumpbox virtual machine source image"
  type        = string
  default     = "latest"
}

variable "jumpbox_linux_vm_name" {
  description = "The name of the Linux jumpbox virtual machine"
  type        = string
  default     = "jumpboxLinuxVm"
}

variable "jumpbox_linux_vm_size" {
  description = "The size of the Linux jumpbox virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "jumpbox_linux_vm_publisher" {
  description = "The publisher of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "Canonical"
}

variable "jumpbox_linux_vm_offer" {
  description = "The offer of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "UbuntuServer"
}

variable "jumpbox_linux_vm_sku" {
  description = "The SKU of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "18.04-LTS"
}

variable "jumpbox_linux_vm_version" {
  description = "The version of the Linux jumpbox virtual machine source image"
  type        = string
  default     = "latest"
}

################################
# Policy Configuration
################################

variable "create_policy_assignment" {
  description = "Assign Policy to deployed resources?"
  type        = bool
  default     = true
}

#################################
# Tier 0 Configuration
#################################

variable "tier0_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  default     = ""
}

variable "tier0_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "identity-rg"
}

variable "tier0_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "identity-vnet"
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
    "identitySubnet" = {
      name              = "identitySubnet"
      address_prefixes  = ["10.0.110.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "identitySubnetNsg"
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

      routetable_name = "identityRouteTable"
    }
  }
}

#################################
# Tier 1 Configuration
#################################

variable "tier1_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  default     = ""
}

variable "tier1_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "operations-rg"
}

variable "tier1_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "operations-vnet"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace Name for the deployment"
  type        = string
  default     = ""
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
    "operationsSubnet" = {
      name              = "operationsSubnet"
      address_prefixes  = ["10.0.115.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "operationsSubnetNsg"
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

      routetable_name = "operationsRouteTable"
    }
  }
}

#################################
# Tier 2 Configuration
#################################

variable "tier2_subid" {
  description = "Subscription ID for the deployment"
  type        = string
  default     = ""
}

variable "tier2_rgname" {
  description = "Resource Group for the deployment"
  type        = string
  default     = "sharedServices-rg"
}

variable "tier2_vnetname" {
  description = "Virtual Network Name for the deployment"
  type        = string
  default     = "sharedServices-vnet"
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
    "sharedServicesSubnet" = {
      name              = "sharedServicesSubnet"
      address_prefixes  = ["10.0.120.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "sharedServicesSubnetNsg"
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

      routetable_name = "sharedServicesRouteTable"
    }
  }
}
