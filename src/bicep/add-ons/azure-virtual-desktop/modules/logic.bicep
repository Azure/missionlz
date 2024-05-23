targetScope = 'subscription'

param activeDirectorySolution string
param deploymentLocations array
param diskSku string
param domainName string
param fileShareNames object
param fslogixContainerType string
param fslogixStorageService string
param hostPoolType string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param locations object
param locationVirtualMachines string
param networkName string
param resourceGroupControlPlane string
param resourceGroupFeedWorkspace string
param resourceGroupHosts string
param resourceGroupManagement string
param resourceGroupsNetwork array
param resourceGroupStorage string
param securityPrincipals array
param serviceName string
param sessionHostCount int
param sessionHostIndex int
param virtualMachineNamePrefix string
param virtualMachineSize string

//  BATCH SESSION HOSTS
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var maxResourcesPerTemplateDeployment = 88 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var divisionValue = sessionHostCount / maxResourcesPerTemplateDeployment // This determines if any full batches are required.
var divisionRemainderValue = sessionHostCount % maxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var sessionHostBatchCount = divisionRemainderValue > 0 ? divisionValue + 1 : divisionValue // This determines the total number of batches needed, whether full and / or partial.

//  BATCH AVAILABILITY SETS
// The following variables are used to determine the number of availability sets.
var maxAvSetMembers = 200 // This is the max number of session hosts that can be deployed in an availability set.
var beginAvSetRange = sessionHostIndex / maxAvSetMembers // This determines the availability set to start with.
var endAvSetRange = (sessionHostCount + sessionHostIndex) / maxAvSetMembers // This determines the availability set to end with.
var availabilitySetsCount = length(range(beginAvSetRange, (endAvSetRange - beginAvSetRange) + 1))

// OTHER LOGIC & COMPUTED VALUES
var customImageId = empty(imageVersionResourceId) ? 'null' : '"${imageVersionResourceId}"'
var fileShares = fileShareNames[fslogixContainerType]
var fslogix = fslogixStorageService == 'None' || !contains(activeDirectorySolution, 'DomainServices') ? false : true
var galleryImageOffer = empty(imageVersionResourceId) ? '"${imageOffer}"' : 'null'
var galleryImagePublisher = empty(imageVersionResourceId) ? '"${imagePublisher}"' : 'null'
var galleryImageSku = empty(imageVersionResourceId) ? '"${imageSku}"' : 'null'
var galleryItemId = empty(imageVersionResourceId) ? '"${imagePublisher}.${imageOffer}${imageSku}"' : 'null'
var imageType = empty(imageVersionResourceId) ? '"Gallery"' : '"CustomImage"'
var netbios = split(domainName, '.')[0]
var pooledHostPool = split(hostPoolType, ' ')[0] == 'Pooled' ? true : false
var resourceGroups = union(resourceGroupsCommon, resourceGroupsNetworking, resourceGroupsStorage)
var resourceGroupsCommon = [
  resourceGroupControlPlane
  resourceGroupFeedWorkspace
  resourceGroupHosts
  resourceGroupManagement
]
var resourceGroupsNetworking = length(deploymentLocations) == 2 ? resourceGroupsNetwork : [
  resourceGroupsNetwork[0]
]
var resourceGroupsStorage = fslogix ? [
  resourceGroupStorage
] : []
var roleDefinitions = {
  DesktopVirtualizationPowerOnContributor: '489581de-a3bd-480d-9518-53dea7416b33'
  DesktopVirtualizationUser: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  VirtualMachineUserLogin: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
}
var securityPrincipalsCount = length(securityPrincipals)
var sessionHostNamePrefix = replace(virtualMachineNamePrefix, '${serviceName}${networkName}', '')
var smbServerLocation = locations[locationVirtualMachines].abbreviation
var storageSku = fslogixStorageService == 'None' ? 'None' : split(fslogixStorageService, ' ')[1]
var storageService = split(fslogixStorageService, ' ')[0]
var storageSuffix = environment().suffixes.storage
var timeDifference = locations[locationVirtualMachines].timeDifference
var timeZone = locations[locationVirtualMachines].timeZone
var vmTemplate = '{"domain":"${domainName}","galleryImageOffer":${galleryImageOffer},"galleryImagePublisher":${galleryImagePublisher},"galleryImageSKU":${galleryImageSku},"imageType":${imageType},"customImageId":${customImageId},"namePrefix":"${sessionHostNamePrefix}","osDiskType":"${diskSku}","vmSize":{"id":"${virtualMachineSize}","cores":null,"ram":null,"rdmaEnabled": false,"supportsMemoryPreservingMaintenance": true},"galleryItemId":${galleryItemId},"hibernate":false,"diskSizeGB":0,"securityType":"TrustedLaunch","secureBoot":true,"vTPM":true,"vmInfrastructureType":"Cloud","virtualProcessorCount":null,"memoryGB":null,"maximumMemoryGB":null,"minimumMemoryGB":null,"dynamicMemoryConfig":false}'

output availabilitySetsCount int = availabilitySetsCount
output beginAvSetRange int = beginAvSetRange
output divisionRemainderValue int = divisionRemainderValue
output fileShares array = fileShares
output fslogix bool = fslogix
output maxResourcesPerTemplateDeployment int = maxResourcesPerTemplateDeployment
output netbios string = netbios
output pooledHostPool bool = pooledHostPool
output resourceGroups array = resourceGroups
output roleDefinitions object = roleDefinitions
output sessionHostBatchCount int = sessionHostBatchCount
output securityPrincipalsCount int = securityPrincipalsCount
output smbServerLocation string = smbServerLocation
output storageSku string = storageSku
output storageService string = storageService
output storageSuffix string = storageSuffix
output timeDifference string = timeDifference
output timeZone string = timeZone
output vmTemplate string = vmTemplate
