targetScope = 'subscription'

param environmentAbbreviation string
param subscriptionId string
param resourcePrefix string
param resources object
param tokens object
param workloadName string
param workloadShortName string

var network = {
  name: workloadName
  subscriptionId: subscriptionId
  resourceGroupName: replace(replace(resources.resourceGroup, '-${tokens.service}', ''), tokens.network, workloadName)
  deployUniqueResources: true
  actionGroupName: replace(replace(resources.actionGroup, tokens.service, ''), tokens.network, workloadName)
  automationAccountName: replace(replace(resources.automationAccount, tokens.service, ''), tokens.network, workloadName)
  bastionHostIPConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'bas'), tokens.network, workloadName)
  bastionHostName: replace(replace(resources.bastionHost, '-${tokens.service}', ''), tokens.network, workloadName)
  bastionHostPublicIPAddressName: replace(replace(resources.publicIpAddress, tokens.service, 'bas'), tokens.network, workloadName)
  computeGalleryName: replace(replace(resources.computeGallery, '_${tokens.service}', ''), tokens.network, workloadName)
  diskEncryptionSetName: replace(replace(resources.diskEncryptionSet, '-${tokens.service}', ''), tokens.network, workloadName)
  firewallClientIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'client-afw'), tokens.network, workloadName)
  firewallClientPublicIPAddressName: replace(replace(resources.publicIpAddress, tokens.service, 'client-afw'), tokens.network, workloadName)
  firewallManagementIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'mgmt-afw'), tokens.network, workloadName)
  firewallManagementPublicIPAddressName: replace(replace(resources.publicIpAddress, tokens.service, 'mgmt-afw'), tokens.network, workloadName)
  firewallName: replace(replace(resources.firewall, '-${tokens.service}', ''), tokens.network, workloadName)
  firewallPolicyName: replace(replace(resources.firewallPolicy, '-${tokens.service}', ''), tokens.network, workloadName)
  keyVaultName: take(replace(replace(replace(resources.keyVault, tokens.service, ''), tokens.network, workloadShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, subscriptionId)), 24)
  keyVaultNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'kv'), tokens.network, workloadName)
  keyVaultPrivateEndpointName: replace(replace(resources.privateEndpoint, tokens.service, 'kv'), tokens.network, workloadName)
  linuxDiskName: replace(replace(resources.disk, tokens.service, 'linux'), tokens.network, workloadName)
  linuxNetworkInterfaceIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'linux'), tokens.network, workloadName)
  linuxNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'linux'), tokens.network, workloadName)
  linuxVmName: replace(replace(resources.virtualMachine, tokens.service, 'l${tokens.service}'), tokens.network, workloadShortName)
  logStorageAccountName: take(replace(replace(replace(resources.storageAccount, tokens.service, ''), tokens.network, workloadShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, subscriptionId)), 24)
  logStorageAccountNetworkInterfaceNamePrefix: replace(replace(resources.networkInterface, tokens.service, '${tokens.service}-st'), tokens.network, workloadName)
  logStorageAccountPrivateEndpointNamePrefix: replace(replace(resources.privateEndpoint, tokens.service, '${tokens.service}-st'), tokens.network, workloadName)
  networkSecurityGroupName: replace(replace(resources.networkSecurityGroup, '-${tokens.service}', ''), tokens.network, workloadName)
  networkWatcherName: replace(replace(resources.networkWatcher, '-${tokens.service}', ''), tokens.network, workloadName)
  routeTableName: replace(replace(resources.routeTable, '-${tokens.service}', ''), tokens.network, workloadName)
  subnetName: replace(replace(resources.subnet, '-${tokens.service}', ''), tokens.network, workloadName)
  userAssignedIdentityName: replace(replace(resources.userAssignedIdentity, '-${tokens.service}', ''), tokens.network, workloadName)
  virtualNetworkName: replace(replace(resources.virtualNetwork, '-${tokens.service}', ''), tokens.network, workloadName)
  windowsDiskName: replace(replace(resources.disk, tokens.service, 'windows'), tokens.network, workloadName)
  windowsNetworkInterfaceIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'windows'), tokens.network, workloadName)
  windowsNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'windows'), tokens.network, workloadName)
  windowsVmName: replace(replace(resources.virtualMachine, tokens.service, 'w${tokens.service}'), tokens.network, workloadShortName)
}

output network object = network
