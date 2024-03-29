targetScope = 'subscription'

@description('The file name of the ArcGIS Pro installer in Azure Blobs.')
param arcGisProInstaller string

@description('The blob name of the MSI file for the AVD Agent Boot Loader installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param avdAgentBootLoaderMsiName string

@description('The blob name of the MSI file for the AVD Agent installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param avdAgentMsiName string

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

@description('The blob name of the MSI file for the  Azure PowerShell Module installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param azurePowerShellModuleMsiName string

@description('The name of the container in the Azure Storage Account containing the deployment artifacts.')
param containerName string

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@secure()
@description('The password for the domain join account that will be created in Entra Domain Services.')
param domainJoinPassword string

@description('The username for the domain join account that will be created in Entra Domain Services.')
param domainJoinUsername string = 'domainjoin'

@description('The name of the domain to use for Entra Domain Services.')
param domainName string

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string = ''

@description('Determines whether to use the hybrid use benefit.')
param hybridUseBenefit bool

@minLength(1)
@maxLength(3)
@description('The unique identifier between the business unit or project this solution will support.')
param identifier string

@secure()
@description('The password for the local administrator account on the virtual machines.')
param localAdministratorPassword string

@description('The username for the local administrator account on the virtual machines.')
param localAdministratorUsername string

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@minLength(3)
@maxLength(6)
@description('A prefix, 3-6 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string

@description('The array of Security Principals with their object IDs and display names to assign to the AVD Application Group and FSLogix Storage.')
param securityPrincipals array

@description('The resource ID of the Azure Storage Account to use for storing artifacts to customize the image.')
param storageAccountResourceId string

@allowed([
  'Standard_NV4as_v4'
  'Standard_NV8as_v4'
  'Standard_NV16as_v4'
  'Standard_NV32as_v4'
])
@description('The virtual machine SKU for the AVD session hosts.')
param virtualMachineSize string = 'Standard_NV4as_v4'

module missionLandingZone '../../mlz.bicep' = {
  name: 'deploy-mission-landing-zone-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: 'dev'
    deployIdentity: true
    firewallSkuTier: 'Standard'
    location: location
    resourcePrefix: resourcePrefix
  }
}

module domainServices 'modules/domainServices.bicep' = {
  name: 'deploy-entra-domain-services-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    domainName: domainName
    location: location
    resourceGroupName: first(filter(missionLandingZone.outputs.networks, network => network.name == 'identity')).resourceGroupName
    subnetResourceId: missionLandingZone.outputs.identitySubnetResourceId
  }
}

module image '../imaging/solution.bicep' = {
  name: 'deploy-image-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    azureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    containerName: containerName
    emailSecurityContact: emailSecurityContact
    enableBuildAutomation: false
    environmentAbbreviation: 'dev'
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    hybridUseBenefit: hybridUseBenefit
    identifier: identifier
    imageDefinitionNamePrefix: 'arcgis-pro'
    imageMajorVersion: 1
    imagePatchVersion: 0
    installAccess: false
    installArcGisPro: true
    installExcel: false
    installOneDrive: false
    installOneNote: false
    installOutlook: false
    installPowerPoint: false
    installProject: false
    installPublisher: false
    installSkypeForBusiness: false
    installTeams: false
    installVirtualDesktopOptimizationTool: false
    installVisio: false
    installWord: false
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    replicaCount: 1
    sourceImageType: 'AzureMarketplace'
    spokelogAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    storageAccountResourceId: storageAccountResourceId
    virtualMachineSize: virtualMachineSize
  }
}

module azureVirtualDesktop '../azureVirtualDesktop/solution.bicep' = {
  name: 'deploy-azure-virtual-desktop-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: 'MicrosoftEntraDomainServices'
    artifactsContainerName: containerName
    artifactsStorageAccountResourceId: storageAccountResourceId
    availability: 'None'
    avdAgentBootLoaderMsiName: avdAgentBootLoaderMsiName
    avdAgentMsiName: avdAgentMsiName
    avdObjectId: avdObjectId
    azureNetAppFilesSubnetAddressPrefix: '10.0.140.128/25'
    azurePowerShellModuleMsiName: azurePowerShellModuleMsiName
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: '${domainJoinUsername}@${domainName}'
    domainName: domainName
    environmentAbbreviation: 'dev'
    fslogixStorageService: 'AzureNetAppFiles Premium'
    hostPoolPublicNetworkAccess: 'Enabled'
    hubAzureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    hubSubnetResourceId: missionLandingZone.outputs.hubSubnetResourceId
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    identifier: identifier
    imageDefinitionResourceId: image.outputs.imageDefinitionResourceId
    locationControlPlane: location
    locationVirtualMachines: location
    organizationalUnitPath: 'OU=AADDC Computers,DC=${replace(domainName, '.', ',DC=')}'
    securityPrincipals: securityPrincipals
    subnetAddressPrefixes: ['10.0.140.0/25']
    virtualMachinePassword: localAdministratorPassword
    virtualMachineSize: virtualMachineSize
    virtualMachineUsername: localAdministratorUsername
    virtualMachineVirtualCpuCount: int(replace(replace(virtualMachineSize, 'Standard_NV', ''), 'as_v4', ''))
    virtualNetworkAddressPrefixes: ['10.0.140.0/24']
    workspacePublicNetworkAccess: 'Enabled'
  }
  dependsOn: [
    domainServices
  ]
}
