# Examples

In this directory are examples of how to add and extend functionality on-top of MissionLZ.

You [must first deploy MissionLZ](../README.md#Deployment), then you can deploy these examples.

Example | Description
------- | -----------
[Remote Access](./remoteAccess) | Adds a Bastion Host and a virtual machine to serve as a jumpbox into the network
[New Workload](./newWorkload) | Adds a new Spoke Network and peers it to the Hub Network routing all traffic to the Azure Firewall
[Azure Sentinel](./sentinel) | A Terraform module that adds an Azure Sentinel solution to a Log Analytics Workspace

