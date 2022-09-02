# Azure IaaS DNS Forwarders example

This example deploys DNS Forwarder Virtual Machines in the MLZ HUB, to enables proper resolution of Private Endpoint and internal domains accross all Virtualn Networks.

## What this example does

### Follows best-practices

This Infrastructure as Code deploys the components to follow best practices: [Private Link and DNS integration in hub and spoke network architectures](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale#private-link-and-dns-integration-in-hub-and-spoke-network-architectures)

### Configures proper DNS resolution in DoD Azure environments

The two Windows DNS Servers are configured to act as DNS servers for all Virtual Networks, and then forward DNS requests three different ways, as depicted below.

[![DNS Forwarders diagram](diagram.png)

1. Azure Private Endpoint-related DNS requests will be forwarded to the Azure DNS server (168.63.129.16), which will use the Private DNS zones configured as part of MLZ.
2. Active Directory-related DNS requests will be forwarded to the Domain Controllers in the Identity tier.
3. All other DNS requests (Internet...) will be forwarded to the default server forwarder, typically DISA DNS servers.

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
2. The outputs from a deployment of mlz.bicep (./src/bicep/examples/deploymentVariables.json).  

See below for information on how to create the appropriate deployment variables file for use with this template.

### Template Parameters

Template Parameters Name | Description
-----------------------| -----------


### Generate MLZ Variable File (deploymentVariables.json)

For instructions on generating 'deploymentVariables.json' using both Azure PowerShell and Azure CLI, please see the [README at the root of the examples folder](..\README.md).

Place the resulting 'deploymentVariables.json' file within the ./src/bicep/examples folder.

### Deploying IaaS DNS Forwarders
