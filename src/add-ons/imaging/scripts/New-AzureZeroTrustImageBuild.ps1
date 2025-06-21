[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]$Parameters
)

$ErrorActionPreference = 'Stop'

try {
	# Convert JSON string to PowerShell
	$Values = $Parameters.Replace('\"', '"') | ConvertFrom-Json

	# Set Variables
	$DestinationGalleryResourceGroupName = $Values.computeGalleryResourceId.Split('/')[4]
	$DestinationImageDefinitionName = $Values.imageDefinitionName
	$UserAssignedIdentityClientId = $Values.userAssignedIdentityClientId
	$ResourceManagerUri = $Values.resourceManagerUri

	# Fix the resource manager URI since only AzureCloud contains a trailing slash
	$ResourceManagerUriFixed = if ($ResourceManagerUri[-1] -eq '/') { $ResourceManagerUri.Substring(0, $ResourceManagerUri.Length - 1) } else { $ResourceManagerUri }

	# Get an access token for Azure resources
	$AzureManagementAccessToken = (Invoke-RestMethod `
			-Headers @{Metadata = "true" } `
			-Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

	Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Obtained OATH token for Azure."
    
	# Set header for Azure Management API
	$AzureManagementHeader = @{
		'Content-Type'  = 'application/json'
		'Authorization' = 'Bearer ' + $AzureManagementAccessToken
	}
	$RunCommandNames = @('generalizeVirtualMachine', 'removeVirtualMachine', 'restartVirtualMachine')
	foreach ($RunCommandName in $RunCommandNames) {	
		Invoke-RestMethod `
		 -Headers $AzureManagementHeader `
		 -Method 'Delete' `
		 -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $Values.subscriptionId + '/resourceGroups/' + $Values.resourceGroupName + '/providers/Microsoft.Compute/virtualMachines/' + $Values.managementVirtualMachineName + '/runCommands/' + $RunCommandName + '?api-version=2024-03-01')
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Removed '$RunCommandName' Run Command"
	}

	# Get date on the latest image gallery version
	$GalleryImageVersions = (Invoke-RestMethod `
			-Headers $AzureManagementHeader `
			-Method 'Get' `
			-Uri $($ResourceManagerUriFixed + $Values.computeGalleryResourceId + '/images/' + $DestinationImageDefinitionName + '/versions?api-version=2023-07-03')).value | Where-Object { $_.properties.provisioningState -eq 'Succeeded' }
	$CurrentImageVersionDate = $GalleryImageVersions.Properties.PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
	Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Compute Gallery Image (Destination), Latest Version Date: $CurrentImageVersionDate."
	
	switch ($Values.sourceImageType) {
		'AzureComputeGallery' {

			# Get the date of the latest image definition version
			$SourceGalleryImageVersions = (Invoke-RestMethod `
					-Headers $AzureManagementHeader `
					-Method 'Get' `
					-Uri $($ResourceManagerUriFixed + $Values.computeGalleryImageResourceId + '/versions?api-version=2023-07-03')).value | Where-Object { $_.PublishingProfile.ExcludeFromLatest -eq $false -and $_.properties.provisioningState -eq 'Succeeded' }
			$SourceImageVersionDate = $SourceGalleryImageVersions.Properties.PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
			Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Compute Gallery Image (Source), Latest Version Date: $SourceImageVersionDate."
		}
		'AzureMarketplace' {
			# Get the date of the latest marketplace image version
			$MarketPlaceImageVersions = Invoke-RestMethod `
				-Header $AzureManagementHeader `
				-Method 'Get' `
				-Uri $($ResourceManagerUriFixed + '/subscriptions/' + $Values.subscriptionId + '/providers/Microsoft.Compute/locations/' + $Values.location + '/publishers/' + $Values.marketplaceImagePublisher + '/artifacttypes/vmimage/offers/' + $Values.marketplaceImageOffer + '/skus/' + $Values.marketplaceImageSku + '/versions?api-version=2024-03-01')
			$ImageVersionDateRaw = ($MarketPlaceImageVersions | Sort-Object -Property 'Name' -Descending | Select-Object -First 1).Name.Split('.')[-1]
			$Year = '20' + $ImageVersionDateRaw.Substring(0, 2)
			$Month = $ImageVersionDateRaw.Substring(2, 2)
			$Day = $ImageVersionDateRaw.Substring(4, 2)
			$SourceImageVersionDate = Get-Date -Year $Year -Month $Month -Day $Day -Hour 00 -Minute 00 -Second 00
			Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Marketplace Image (Source), Latest Version Date: $SourceImageVersionDate."
		}
	}

	# If the latest source image was released after the last image build then trigger a new image build
	if ($SourceImageVersionDate -gt $CurrentImageVersionDate -or !$CurrentImageVersionDate) {   
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build initiated with a new source image version."
		$TemplateParameters = @{
			arcGisProInstaller                    = $Values.arcGisProInstaller
			computeGalleryImageResourceId         = $Values.computeGalleryImageResourceId
			computeGalleryName                    = $Values.computeGalleryResourceId.Split('/')[8]
			containerName                         = $Values.containerName
			diskEncryptionSetResourceId           = $Values.diskEncryptionSetResourceId
			enableBuildAutomation                 = if ($Values.enableBuildAutomation -eq 'true') { $true }else { $false }
			excludeFromLatest                     = $Values.excludeFromLatest
			hybridUseBenefit                      = if ($Values.hybridUseBenefit -eq 'true') { $true }else { $false }
			imageDefinitionName                   = $Values.imageDefinitionName
			imageMajorVersion                     = [int]$Values.imageMajorVersion
			imagePatchVersion                     = [int]$Values.imagePatchVersion
			imageVirtualMachineName               = $Values.imageVirtualMachineName
			installAccess                         = if ($Values.installAccess -eq 'true') { $true }else { $false }
			installArcGisPro                      = if ($Values.installArcGisPro -eq 'true') { $true }else { $false }
			installExcel                          = if ($Values.installExcel -eq 'true') { $true }else { $false }
			installOneDrive                       = if ($Values.installOneDrive -eq 'true') { $true }else { $false }
			installOneNote                        = if ($Values.installOneNote -eq 'true') { $true }else { $false }
			installOutlook                        = if ($Values.installOutlook -eq 'true') { $true }else { $false }
			installPowerPoint                     = if ($Values.installPowerPoint -eq 'true') { $true }else { $false }
			installProject                        = if ($Values.installProject -eq 'true') { $true }else { $false }
			installPublisher                      = if ($Values.installPublisher -eq 'true') { $true }else { $false }
			installSkypeForBusiness               = if ($Values.installSkypeForBusiness -eq 'true') { $true }else { $false }
			installTeams                          = if ($Values.installTeams -eq 'true') { $true }else { $false }
			installVirtualDesktopOptimizationTool = if ($Values.installVirtualDesktopOptimizationTool -eq 'true') { $true }else { $false }
			installVisio                          = if ($Values.installVisio -eq 'true') { $true }else { $false }
			installWord                           = if ($Values.installWord -eq 'true') { $true }else { $false }
			keyVaultName                          = $Values.keyVaultName
			managementVirtualMachineName          = $Values.managementVirtualMachineName
			marketplaceImageOffer                 = $Values.marketplaceImageOffer
			marketplaceImagePublisher             = $Values.marketplaceImagePublisher
			marketplaceImageSKU                   = $Values.marketplaceImageSKU
			msrdcwebrtcsvcInstaller               = $Values.msrdcwebrtcsvcInstaller
			officeInstaller                       = $Values.officeInstaller
			replicaCount                          = [int]$Values.replicaCount
			resourceGroupName                     = $Values.resourceGroupName
			runbookExecution                      = $true
			sourceImageType                       = $Values.sourceImageType
			storageAccountResourceId              = $Values.storageAccountResourceId
			subnetResourceId                      = $Values.subnetResourceId
			teamsInstaller                        = $Values.teamsInstaller
			userAssignedIdentityClientId          = $Values.userAssignedIdentityClientId
			userAssignedIdentityPrincipalId       = $Values.userAssignedIdentityPrincipalId
			userAssignedIdentityResourceId        = $Values.userAssignedIdentityResourceId
			vcRedistInstaller                     = $Values.vcRedistInstaller
			vDOTInstaller                         = $Values.vDOTInstaller
			virtualMachineSize                    = $Values.virtualMachineSize
		}
		if ($Values.customizations -ne '[]') { $TemplateParameters.Add('customizations', $Values.customizations) }
		if ($Values.mlzTags -ne '{}') { $TemplateParameters.Add('mlzTags', $Values.mlzTags) }
		if ($Values.tags -ne '{}') { $TemplateParameters.Add('tags', $Values.tags) }

		$Body = @{
			'location'   = $Values.location
			'properties' = @{
				'mode'         = 'Incremental'
				'templateLink' = @{
					'id' = $Value.templateSpecResourceId
				}
				'parameters'   = $TemplateParameters
			}
		}
		$Timestamp = Get-Date -Format 'yyyy.MM.dd-HH.mm.ss'
		Invoke-RestMethod `
			-Header $AzureManagementHeader `
			-Body ($Body | ConvertTo-Json) `
			-Method 'PUT' `
			-Uri $($ResourceManagerUriFixed + '/subscriptions/' + $Values.subscriptionId + '/providers/Microsoft.Resources/deployments/imageBuild_' + $timeStamp + '?api-version=2021-04-01')

		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build succeeded. New image version available in the destination Compute Gallery."
	}
	else {
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build not required. The source image version is older than the latest destination image version."
	}
}
catch {
	Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build failed. Review the deployment errors in the Azure Portal and correct the issue."
	Write-Output $($Error[0] | Select-Object *)
	throw
}