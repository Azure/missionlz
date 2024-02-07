@description('Azure Region for the site deployment. All Resources provisioned are created here')
param location string = 'eastus'

@description('(Optional) Prefix applied to all resources provisioned as part of this template')
@maxLength(3)
param deploymentPrefix string = ''

@description('(Optional) Indicates whether Azure Files (SMB protocol) is used for the server config and portal content store')
param usesPrivateIP bool = false

@description('(Optional) Deploys an unused public IP when using a Private Ip as Application Gateway V2 doesn\'t support only Private IP deployments yet.')
param deployPublicIPWhenUsingPrivateIP bool = true

@description('(Optional) Indicates whether to use existing Public IP is usesPrivateIP is false')
param usesExistingPublicIP bool = false

@description('Name of the existing Public IP')
param existingPublicIPName string = ''

@description('DNS name for the Public IP address resource asociated with the site deployment. It needs to be unique across the region of deployment')
@maxLength(80)
param dnsPrefixForPublicIpAddress string = ''

@description('DNS name for the site deployment. It will be a custom domain (e.g. mysite.contoso.com) if using a Private IP or an SSL certificate, otherwise will be the Azure DNS <dnsPrefixForPublicIpAddress>.<location>.cloudapp.azure.com')
param externalDnsHostName string

@description('Private DNS name for the site deployment. It will be a custom domain (e.g. mysite.contoso.com) if using a Private IP or an SSL certificate, otherwise will be the Azure DNS <dnsPrefixForPublicIpAddress>.<location>.cloudapp.azure.com')
param secondaryDnsHostName string = ''

@description('File name for the SSL Certificate')
param sslCertificateFileName string = ''

@description('Base-64 encoded form of the .pfx file. This is the cert terminating on the Application Gateway.')
param sslCertificateData string = ''

@description('File name for the Public Key SSL Certificate')
param publicKeySSLCertificateFileName string = ''

@description('Password for .pfx certificate')
@secure()
param sslCertificatePassword string = ''

@description('Use Self Signed Internal Certificate')
param useSelfSignedInternalSSLCertificate bool = true

@description('Private Key for the Backend Self signed SSL Certificate')
@secure()
param selfSignedSSLCertificatePassword string = ''

@description('File name for the SSL Certificate')
param serverInternalCertificateFileName string = ''

@description('Accessible file path for SSL Certificate')
@secure()
param serverInternalCertificatePassword string = ''

@description('File name for the SSL Certificate')
param portalInternalCertificateFileName string = ''

@description('Accessible file path for SSL Certificate')
@secure()
param portalInternalCertificatePassword string = ''

@description('Name of the Resource Group for the existing Virtual Network specified with the \'existingVirtualNetworkName\' parameter')
param virtualNetworkResourceGroupName string

@description('Name of the existing Virtual Network')
param existingVirtualNetworkName string

@description('Name of the existing Subnet within the Virtual Network specified with the \'existingVirtualNetworkName\' parameter')
param subnetName string

@description('Name of the existing Subnet within the Virtual Network specified with the \'existingVirtualNetworkName\' parameter')
param appGatewaySubnetName string

// @description('True if updating certificates of an existing deployment')
// param isUpdatingCertificates bool = false

@description('Available IP address in Application Gateway Subnet Range to be used with external dns name')
param appGatewayPrivateIP string = ''

@description('Subnet associated with Private IP')
param appGatewayPrivateIPSubnet string = ''

@description('Name of Application Gateway Resource')
param appGatewayName string

@description('Name of Application Gateway Resource Group Name')
param appGatewayResourceGroupName string

@description('Windows Base Image reference version to be either used for RDP jump box or Fileshare Machine')
param windowsServerBaseImageReferenceVersion string = 'latest'

@description('Details of ArcGIS marketplace image or User Images')
param imageReferences object

@description('Username for the Virtual Machine Administrator (Windows) Account')
param adminUsername string = ''

@description('Password for the Virtual Machine Administrator (Windows) Account')
@secure()
param adminPassword string = ''

@description('Name of the File Share Virtual Machine')
param fileShareVirtualMachineName string

@description('Size used for the File Share Virtual Machine')
param fileShareVirtualMachineSize string = 'Standard_DS2_v2'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the File Share Virtual Machine')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
])
param fileShareVirtualMachineOSDiskSize int = 64

@description('Managed Disk Type for the Operating System (c Drive) Disk for the File Share Virtual Machine')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param fileShareVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Indicates whether an additional Managed Disk is attached to the File Share Virtual Machine')
param enableFileShareVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the File Share Virtual Machine')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param fileShareVirtualMachineDataDiskSize int = 32

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Server tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param fileShareVirtualMachineDataDiskType string = 'Premium_LRS'

@description('Comma seperated list of virtual machine names for the Server Tier')
param serverVirtualMachineNames string

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param serverVirtualMachineImageSpecs string = '0,0'

@description('Virtual Machine Size for the Server tier of machines')
param serverVirtualMachineSize string = 'Standard_DS3_v2'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the Server tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param serverVirtualMachineOSDiskSize int = 128

@description('(Optional) Managed Disk Type for the Operating System (c Drive) Disk for the Server tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param serverVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Server tier of Virtual Machines')
param enableServerVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Server tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param serverVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk size for the additional (Data) disk attached to the Server tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param serverVirtualMachineDataDiskSize int = 32

@description('Comma seperated list of virtual machine names for the Portal Tier')
param portalVirtualMachineNames string

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param portalVirtualMachineImageSpecs string = '0,0'

@description('Virtual Machine Size for the Portal tier of machines')
param portalVirtualMachineSize string = 'Standard_DS3_v2'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the Portal tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  327678
])
param portalVirtualMachineOSDiskSize int = 128

@description('(Optional) Managed Disk Type for the Operating System (c Drive) Disk for the Portal tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param portalVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Portal tier of Virtual Machines')
param enablePortalVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Portal tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param portalVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Portal tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param portalVirtualMachineDataDiskSize int = 32

@description('Comma seperated list of virtual machine names for the Data Store Tier')
param dataStoreVirtualMachineNames string

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param dataStoreVirtualMachineImageSpecs string = '0,0'

@description('Virtual Machine Size for the Data Store tier of machines')
param dataStoreVirtualMachineSize string = 'Standard_DS3_v2'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the DataStore tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param dataStoreVirtualMachineOSDiskSize int = 128

@description('(Optional) Managed Disk Type for the Operating System (c Drive) Disk for the DataStore tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param dataStoreVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Data Store tier of Virtual Machines')
param enableDataStoreVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param dataStoreVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk type for the additional (Data) disk attached to the DataStore tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param dataStoreVirtualMachineDataDiskSize int = 32

@description('Comma seperated list of virtual machine names for the Spatiotemporal Big Data Store Tier')
param spatiotemporalBigDataStoreVirtualMachineNames string = ''

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param spatiotemporalBigDataStoreVirtualMachineImageSpecs string = ''

@description('Virtual Machine Size for the Spatiotemporal Big Data Store tier of machines')
param spatiotemporalBigDataStoreVirtualMachineSize string = 'Standard_DS3_v2'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the Portal tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param spatiotemporalBigDataStoreVirtualMachineOSDiskSize int = 128

@description('Managed Disk Type for the Operating System (c Drive) Disk for the Spatiotemporal Big Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param spatiotemporalBigDataStoreVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Spatiotemporal Big Data Store tier of Virtual Machines')
param enableSpatiotemporalBigDataStoreVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Spatiotemporal Big Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param spatiotemporalBigDataStoreVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Spatiotemporal Big Data tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param spatiotemporalBigDataStoreVirtualMachineDataDiskSize int = 32

@description('TileCache Datastore architecture mode set to `cluster` if true, else `masterSlave`')
param isTileCacheDataStoreClustered bool = false

@description('Comma seperated list of virtual machine names for the Tile Cache Data Store Tier')
param tileCacheDataStoreVirtualMachineNames string = ''

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param tileCacheDataStoreVirtualMachineImageSpecs string = ''

@description('Virtual Machine Size for the Tile Cache Data Store tier of machines')
param tileCacheDataStoreVirtualMachineSize string = 'Standard_DS3_v2'

@description('Managed Disk Type for the Operating System (c Drive) Disk for the Tile Cache Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param tileCacheDataStoreVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the Portal tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param tileCacheDataStoreVirtualMachineOSDiskSize int = 128

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Tile Cache Data Store tier of Virtual Machines')
param enableTileCacheDataStoreVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Tile Cache Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param tileCacheDataStoreVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Tile Cache Data tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param tileCacheDataStoreVirtualMachineDataDiskSize int = 32

@description('Comma seperated list of virtual machine names for the Graph Data Store Tier')
param graphDataStoreVirtualMachineNames string = ''

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param graphDataStoreVirtualMachineImageSpecs string = ''

@description('Virtual Machine Size for the Graph Data Store tier of machines')
param graphDataStoreVirtualMachineSize string = 'Standard_DS3_v2'

@description('Managed Disk Type for the Operating System (c Drive) Disk for the Graph Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param graphDataStoreVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the Graph Data Store tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param graphDataStoreVirtualMachineOSDiskSize int = 128

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Graph Data Store tier of Virtual Machines')
param enableGraphDataStoreVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Graph Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param graphDataStoreVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Graph Data tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param graphDataStoreVirtualMachineDataDiskSize int = 32

@description('Object Datastore architecture mode set to `cluster` if true, else `standalone`')
param isObjectDataStoreClustered bool = false

@description('Comma seperated list of virtual machine names for the Object Data Store Tier')
param objectDataStoreVirtualMachineNames string = ''

@description('Comma seperated list of Image Type used refrencing useManagedDiskImage,userImageName,userImageResourceGroupName,imagePublisher,imageOffery and imageSKU by index')
param objectDataStoreVirtualMachineImageSpecs string = ''

@description('Virtual Machine Size for the Object Data Store tier of machines')
param objectDataStoreVirtualMachineSize string = 'Standard_DS3_v2'

@description('Managed Disk Type for the Operating System (c Drive) Disk for the Object Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param objectDataStoreVirtualMachineOSDiskType string = 'Premium_LRS'

@description('(Optional) Managed Disk Size for the Operating System (c Drive) Disk for the Portal tier Object Data Store tier of Virtual Machines')
@allowed([
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param objectDataStoreVirtualMachineOSDiskSize int = 128

@description('(Optional) Indicates whether an additional Managed Disk is attached to the Object Data Store tier of Virtual Machines')
param enableObjectDataStoreVirtualMachineDataDisk bool = false

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Object Data Store tier of Virtual Machines')
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
])
param objectDataStoreVirtualMachineDataDiskType string = 'Premium_LRS'

@description('(Optional) Managed disk type for the additional (Data) disk attached to the Object Data tier of Virtual Machines')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
  16384
  32767
])
param objectDataStoreVirtualMachineDataDiskSize int = 32

@description('(Optional) Standard Id for the timezone to set for the Virtual Machines in the deployment')
param timeZoneId string = ''

@description('(Optional) Indicates whether to enable Automatic (Windows) Operating System updates')
param enableAutomaticUpdates bool = false

@description('(Optional) Indicates whether the virtual machines should join an existing Windows Active Directory which provides domain join and DNS services in the Virtual Network')
param joinWindowsDomain bool = false

@description('(Optional) Domain FQDN where the virtual machine will be joined. Required if joinWindowsDomain = true')
param windowsDomainName string = ''

@description('(Optional) Username for the Active Directory Domain Administrator account where the virtual machine will be joined. Required if joinWindowsDomain = true')
param windowsDomainAdministratorUserName string = ''

@description('(Optional) Password for the Active Directory Domain Administrator account where the virtual machine will be joined. Required if joinWindowsDomain = true')
@secure()
param windowsDomainAdministratorPassword string = ''

@description('Azure Monitor Logs workspace name')
param omsWorkspaceName string = ''

@description('Azure Monitor Logs Workspace Resource Group Name')
param omsWorkspaceResourceGroupName string = ''

@description('User name for the ArcGIS (Windows) Service Account')
param arcgisServiceAccountUserName string = 'arcgis'

@description('Password for the ArcGIS (Windows) Service Account')
@secure()
param arcgisServiceAccountPassword string = ''

@description('(Optional) Indicates whether ArcGIS Service Account is a Domain Account.')
param arcgisServiceAccountIsDomainAccount bool = false

@description('User name for the ArcGIS Server Site Primary Site Administrator')
param primarySiteAdministratorAccountUserName string = 'siteadmin'

@description('User name for the ArcGIS Server Site Primary Site Administrator')
@secure()
param primarySiteAdministratorAccountPassword string

@description('File name for the ArcGIS Server License')
param serverLicenseFileName string = ''

@description('File name for the Portal for ArcGIS License')
param portalLicenseFileName string = ''

@description('Portal for ArcGIS License User Type Id to be used to Configure Portal Site')
param portalLicenseUserTypeId string = ''

@description('(Optional) The types of ArcGIS Data Stores that are enabled for this deployment')
param dataStoreTypes string = 'Relational'

@description('(Optional) Indicates whether TileCache Datastore is a multi machine setup')
param isMultiMachineTileCacheDataStore bool = false

@description('(Optional) Indicates whether Azure Storage is used for the server config and portal content store')
param useCloudStorage bool = false

@description('(Optional) Indicates whether Azure Files (SMB protocol) is used for the server config and portal content store')
param useAzureFiles bool = false

@description('(Optional) Name of the file share on the file share host')
param fileShareName string = 'fileshare'

@description('(Optional) Name of the Azure Storage Account used. Required if \'useCloudStorage\' is set to true')
param cloudStorageAccountName string = ''

@description('(Optional) Name of the resource group for the Azure Storage Account specified with \'cloudStorageAccountName\'. Required if \'useCloudStorage\' is set to true')
param cloudStorageAccountResourceGroupName string = ''

@description('(Optional) Storage Account Access Key for the Azure Storage Account specified with \'cloudStorageAccountName\'. Required if \'useCloudStorage\' is set to true')
@secure()
param cloudStorageAccountKey string = ''


@description('(SAS) Shared Access Token for the deployment artifacts in an Azure Blob Storage Container')
@secure()
param _artifactsLocationSasToken string = ''

@description('Fully qualified URL for the deployment artifacts location in an Azure Blob Storage Container')
param _artifactsLocation string

@description('(Optional) Indicates whether to enable debug settings on the site deployment. Used for troubleshooting only and should not be used for a Production Deployment')
param debugMode bool = false

@description('(Optional) Indicates whether Remote Desktop Access to the File Share Machine should be enabled.')
param enableRDPAccess bool = false

@description('(Optional) Indicates whether to enable auto shutdown at specified time.')
param enableAutoShutDown bool = false

@description('(Optional) Auto Shut down time in hh:ss format.')
param autoShutDownTime string = ''

@description('(Optional) Version number of the ArcGIS Software used in the deployment')
param arcgisDeploymentVersion string = '11.1'

@description('Deployment Id required in case of post deployment operations and optional in case of new deployments')
param arcgisDeploymentId string = ''

@description('(Optional) deployment Tracking ID based on Orchestrator being Automation or Cloud Builder ')
param deploymentTrackingID string = '26ec1866-8a3b-42df-b634-c76a78554568'

@description('(Optional) Prefix applied to all resources provisioned as part of this template')
@maxLength(3)
param resourceSuffix string

var deploymentId = (empty(arcgisDeploymentId) ? uniqueString(resourceGroup().id, concat(serverContext, location), ((!empty(secondaryDnsHostName)) ? secondaryDnsHostName : externalDnsHostName)) : arcgisDeploymentId)

var applicationGatewayName = 'appgw-esri-${resourceSuffix}'
var container = 'artifacts'
var keyVaultCertificatesOfficer = resourceId('Microsoft.Authorization/roleDefinitions', 'a4417e6f-fecd-4de8-b567-7b0420556985')
var keyVaultName = 'kv-esri-${resourceSuffix}'
var keyVaultSecretsOfficer = resourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
var networkInterfaceName = 'nic-esri-${resourceSuffix}'
var portalContext = 'portal'
var portalLicenseFileName = 'PortalLicenseFile.json'
var publicIpAddressName = 'pip-esri-${resourceSuffix}'
var resourceGroupName = 'rg-esri-${resourceSuffix}'
var serverContext = 'server'
var serverLicenseFileName = 'ServerLicenseFile.prvc'
var subscriptionId = subscription().subscriptionId
var userAssignedManagedIdentityName = 'uami-esri-${resourceSuffix}'
var virtualNetworkName = 'vnet-esri-${resourceSuffix}'

var publicIPAddressResourceName = (usesExistingPublicIP ? existingPublicIPName : '${deploymentPrefix}PublicIP')
var publicIPAddressRDPResourceName = '${deploymentPrefix}PublicIP-RDP'
var unusedPublicIPPWhenUsingPrivateIPDnsPrefix = 'ip${deploymentId}${serverContext}'
var unusedPublicIPWhenUsingPrivateIPResourceName = '${unusedPublicIPPWhenUsingPrivateIPDnsPrefix}UnusedPublicIP'
var vnetID = resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks', existingVirtualNetworkName)
var subnetRef = '${vnetID}/subnets/${subnetName}'
var nicName = 'nic'
var serverAvailablitySetName = '${deploymentPrefix}AvailabilitySet-Server'
var serverVirtualMachineNames_var = split(serverVirtualMachineNames, ',')
var serverVirtualMachineImageSpecs_var = split(serverVirtualMachineImageSpecs, ',')
var numberOfServerVirtualMachines = length(serverVirtualMachineNames_var)
var portalAvailablitySetName = '${deploymentPrefix}AvailabilitySet-Portal'
var portalVirtualMachineNames_var = split(portalVirtualMachineNames, ',')
var portalVirtualMachineImageSpecs_var = split(portalVirtualMachineImageSpecs, ',')
var numberOfPortalVirtualMachines = length(portalVirtualMachineNames_var)
var dataStoreAvailablitySetName = '${deploymentPrefix}AvailabilitySet-DataStore'
var dataStoreVirtualMachineNames_var = split(dataStoreVirtualMachineNames, ',')
var dataStoreVirtualMachineImageSpecs_var = split(dataStoreVirtualMachineImageSpecs, ',')
var numberOfDataStoreVirtualMachines = length(dataStoreVirtualMachineNames_var)
// var enableSpatiotemporalBigDataStore = contains(dataStoreTypes, 'SpatioTemporal')
// var spatiotemporalBigDataStoreAvailablitySetName = '${deploymentPrefix}AvailabilitySet-SpatiotemporalDataStore'
// var spatiotemporalBigDataStoreVirtualMachineNames_var = split(spatiotemporalBigDataStoreVirtualMachineNames, ',')
// var spatiotemporalBigDataStoreVirtualMachineNameOptions = {
// true: spatiotemporalBigDataStoreVirtualMachineNames_var
// false: [
// 'sa'
// 'sb'
// 'sc'
// 'sd'
// 'se'
// 'sf'
// 'sg'
// 'sh'
// 'si'
// 'sj'
// 'sk'
// 'sl'
// 'sm'
// 'sn'
// 'so'
// 'sp'
// ]
// }
// var numberOfSpatiotemporalBigDataStoreVirtualMachines = length(spatiotemporalBigDataStoreVirtualMachineNames_var)
// var spatiotemporalBigDataStoreVirtualMachineImageSpecs_var = split(spatiotemporalBigDataStoreVirtualMachineImageSpecs, ',')
// var spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions = {
// true: spatiotemporalBigDataStoreVirtualMachineImageSpecs_var
// false: [
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// ]
// }
// var enableTileCacheDataStore = (!empty(tileCacheDataStoreVirtualMachineNames))
// var tileCacheDataStoreAvailablitySetName = '${deploymentPrefix}AvailabilitySet-TileCacheDataStore'
// var tileCacheDataStoreVirtualMachineNames_var = split(tileCacheDataStoreVirtualMachineNames, ',')
// var tileCacheDataStoreVirtualMachineNameOptions = {
// true: tileCacheDataStoreVirtualMachineNames_var
// false: [
// 'ta'
// 'tb'
// 'tc'
// 'td'
// 'te'
// 'tf'
// 'tg'
// 'th'
// 'ti'
// 'tj'
// 'tk'
// 'tl'
// 'tm'
// 'tn'
// 'to'
// 'tp'
// ]
// }
// var numberOftileCacheDataStoreVirtualMachines = length(tileCacheDataStoreVirtualMachineNames_var)
// var tileCacheDataStoreVirtualMachineImageSpecs_var = split(tileCacheDataStoreVirtualMachineImageSpecs, ',')
// var tileCacheDataStoreVirtualMachineImageSpecsOptions = {
// true: tileCacheDataStoreVirtualMachineImageSpecs_var
// false: [
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// ]
// }
// var enableGraphDataStore = contains(dataStoreTypes, 'GraphStore')
// var graphDataStoreAvailablitySetName = '${deploymentPrefix}AvailabilitySet-GraphDataStore'
// var graphDataStoreVirtualMachineNames_var = split(graphDataStoreVirtualMachineNames, ',')
// var graphDataStoreVirtualMachineNameOptions = {
// true: graphDataStoreVirtualMachineNames_var
// false: [
// 'ga'
// 'gb'
// 'gc'
// 'gd'
// 'ge'
// 'gf'
// 'gg'
// 'gh'
// 'gi'
// 'gj'
// 'gk'
// 'gl'
// 'gm'
// 'gn'
// 'go'
// 'gp'
// ]
// }
// var numberOfGraphDataStoreVirtualMachines = length(graphDataStoreVirtualMachineNames_var)
// var graphDataStoreVirtualMachineImageSpecs_var = split(graphDataStoreVirtualMachineImageSpecs, ',')
// var graphDataStoreVirtualMachineImageSpecsOptions = {
// true: graphDataStoreVirtualMachineImageSpecs_var
// false: [
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// ]
// }
// var enableObjectDataStore = contains(dataStoreTypes, 'ObjectStore')
// var objectDataStoreAvailablitySetName = '${deploymentPrefix}AvailabilitySet-ObjectDataStore'
// var objectDataStoreVirtualMachineNames_var = split(objectDataStoreVirtualMachineNames, ',')
// var objectDataStoreVirtualMachineNameOptions = {
// true: objectDataStoreVirtualMachineNames_var
// false: [
// 'oa'
// 'ob'
// 'oc'
// 'od'
// 'oe'
// 'of'
// 'og'
// 'oh'
// 'oi'
// 'oj'
// 'ok'
// 'ol'
// 'om'
// 'on'
// 'oo'
// 'op'
// ]
// }
// var numberOfObjectDataStoreVirtualMachines = length(objectDataStoreVirtualMachineNames_var)
// var objectDataStoreVirtualMachineImageSpecs_var = split(objectDataStoreVirtualMachineImageSpecs, ',')
// var objectDataStoreVirtualMachineImageSpecsOptions = {
// true: objectDataStoreVirtualMachineImageSpecs_var
// false: [
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// '0'
// ]
// }



var dscExtensionArchiveFileName = 'DSC.zip'
var fileShareDscScriptFunction = 'FileShareConfiguration'
var jumpBoxName = '${deploymentPrefix}JumpBox'
var jumpBoxNicName = '${jumpBoxName}-${nicName}'
var omsWorkspaceResourceId = (((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) ? resourceId(omsWorkspaceResourceGroupName, 'Microsoft.OperationalInsights/workspaces/', omsWorkspaceName) : '')


module userAssignedIdentity './modules/userAssignedManagedIdentity.bicep' = {
  name: 'user-assigned-identity-${deployment().name}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    name: userAssignedManagedIdentityName
    tags: {}
  }
  dependsOn: [
  ]
}


module virtualNetwork './modules/virtualNetwork.bicep' = {
  name: 'virtual-network-${deployment().name}'
  params: {
    applicationGatewayName: applicationGatewayName
    location: location
    resourceGroup: resourceGroup().name
    tags: {}
    virtualNetworkName: virtualNetworkName
  }
  dependsOn: [
  ]
}

module createAFS_name './nested_createAFS_name.bicep' = if (useCloudStorage && useAzureFiles) {
  name: 'createAFS-${deployment().name}'
  scope: resourceGroup(cloudStorageAccountResourceGroupName)
  params: {
    cloudStorageAccountName: cloudStorageAccountName
    fileShareName: fileShareName
  }
}

resource publicIPAddressRDPResource 'Microsoft.Network/publicIPAddresses@2018-08-01' = if (string(enableRDPAccess) == 'True') {
  name: publicIPAddressRDPResourceName
  location: location
  tags: {
    displayName: 'Public IP Address - RDP (Optional)'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: '${dnsPrefixForPublicIpAddress}-rdp'
    }
  }
}

resource jumpBoxNic 'Microsoft.Network/networkInterfaces@2018-08-01' = if (string(enableRDPAccess) == 'True') {
  name: jumpBoxNicName
  location: location
  tags: {
    displayName: 'RDP Jump Box Network Interface'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'jumpbox-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressRDPResource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
}

resource jumpBox 'Microsoft.Compute/virtualMachines@2018-06-01' = if ((!empty(adminPassword)) && (string(enableRDPAccess) == 'True')) {
  name: jumpBoxName
  location: location
  tags: {
    displayName: 'RDP Jump Box'
    'arcgis-deployment-id': deploymentId
    'arcgis-vm-roles': 'RDPJumpBox'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    osProfile: {
      computerName: jumpBoxName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-smalldisk-g2'
        version: windowsServerBaseImageReferenceVersion
      }
      osDisk: {
        name: '${jumpBoxName}-OsDisk'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpBoxNic.id
        }
      ]
    }
  }
}

resource shutdown_computevm_jumpBox 'Microsoft.DevTestLab/schedules@2018-09-15' = if ((string(enableRDPAccess) == 'True') && (string(enableAutoShutDown) == 'True')) {
  name: 'shutdown-computevm-${jumpBoxName}'
  location: location
  properties: {
    status: 'Enabled'
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: jumpBox.id
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
  ]
}

resource jumpBoxName_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = if ((string(enableRDPAccess) == 'True') && (string(joinWindowsDomain) == 'True')) {
  name: 'JoinDomain'
  parent: jumpBox
  location: location
  tags: {
    displayName: '(Optional) Jumpbox Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [

  ]
}

resource usesPrivateIP_unusedPublicIPWhenUsingPrivateIPResourceName_publicIPAddressResource 'Microsoft.Network/publicIPAddresses@2018-06-01' = if ((!usesExistingPublicIP) || ((string(usesPrivateIP) == 'True') && (string(deployPublicIPWhenUsingPrivateIP) == 'True'))) {
  name: (usesPrivateIP ? unusedPublicIPWhenUsingPrivateIPResourceName : publicIPAddressResourceName)
  location: location
  tags: {
    displayName: 'Application Gateway Public IP Address'
    'arcgis-deployment-id': deploymentId
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 11
    dnsSettings: {
      domainNameLabel: (usesPrivateIP ? unusedPublicIPPWhenUsingPrivateIPDnsPrefix : dnsPrefixForPublicIpAddress)
    }
  }
  dependsOn: []
}

resource serverAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: serverAvailablitySetName
  location: location
  tags: {
    displayName: 'Server Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource serverVirtualMachineNames_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOfServerVirtualMachines): {
  name: '${serverVirtualMachineNames_var[i]}-${nicName}'
  location: location
  tags: {
    displayName: 'Server Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource serverVirtualMachineNames_resource 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOfServerVirtualMachines): if (!empty(adminPassword)) {
  name: serverVirtualMachineNames_var[i]
  location: location
  tags: {
    'arcgis-vm-roles': 'Server'
    'arcgis-deployment-id': deploymentId
    displayName: 'Server Virtual Machines'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: serverAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: serverVirtualMachineSize
    }
    osProfile: {
      computerName: serverVirtualMachineNames_var[i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[serverVirtualMachineImageSpecs_var[i]].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[serverVirtualMachineImageSpecs_var[i]].Publisher}","offer":"${imageReferences[serverVirtualMachineImageSpecs_var[i]].Offer}","sku":"${imageReferences[serverVirtualMachineImageSpecs_var[i]].SKU}","version":"latest"}') : ((string(imageReferences[serverVirtualMachineImageSpecs_var[i]].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[serverVirtualMachineImageSpecs_var[i]].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[serverVirtualMachineImageSpecs_var[i]].UserImageName))}"}') : json('{"id":"${string(imageReferences[serverVirtualMachineImageSpecs_var[i]].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${serverVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: serverVirtualMachineOSDiskType
        }
        diskSizeGB: serverVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableServerVirtualMachineDataDisk) == 'True') ? json('[{"name":"${serverVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${serverVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${serverVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${serverVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    serverVirtualMachineNames_nic[i]
  ]
}]

resource shutdown_computevm_serverVirtualMachineNames 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOfServerVirtualMachines): if (string(enableAutoShutDown) == 'True') {
  name: 'shutdown-computevm-${serverVirtualMachineNames_var[i]}'
  location: location
  properties: {
    status: 'Enabled'
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', serverVirtualMachineNames_var[i])
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    serverVirtualMachineNames_resource[i]
  ]
}]

resource serverVirtualMachineNames_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfServerVirtualMachines): if (string(joinWindowsDomain) == 'True') {
  name: '${serverVirtualMachineNames_var[i]}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Server Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    serverVirtualMachineNames_resource[i]
  ]
}]

resource portalAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: portalAvailablitySetName
  location: location
  tags: {
    displayName: 'Portal Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource portalVirtualMachineNames_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOfPortalVirtualMachines): {
  name: '${portalVirtualMachineNames_var[i]}-${nicName}'
  location: location
  tags: {
    displayName: 'Portal Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource portalVirtualMachineNames_resource 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOfPortalVirtualMachines): if (!empty(adminPassword)) {
  name: portalVirtualMachineNames_var[i]
  location: location
  tags: {
    'arcgis-vm-roles': 'Portal'
    'arcgis-deployment-id': deploymentId
    displayName: 'Portal Virtual Machines'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: portalAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: portalVirtualMachineSize
    }
    osProfile: {
      computerName: portalVirtualMachineNames_var[i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[portalVirtualMachineImageSpecs_var[i]].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[portalVirtualMachineImageSpecs_var[i]].Publisher}","offer":"${imageReferences[portalVirtualMachineImageSpecs_var[i]].Offer}","sku":"${imageReferences[portalVirtualMachineImageSpecs_var[i]].SKU}","version":"latest"}') : ((string(imageReferences[portalVirtualMachineImageSpecs_var[i]].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[portalVirtualMachineImageSpecs_var[i]].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[portalVirtualMachineImageSpecs_var[i]].UserImageName))}"}') : json('{"id":"${string(imageReferences[portalVirtualMachineImageSpecs_var[i]].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${portalVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: portalVirtualMachineOSDiskType
        }
        diskSizeGB: portalVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enablePortalVirtualMachineDataDisk) == 'True') ? json('[{"name":"${portalVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${portalVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${portalVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${portalVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    portalVirtualMachineNames_nic[i]
  ]
}]

resource shutdown_computevm_portalVirtualMachineNames 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOfPortalVirtualMachines): if (string(enableAutoShutDown) == 'True') {
  name: 'shutdown-computevm-${portalVirtualMachineNames_var[i]}'
  location: location
  properties: {
    status: 'Enabled'
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', portalVirtualMachineNames_var[i])
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    portalVirtualMachineNames_resource[i]
  ]
}]

resource portalVirtualMachineNames_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfPortalVirtualMachines): if (string(joinWindowsDomain) == 'True') {
  name: '${portalVirtualMachineNames_var[i]}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Portal Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    portalVirtualMachineNames_resource[i]
  ]
}]

resource dataStoreAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: dataStoreAvailablitySetName
  location: location
  tags: {
    displayName: 'Data Store Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource dataStoreVirtualMachineNames_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOfDataStoreVirtualMachines): {
  name: '${dataStoreVirtualMachineNames_var[i]}-${nicName}'
  location: location
  tags: {
    displayName: 'Data Store Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource dataStoreVirtualMachineNames_resource 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOfDataStoreVirtualMachines): if (!empty(adminPassword)) {
  name: dataStoreVirtualMachineNames_var[i]
  location: location
  tags: {
    'arcgis-vm-roles': 'DataStore'
    'arcgis-deployment-id': deploymentId
    displayName: 'Data Store Virtual Machines'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: dataStoreAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: dataStoreVirtualMachineSize
    }
    osProfile: {
      computerName: dataStoreVirtualMachineNames_var[i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].Publisher}","offer":"${imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].Offer}","sku":"${imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].SKU}","version":"latest"}') : ((string(imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].UserImageName))}"}') : json('{"id":"${string(imageReferences[dataStoreVirtualMachineImageSpecs_var[i]].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${dataStoreVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: dataStoreVirtualMachineOSDiskType
        }
        diskSizeGB: dataStoreVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableDataStoreVirtualMachineDataDisk) == 'True') ? json('[{"name":"${dataStoreVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${dataStoreVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${dataStoreVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${dataStoreVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    dataStoreVirtualMachineNames_nic[i]
  ]
}]

resource shutdown_computevm_dataStoreVirtualMachineNames 'Microsoft.DevTestLab/schedules@2018-09-15' = [for item in dataStoreVirtualMachineNames_var: if (string(enableAutoShutDown) == 'True') {
  name: 'shutdown-computevm-${item}'
  location: location
  properties: {
    status: 'Enabled'
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', item)
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    dataStoreVirtualMachineNames_resource
  ]
}]

resource dataStoreVirtualMachineNames_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for item in dataStoreVirtualMachineNames_var: if (string(joinWindowsDomain) == 'True') {
  name: '${item}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Data Store Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    dataStoreVirtualMachineNames_resource
  ]
}]

resource fileShareVirtualMachineName_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = {
  name: '${fileShareVirtualMachineName}-${nicName}'
  location: location
  tags: {
    displayName: 'File Share Network Interface'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}

resource fileShareVirtualMachine 'Microsoft.Compute/virtualMachines@2018-06-01' = if (!empty(adminPassword)) {
  name: fileShareVirtualMachineName
  location: location
  tags: {
    'arcgis-vm-roles': 'FileShare'
    displayName: 'File Share'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    hardwareProfile: {
      vmSize: fileShareVirtualMachineSize
    }
    osProfile: {
      computerName: fileShareVirtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: ((contains(arcgisDeploymentVersion, '@') && (first(split(arcgisDeploymentVersion, '@')) != '11.0')) ? '2019-Datacenter-smalldisk' : '2022-datacenter-smalldisk-g2')
        version: windowsServerBaseImageReferenceVersion
      }
      osDisk: {
        name: '${fileShareVirtualMachineName}-OsDisk'
        managedDisk: {
          storageAccountType: fileShareVirtualMachineOSDiskType
        }
        diskSizeGB: fileShareVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableFileShareVirtualMachineDataDisk) == 'True') ? json('[{"name":"${fileShareVirtualMachineName}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${fileShareVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${fileShareVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: fileShareVirtualMachineName_nic.id
        }
      ]
    }
  }
}

resource shutdown_computevm_fileShareVirtualMachine 'Microsoft.DevTestLab/schedules@2018-09-15' = if (string(enableAutoShutDown) == 'True') {
  name: 'shutdown-computevm-${fileShareVirtualMachineName}'
  location: location
  properties: {
    status: 'Enabled'
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: fileShareVirtualMachine.id
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
  ]
}

resource fileShareVirtualMachineName_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = if (string(joinWindowsDomain) == 'True') {
  name: 'JoinDomain'
  parent: fileShareVirtualMachine
  location: location
  tags: {
    displayName: '(Optional) File Share Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [

  ]
}

module generateSSLCertificatesCustomExtension_name './modules/generatecertificate-cse.bicep' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'),'/','generatecertificate-cse.json', parameters('_artifactsLocationSasToken'))]*/ = if ((!empty(selfSignedSSLCertificatePassword)) || ((!empty(serverInternalCertificatePassword)) && (!empty(portalInternalCertificatePassword)))) {
  name: 'generateSSLCertificatesCustomExtension-${deployment().name}'
  params: {
    location: location
    vmName: fileShareVirtualMachineName
    useSelfSignedInternalSSLCertificate: useSelfSignedInternalSSLCertificate
    selfSignedSSLCertificatePassword: selfSignedSSLCertificatePassword
    serverInternalCertificateFileName: serverInternalCertificateFileName
    portalInternalCertificateFileName: portalInternalCertificateFileName
    fileShareName: fileShareName
    serverVirtualMachineNames: serverVirtualMachineNames
    portalVirtualMachineNames: portalVirtualMachineNames
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
  }
  dependsOn: [
    serverVirtualMachineNames_JoinDomain
    portalVirtualMachineNames_JoinDomain
    fileShareVirtualMachineName_JoinDomain
  ]
}


module appGatewayNestedDeployment_name './modules/nested_appGatewayNestedDeployment_name.bicep' = {
  name: 'appGatewayNestedDeployment-${deployment().name}'
  scope: resourceGroup(appGatewayResourceGroupName)
  params: {
    appGatewayName: appGatewayName
    location: location
    sslCertificateData: sslCertificateData
    sslCertificatePassword: sslCertificatePassword
    joinWindowsDomain: joinWindowsDomain
    windowsDomainName: windowsDomainName
    secondaryDnsHostName: secondaryDnsHostName
    externalDnsHostName: externalDnsHostName
    serverContext: serverContext
    applicationGatewayName: appGatewayName
    publicIpId: publicIPAddressRDPResource.id
    resourceGroup: resourceGroup().name
    resourceSuffix: resourceSuffix
    serverVirtualMachineNames: serverVirtualMachineNames
    userAssignedIdenityResourceId: userAssignedIdentity.outputs.resourceId
    virtualNetworkName: virtualNetworkName
  }
  dependsOn: [
    generateSSLCertificatesCustomExtension_name
  ]
}

resource fileShareVirtualMachineName_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = if ((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) {
  name: 'LogAnalytics'
  parent: fileShareVirtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: []
}

resource fileShareVirtualMachineName_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = if (!empty(adminPassword)) {
  name: 'DSCConfiguration'
  parent: fileShareVirtualMachine
  location: location
  tags: {
    displayName: 'File Share DSC Script'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: fileShareDscScriptFunction
        script: '${fileShareDscScriptFunction}.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        OSDiskSize: fileShareVirtualMachineOSDiskSize
        EnableDataDisk: string(enableFileShareVirtualMachineDataDisk)
        IsBaseDeployment: 'True'
        ExternalDNSHostName: externalDnsHostName
        PortalContext: portalContext
        FileShareName: fileShareName
        DebugMode: string(debugMode)
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        MachineAdministratorCredential: {
          userName: adminUsername
          password:  adminPassword
        }
      }
    }
  }
  dependsOn: [
    generateSSLCertificatesCustomExtension_name
  ]
}

resource serverVirtualMachineNames_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfServerVirtualMachines): if ((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) {
  name: '${serverVirtualMachineNames_var[i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    serverVirtualMachineNames_resource[i]
  ]
}]

@batchSize(1)
resource serverVirtualMachineNames_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(1, numberOfServerVirtualMachines): {
  name: 'DSCConfiguration'
  parent: serverVirtualMachineNames_resource[i]
  location: location
  tags: {
    displayName: 'Server DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: serverDscScriptFunction
        script: '${serverDscScriptFunction}.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        PublicKeySSLCertificateFileUrl: (empty(publicKeySSLCertificateFileName) ? '' : '${_artifactsLocation}/${publicKeySSLCertificateFileName}${_artifactsLocationSasToken}')
        ServerLicenseFileUrl: (empty(serverLicenseFileName) ? '' : '${_artifactsLocation}/${serverLicenseFileName}${_artifactsLocationSasToken}')
        ServerMachineNames: serverVirtualMachineNames
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: useCloudStorage
        UseAzureFiles: useAzureFiles
        OSDiskSize: serverVirtualMachineOSDiskSize
        EnableDataDisk: string(enableServerVirtualMachineDataDisk)
        EnableLogHarvesterPlugin: string(enableServerLogHarvesterPlugin)
        DebugMode: string(debugMode)
        ServerContext: serverContext
        IsUpdatingCertificates: isUpdatingCertificates
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
        ServerInternalCertificatePassword: {
          userName: 'Placeholder'
          password: ((string(useSelfSignedInternalSSLCertificate) == 'True') ? selfSignedSSLCertificatePassword : serverInternalCertificatePassword)
        }
        StorageAccountCredential: {
          userName:  useCloudStorage ? cloudStorageAccountCredentialsUserName : 'placeholder'
          password:  useCloudStorage ? cloudStorageAccountCredentialsPassword : 'placeholder'
      }
    }
  }
  dependsOn: [
    createAFS_name
    fileShareVirtualMachineName_DSCConfiguration
    appGatewayNestedDeployment_name
  ]
}]

resource portalVirtualMachineNames_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = [for i in range(0, numberOfPortalVirtualMachines): if ((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) {
  name: '${portalVirtualMachineNames_var[i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    portalVirtualMachineNames_resource[i]
  ]
}]

@batchSize(1)
resource portalVirtualMachineNames_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfPortalVirtualMachines): {
  name: '${portalVirtualMachineNames_var[i]}/DSCConfiguration'
  location: location
  tags: {
    displayName: 'Portal DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: portalDscScriptFunction
        script: '${portalDscScriptFunction}.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        PublicKeySSLCertificateFileUrl: (empty(publicKeySSLCertificateFileName) ? '' : '${_artifactsLocation}/${publicKeySSLCertificateFileName}${_artifactsLocationSasToken}')
        PortalLicenseFileUrl: (empty(portalLicenseFileName) ? '' : '${_artifactsLocation}/${portalLicenseFileName}${_artifactsLocationSasToken}')
        PortalLicenseUserTypeId: (empty(portalLicenseUserTypeId) ? '' : portalLicenseUserTypeId)
        ServerMachineNames: serverVirtualMachineNames
        PortalMachineNames: portalVirtualMachineNames
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ExternalDNSHostName: externalDnsHostName
        PrivateDNSHostName: secondaryDnsHostName
        UseCloudStorage: useCloudStorage
        UseAzureFiles: useAzureFiles
        OSDiskSize: portalVirtualMachineOSDiskSize
        EnableDataDisk: string(enablePortalVirtualMachineDataDisk)
        DebugMode: string(debugMode)
        ServerContext: serverContext
        PortalContext: portalContext
        IsUpdatingCertificates: isUpdatingCertificates
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
        PortalInternalCertificatePassword: {
          userName: 'Placeholder'
          password: ((string(useSelfSignedInternalSSLCertificate) == 'True') ? selfSignedSSLCertificatePassword : portalInternalCertificatePassword)
        }
        StorageAccountCredential: {
          userName:  useCloudStorage ? cloudStorageAccountCredentialsUserName : 'placeholder'
          password:  useCloudStorage ? cloudStorageAccountCredentialsPassword : 'placeholder'
        }
      }
    }
  }
  dependsOn: [
    createAFS_name
   appGatewayNestedDeployment_name
    fileShareVirtualMachineName_DSCConfiguration
    dataStoreVirtualMachineNames_DSCConfiguration
  ]
}]

resource dataStoreVirtualMachineNames_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = [for i in range(0, numberOfDataStoreVirtualMachines): if ((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) {
  name: '${dataStoreVirtualMachineNames_var[i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    dataStoreVirtualMachineNames_resource[i]
  ]
}]

@batchSize(1)
resource dataStoreVirtualMachineNames_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfDataStoreVirtualMachines): {
  name: '${dataStoreVirtualMachineNames_var[i]}/DSCConfiguration'
  location: location
  tags: {
    displayName: 'Data Store DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: dataStoreDscScriptFunction
        script: '${dataStoreDscScriptFunction}.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        DataStoreMachineNames: dataStoreVirtualMachineNames
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ServerMachineNames: serverVirtualMachineNames
        OSDiskSize: dataStoreVirtualMachineOSDiskSize
        EnableDataDisk: string(enableDataStoreVirtualMachineDataDisk)
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: useCloudStorage
        UseAzureFiles: useAzureFiles
        DebugMode: string(debugMode)
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
        StorageAccountCredential: {
          userName:  useCloudStorage ? cloudStorageAccountCredentialsUserName : 'placeholder'
          password:  useCloudStorage ? cloudStorageAccountCredentialsPassword : 'placeholder'
        }
      }
    }
  }
  dependsOn: [
    createAFS_name
    dataStoreVirtualMachineNames_resource[i]
    dataStoreVirtualMachineNames_JoinDomain[i]
    serverVirtualMachineNames_DSCConfiguration
  ]
}]

resource tileCacheDataStoreAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = if (string(enableTileCacheDataStore) == 'True') {
  name: tileCacheDataStoreAvailablitySetName
  location: location
  tags: {
    displayName: '(Optional) Tile Cache Data Store Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOftileCacheDataStoreVirtualMachines): if (string(enableTileCacheDataStore) == 'True') {
  name: '${tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]}-${nicName}'
  location: location
  tags: {
    displayName: '(Optional) Tile Cache Data Store Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOftileCacheDataStoreVirtualMachines): if ((!empty(adminPassword)) && (string(enableTileCacheDataStore) == 'True')) {
  name: tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]
  location: location
  tags: {
    'arcgis-vm-roles': 'TileCacheDataStore'
    'arcgis-deployment-id': deploymentId
    displayName: '(Optional) Tile Cache Data Store Virtual Machines'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: tileCacheDataStoreAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: tileCacheDataStoreVirtualMachineSize
    }
    osProfile: {
      computerName: tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].Publisher}","offer":"${imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].Offer}","sku":"${imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].SKU}","version":"latest"}') : ((string(imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].UserImageName))}"}') : json('{"id":"${string(imageReferences[string(tileCacheDataStoreVirtualMachineImageSpecsOptions[string(enableTileCacheDataStore)][i])].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${tileCacheDataStoreVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: tileCacheDataStoreVirtualMachineOSDiskType
        }
        diskSizeGB: tileCacheDataStoreVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableTileCacheDataStoreVirtualMachineDataDisk) == 'True') ? json('[{"name":"${tileCacheDataStoreVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${tileCacheDataStoreVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${tileCacheDataStoreVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${tileCacheDataStoreVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore_nic[i]
  ]
}]

resource shutdown_computevm_tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOftileCacheDataStoreVirtualMachines): if ((string(enableTileCacheDataStore) == 'True') && (string(enableAutoShutDown) == 'True')) {
  name: 'shutdown-computevm-${tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]}'
  location: location
  properties: {
    status: 'Enabled'
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', tileCacheDataStoreVirtualMachineNames_var[i])
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore[i]
  ]
}]

resource tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, length(tileCacheDataStoreVirtualMachineNames_var)): if ((string(enableTileCacheDataStore) == 'True') && (string(joinWindowsDomain) == 'True')) {
  name: '${tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Tile Cache Store Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore[i]
  ]
}]

resource tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = [for i in range(0, numberOftileCacheDataStoreVirtualMachines): if (((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) && enableTileCacheDataStore) {
  name: '${tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore[i]
  ]
}]

@batchSize(1)
resource tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOftileCacheDataStoreVirtualMachines): if (string(enableTileCacheDataStore) == 'True') {
  name: '${tileCacheDataStoreVirtualMachineNameOptions[string(enableTileCacheDataStore)][i]}/DSCConfiguration'
  location: location
  tags: {
    displayName: '(Optional) Tile Cache Data Store DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: tileCacheDataStoreDscScriptFunction
        script: '${tileCacheDataStoreDscScriptFunction}.ps1'
      }
      advancedOptions: {
        forcePullAndApply: false
      }
      configurationArguments: {
        IsTileCacheDataStoreClustered: isTileCacheDataStoreClustered
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        TileCacheDataStoreMachineNames: tileCacheDataStoreVirtualMachineNames
        IsMultiMachineTileCache: isMultiMachineTileCacheDataStore
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ServerMachineNames: serverVirtualMachineNames
        OSDiskSize: tileCacheDataStoreVirtualMachineOSDiskSize
        EnableDataDisk: string(enableTileCacheDataStoreVirtualMachineDataDisk)
        DebugMode: string(debugMode)
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
      }
    }
  }
  dependsOn: [
    serverVirtualMachineNames_DSCConfiguration
    tileCacheDataStoreVirtualMachineNameOptions_enableTileCacheDataStore[i]
  ]
}]

resource spatiotemporalBigDataStoreAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = if (string(enableSpatiotemporalBigDataStore) == 'True') {
  name: spatiotemporalBigDataStoreAvailablitySetName
  location: location
  tags: {
    displayName: '(Optional) Big Data Store Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOfSpatiotemporalBigDataStoreVirtualMachines): if (string(enableSpatiotemporalBigDataStore) == 'True') {
  name: '${spatiotemporalBigDataStoreVirtualMachineNameOptions[string(enableSpatiotemporalBigDataStore)][i]}-${nicName}'
  location: location
  tags: {
    displayName: '(Optional) Big Data Store Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOfSpatiotemporalBigDataStoreVirtualMachines): if ((!empty(adminPassword)) && (string(enableSpatiotemporalBigDataStore) == 'True')) {
  name: spatiotemporalBigDataStoreVirtualMachineNameOptions[string(enableSpatiotemporalBigDataStore)][i]
  location: location
  tags: {
    'arcgis-vm-roles': 'SpatiotemporalDataStore'
    'arcgis-deployment-id': deploymentId
    displayName: '(Optional) Big Data Store Virtual Machines'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: spatiotemporalBigDataStoreAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: spatiotemporalBigDataStoreVirtualMachineSize
    }
    osProfile: {
      computerName: spatiotemporalBigDataStoreVirtualMachineNameOptions[string(enableSpatiotemporalBigDataStore)][i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].Publisher}","offer":"${imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].Offer}","sku":"${imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].SKU}","version":"latest"}') : ((string(imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].UserImageName))}"}') : json('{"id":"${string(imageReferences[string(spatiotemporalBigDataStoreVirtualMachineImageSpecsOptions[string(enableSpatiotemporalBigDataStore)][i])].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${spatiotemporalBigDataStoreVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: spatiotemporalBigDataStoreVirtualMachineOSDiskType
        }
        diskSizeGB: spatiotemporalBigDataStoreVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableSpatiotemporalBigDataStoreVirtualMachineDataDisk) == 'True') ? json('[{"name":"${spatiotemporalBigDataStoreVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${spatiotemporalBigDataStoreVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${spatiotemporalBigDataStoreVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${spatiotemporalBigDataStoreVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore_nic[i]
  ]
}]

resource shutdown_computevm_spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOfSpatiotemporalBigDataStoreVirtualMachines): if ((string(enableSpatiotemporalBigDataStore) == 'True') && (string(enableAutoShutDown) == 'True')) {
  name: 'shutdown-computevm-${spatiotemporalBigDataStoreVirtualMachineNameOptions[string(enableSpatiotemporalBigDataStore)][i]}'
  location: location
  properties: {
    status: (enableAutoShutDown ? 'Enabled' : 'Disabled')
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', spatiotemporalBigDataStoreVirtualMachineNames_var[i])
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore[i]
  ]
}]

resource spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = [for i in range(0, numberOfSpatiotemporalBigDataStoreVirtualMachines): if (((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) && enableSpatiotemporalBigDataStore) {
  name: '${spatiotemporalBigDataStoreVirtualMachineNameOptions[string(enableSpatiotemporalBigDataStore)][i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore[i]
  ]
}]

@batchSize(1)
resource spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfSpatiotemporalBigDataStoreVirtualMachines): if (string(enableSpatiotemporalBigDataStore) == 'True') {
  name: 'DSCConfiguration'
  parent: spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore[i]
  location: location
  tags: {
    displayName: '(Optional) Big Data Store DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: spatiotemporalBigDataStoreDscScriptFunction
        script: '${spatiotemporalBigDataStoreDscScriptFunction}.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        SpatiotemporalBigDataStoreMachineNames: spatiotemporalBigDataStoreVirtualMachineNames
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ServerMachineNames: serverVirtualMachineNames
        OSDiskSize: spatiotemporalBigDataStoreVirtualMachineOSDiskSize
        EnableDataDisk: string(enableSpatiotemporalBigDataStoreVirtualMachineDataDisk)
        DebugMode: string(debugMode)
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
      }
    }
  }
  dependsOn: [
    serverVirtualMachineNames_DSCConfiguration
  ]
}]

resource spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, length(spatiotemporalBigDataStoreVirtualMachineNames_var)): if ((string(enableSpatiotemporalBigDataStore) == 'True') && (string(joinWindowsDomain) == 'True')) {
  name: '${spatiotemporalBigDataStoreVirtualMachineNameOptions[string(enableSpatiotemporalBigDataStore)][i]}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Big Data Store Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    spatiotemporalBigDataStoreVirtualMachineNameOptions_enableSpatiotemporalBigDataStore[i]
  ]
}]

resource graphDataStoreAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = if (string(enableGraphDataStore) == 'True') {
  name: graphDataStoreAvailablitySetName
  location: location
  tags: {
    displayName: '(Optional) Graph Store Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource graphDataStoreVirtualMachineNameOptions_enableGraphDataStore_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOfGraphDataStoreVirtualMachines): if (string(enableGraphDataStore) == 'True') {
  name: '${graphDataStoreVirtualMachineNameOptions[string(enableGraphDataStore)][i]}-${nicName}'
  location: location
  tags: {
    displayName: '(Optional) Graph Store Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource graphDataStoreVirtualMachineNameOptions_enableGraphDataStore 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOfGraphDataStoreVirtualMachines): if ((!empty(adminPassword)) && (string(enableGraphDataStore) == 'True')) {
  name: graphDataStoreVirtualMachineNameOptions[string(enableGraphDataStore)][i]
  location: location
  tags: {
    'arcgis-vm-roles': 'GraphDataStore'
    'arcgis-deployment-id': deploymentId
    displayName: '(Optional) Graph Store Virtual Machines'
  }
  plan:{
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: graphDataStoreAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: graphDataStoreVirtualMachineSize
    }
    osProfile: {
      computerName: graphDataStoreVirtualMachineNameOptions[string(enableGraphDataStore)][i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].Publisher}","offer":"${imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].Offer}","sku":"${imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].SKU}","version":"latest"}') : ((string(imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].UserImageName))}"}') : json('{"id":"${string(imageReferences[string(graphDataStoreVirtualMachineImageSpecsOptions[string(enableGraphDataStore)][i])].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${graphDataStoreVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: graphDataStoreVirtualMachineOSDiskType
        }
        diskSizeGB: graphDataStoreVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableGraphDataStoreVirtualMachineDataDisk) == 'True') ? json('[{"name":"${graphDataStoreVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${graphDataStoreVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${graphDataStoreVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${graphDataStoreVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    graphDataStoreVirtualMachineNameOptions_enableGraphDataStore_nic[i]
  ]
}]

resource shutdown_computevm_graphDataStoreVirtualMachineNameOptions_enableGraphDataStore 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOfGraphDataStoreVirtualMachines): if ((string(enableGraphDataStore) == 'True') && (string(enableAutoShutDown) == 'True')) {
  name: 'shutdown-computevm-${graphDataStoreVirtualMachineNameOptions[string(enableGraphDataStore)][i]}'
  location: location
  properties: {
    status: ((string(enableAutoShutDown) == 'True') ? 'Enabled' : 'Disabled')
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', graphDataStoreVirtualMachineNames_var[i])
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    graphDataStoreVirtualMachineNameOptions_enableGraphDataStore[i]
  ]
}]

resource graphDataStoreVirtualMachineNameOptions_enableGraphDataStore_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, length(graphDataStoreVirtualMachineNames_var)): if ((string(enableGraphDataStore) == 'True') && (string(joinWindowsDomain) == 'True')) {
  name: '${graphDataStoreVirtualMachineNameOptions[string(enableGraphDataStore)][i]}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Graph Store Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    graphDataStoreVirtualMachineNameOptions_enableGraphDataStore[i]
  ]
}]

resource graphDataStoreVirtualMachineNameOptions_enableGraphDataStore_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = [for i in range(0, numberOfGraphDataStoreVirtualMachines): if (((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) && enableGraphDataStore) {
  name: '${graphDataStoreVirtualMachineNameOptions[string(enableGraphDataStore)][i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    graphDataStoreVirtualMachineNameOptions_enableGraphDataStore[i]
  ]
}]

@batchSize(1)
resource graphDataStoreVirtualMachineNameOptions_enableGraphDataStore_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfGraphDataStoreVirtualMachines): if (string(enableGraphDataStore) == 'True') {
  name: 'DSCConfiguration'
  parent: graphDataStoreVirtualMachineNameOptions_enableGraphDataStore[i]
  location: location
  tags: {
    displayName: '(Optional) Graph Data Store DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: graphDataStoreDscScriptFunction
        script: '${graphDataStoreDscScriptFunction}.ps1'
      }
      advancedOptions: {
        forcePullAndApply: false
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        GraphDataStoreMachineNames: graphDataStoreVirtualMachineNames
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ServerMachineNames: serverVirtualMachineNames
        OSDiskSize: graphDataStoreVirtualMachineOSDiskSize
        EnableDataDisk: string(enableGraphDataStoreVirtualMachineDataDisk)
        DebugMode: string(debugMode)
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
      }
    }
  }
  dependsOn: [
    serverVirtualMachineNames_DSCConfiguration
    graphDataStoreVirtualMachineNameOptions_enableGraphDataStore[i]
  ]
}]

resource objectDataStoreAvailablitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = if (string(enableObjectDataStore) == 'True') {
  name: objectDataStoreAvailablitySetName
  location: location
  tags: {
    displayName: '(Optional) Object Store Availability Set'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_nic 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, numberOfObjectDataStoreVirtualMachines): if (string(enableObjectDataStore) == 'True') {
  name: '${objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]}-${nicName}'
  location: location
  tags: {
    displayName: '(Optional) Object Store Network Interfaces'
    'arcgis-deployment-id': deploymentId
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource objectDataStoreVirtualMachineNameOptions_enableObjectDataStore 'Microsoft.Compute/virtualMachines@2018-06-01' = [for i in range(0, numberOfObjectDataStoreVirtualMachines): if ((!empty(adminPassword)) && (string(enableObjectDataStore) == 'True')) {
  name: objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]
  location: location
  tags: {
    'arcgis-vm-roles': 'ObjectDataStore'
    'arcgis-deployment-id': deploymentId
    displayName: '(Optional) Object Store Virtual Machines'
  }
  plan: {
    name: 'byol-111'
    product: 'arcgis-enterprise'
    publisher: 'esri'
  }
  properties: {
    availabilitySet: {
      id: objectDataStoreAvailablitySet.id
    }
    hardwareProfile: {
      vmSize: objectDataStoreVirtualMachineSize
    }
    osProfile: {
      computerName: objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        timeZone: timeZoneId
      }
    }
    storageProfile: {
      imageReference: ((string(imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].AzureVMImageType) == '0') ? json('{"publisher":"${imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].Publisher}","offer":"${imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].Offer}","sku":"${imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].SKU}","version":"latest"}') : ((string(imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].AzureVMImageType) == '1') ? json('{"id":"${resourceId(string(imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].UserImageResourceGroupName), 'Microsoft.Compute/images', string(imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].UserImageName))}"}') : json('{"id":"${string(imageReferences[string(objectDataStoreVirtualMachineImageSpecsOptions[string(enableObjectDataStore)][i])].ComputeGalleryImageVersionResourceId)}"}')))
      osDisk: {
        name: '${objectDataStoreVirtualMachineNames_var[i]}-OSDisk'
        managedDisk: {
          storageAccountType: objectDataStoreVirtualMachineOSDiskType
        }
        diskSizeGB: objectDataStoreVirtualMachineOSDiskSize
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: ((string(enableObjectDataStoreVirtualMachineDataDisk) == 'True') ? json('[{"name":"${objectDataStoreVirtualMachineNames_var[i]}-DataDisk", "lun": 0, "createOption": "empty", "diskSizeGB": "${objectDataStoreVirtualMachineDataDiskSize}", "managedDisk": { "storageAccountType":"${objectDataStoreVirtualMachineDataDiskType}"} }]') : null)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${objectDataStoreVirtualMachineNames_var[i]}-${nicName}')
        }
      ]
    }
  }
  dependsOn: [
    objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_nic[i]
  ]
}]

resource shutdown_computevm_objectDataStoreVirtualMachineNameOptions_enableObjectDataStore 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in range(0, numberOfObjectDataStoreVirtualMachines): if ((string(enableObjectDataStore) == 'True') && (string(enableAutoShutDown) == 'True')) {
  name: 'shutdown-computevm-${objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]}'
  location: location
  properties: {
    status: ((string(enableAutoShutDown) == 'True') ? 'Enabled' : 'Disabled')
    timeZoneId: timeZoneId
    taskType: 'ComputeVmShutdownTask'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 15
      webhookUrl: ''
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines/', objectDataStoreVirtualMachineNames_var[i])
    dailyRecurrence: {
      time: autoShutDownTime
    }
  }
  dependsOn: [
    objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_nic[i]
  ]
}]

resource objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_JoinDomain 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, length(objectDataStoreVirtualMachineNames_var)): if ((string(enableObjectDataStore) == 'True') && (string(joinWindowsDomain) == 'True')) {
  name: '${objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]}/JoinDomain'
  location: location
  tags: {
    displayName: '(Optional) Object Store Domain Join'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: windowsDomainName
      User: windowsDomainAdministratorUserName
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: windowsDomainAdministratorPassword
    }
  }
  dependsOn: [
    objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_nic[i]
  ]
}]

resource objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_LogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfObjectDataStoreVirtualMachines): if (((!empty(omsWorkspaceResourceGroupName)) && (!empty(omsWorkspaceName))) && enableObjectDataStore) {
  name: '${objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]}/LogAnalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: ((!empty(omsWorkspaceResourceId)) ? reference(omsWorkspaceResourceId, '2015-11-01-preview').customerId : null)
    }
    protectedSettings: {
      workspaceKey: ((!empty(omsWorkspaceResourceId)) ? listKeys(omsWorkspaceResourceId, '2015-11-01-preview').primarySharedKey : null)
    }
  }
  dependsOn: [
    objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_nic[i]
  ]
}]

@batchSize(1)
resource objectDataStoreVirtualMachineNameOptions_enableObjectDataStore_DSCConfiguration 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = [for i in range(0, numberOfObjectDataStoreVirtualMachines): if (string(enableObjectDataStore) == 'True') {
  name: '${objectDataStoreVirtualMachineNameOptions[string(enableObjectDataStore)][i]}/DSCConfiguration'
  location: location
  tags: {
    displayName: '(Optional) Object Data Store DSC Scripts'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: '${_artifactsLocation}/${dscExtensionArchiveFileName}'
        function: objectDataStoreDscScriptFunction
        script: '${objectDataStoreDscScriptFunction}.ps1'
      }
      advancedOptions: {
        forcePullAndApply: false
      }
      configurationArguments: {
        IsObjectDataStoreClustered: isObjectDataStoreClustered
        ServiceCredentialIsDomainAccount: arcgisServiceAccountIsDomainAccount
        ObjectDataStoreMachineNames: objectDataStoreVirtualMachineNames
        FileShareMachineName: fileShareVirtualMachineName
        FileShareName: fileShareName
        ServerMachineNames: serverVirtualMachineNames
        OSDiskSize: objectDataStoreVirtualMachineOSDiskSize
        EnableDataDisk: string(enableObjectDataStoreVirtualMachineDataDisk)
        DebugMode: string(debugMode)
      }
    }
    protectedSettings: {
      configurationUrlSasToken: _artifactsLocationSasToken
      configurationArguments: {
        ServiceCredential: {
          userName: arcgisServiceAccountUserName
          password: arcgisServiceAccountPassword
        }
        SiteAdministratorCredential: {
          userName: primarySiteAdministratorAccountUserName
          password: primarySiteAdministratorAccountPassword
        }
      }
    }
  }
  dependsOn: [
    serverVirtualMachineNames_DSCConfiguration
    objectDataStoreVirtualMachineNameOptions_enableObjectDataStore[i]
  ]
}]
