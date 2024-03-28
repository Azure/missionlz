[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]$Parameters
)

$ErrorActionPreference = 'Stop'

try 
{
	# Convert JSON string to PowerShell
	$Values = $Parameters.Replace('\"', '"') | ConvertFrom-Json

	# Set Variables
	$DestinationGalleryName = $Values.computeGalleryResourceId.Split('/')[8]
	$DestinationGalleryResourceGroupName = $Values.computeGalleryResourceId.Split('/')[4]
	$DestinationImageDefinitionName = $Values.imageDefinitionName

    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.Resources'
    Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Imported the required modules."

	# Disable saving of Azure Context
    Disable-AzContextAutosave -Scope Process | Out-Null
	Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Disabled saving of Azure Context."

    # Connect to Azure using the System Assigned Identity
    $AzureContext = (Connect-AzAccount -Environment $Values.environmentName -Subscription $Values.subscriptionId -Tenant $Values.tenantId -Identity -AccountId $Values.userAssignedIdentityClientId).Context
    Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Connected to Azure."

	# Cleanup previous image build
	$RunCommandNames = @('generalizeVirtualMachine','removeVirtualMachine','restartVirtualMachine')
    foreach($RunCommandName in $RunCommandNames)
    {
        Remove-AzVMRunCommand -ResourceGroupName $Values.resourceGroupName -VMName $Values.managementVirtualMachineName -RunCommandName $RunCommandName
        Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Removed '$RunCommandName' Run Command"
    }

	# Get date on the latest image gallery version
    $CurrentImageVersionDate = (Get-AzGalleryImageVersion -ResourceGroupName $DestinationGalleryResourceGroupName -GalleryName $DestinationGalleryName -GalleryImageDefinitionName $DestinationImageDefinitionName -DefaultProfile $AzureContext | Where-Object {$_.ProvisioningState -eq 'Succeeded'}).PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
    Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Compute Gallery Image (Destination), Latest Version Date: $CurrentImageVersionDate."
	
    switch($Values.sourceImageType)
    {
        'AzureComputeGallery' {
			# Set Variables
			$SourceGalleryName = $Values.computeGalleryImageResourceId.Split('/')[8]
			$SourceGalleryResourceGroupName = $Values.computeGalleryImageResourceId.Split('/')[4]
			$SourceImageDefinitionName = $Values.computeGalleryImageResourceId.Split('/')[10]

            # Get the date of the latest image definition version
            $SourceImageVersionDate = (Get-AzGalleryImageVersion -ResourceGroupName $SourceGalleryResourceGroupName -GalleryName $SourceGalleryName -GalleryImageDefinitionName $SourceImageDefinitionName -DefaultProfile $AzureContext | Where-Object {$_.PublishingProfile.ExcludeFromLatest -eq $false -and $_.ProvisioningState -eq 'Succeeded'}).PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
            Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Compute Gallery Image (Source), Latest Version Date: $SourceImageVersionDate."
        }
        'AzureMarketplace' {
            # Get the date of the latest marketplace image version
            $ImageVersionDateRaw = (Get-AzVMImage -Location $Values.location -PublisherName $Values.marketplaceImagePublisher -Offer $Values.marketplaceImageOffer -Skus $Values.marketplaceImageSku -DefaultProfile $AzureContext | Sort-Object -Property 'Version' -Descending | Select-Object -First 1).Version.Split('.')[-1]
            $Year = '20' + $ImageVersionDateRaw.Substring(0,2)
            $Month = $ImageVersionDateRaw.Substring(2,2)
            $Day = $ImageVersionDateRaw.Substring(4,2)
            $SourceImageVersionDate = Get-Date -Year $Year -Month $Month -Day $Day -Hour 00 -Minute 00 -Second 00
            Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Marketplace Image (Source), Latest Version Date: $SourceImageVersionDate."
        }
    }

	# If the latest source image was released after the last image build then trigger a new image build
	if($SourceImageVersionDate -gt $CurrentImageVersionDate -or !$CurrentImageVersionDate)
	{   
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build initiated with a new source image version."
		$TemplateParameters = @{
			arcGisProInstaller = $Values.arcGisProInstaller
			computeGalleryImageResourceId = $Values.computeGalleryImageResourceId
			computeGalleryName = $Values.computeGalleryResourceId.Split('/')[8]
			containerName = $Values.containerName
			diskEncryptionSetResourceId = $Values.diskEncryptionSetResourceId
			enableBuildAutomation = if($Values.enableBuildAutomation -eq 'true'){$true}else{$false}
			excludeFromLatest = $Values.excludeFromLatest
			hybridUseBenefit = if($Values.hybridUseBenefit -eq 'true'){$true}else{$false}
			imageDefinitionName = $Values.imageDefinitionName
			imageMajorVersion = [int]$Values.imageMajorVersion
			imagePatchVersion = [int]$Values.imagePatchVersion
			imageVirtualMachineName = $Values.imageVirtualMachineName
			installAccess = if($Values.installAccess -eq 'true'){$true}else{$false}
			installArcGisPro = if($Values.installArcGisPro -eq 'true'){$true}else{$false}
			installExcel = if($Values.installExcel -eq 'true'){$true}else{$false}
			installOneDrive = if($Values.installOneDrive -eq 'true'){$true}else{$false}
			installOneNote = if($Values.installOneNote -eq 'true'){$true}else{$false}
			installOutlook = if($Values.installOutlook -eq 'true'){$true}else{$false}
			installPowerPoint = if($Values.installPowerPoint -eq 'true'){$true}else{$false}
			installProject = if($Values.installProject -eq 'true'){$true}else{$false}
			installPublisher = if($Values.installPublisher -eq 'true'){$true}else{$false}
			installSkypeForBusiness = if($Values.installSkypeForBusiness -eq 'true'){$true}else{$false}
			installTeams = if($Values.installTeams -eq 'true'){$true}else{$false}
			installVirtualDesktopOptimizationTool = if($Values.installVirtualDesktopOptimizationTool -eq 'true'){$true}else{$false}
			installVisio = if($Values.installVisio -eq 'true'){$true}else{$false}
			installWord = if($Values.installWord -eq 'true'){$true}else{$false}
			keyVaultName = $Values.keyVaultName
			managementVirtualMachineName = $Values.managementVirtualMachineName
			marketplaceImageOffer = $Values.marketplaceImageOffer
			marketplaceImagePublisher = $Values.marketplaceImagePublisher
			marketplaceImageSKU = $Values.marketplaceImageSKU
			msrdcwebrtcsvcInstaller = $Values.msrdcwebrtcsvcInstaller
			officeInstaller = $Values.officeInstaller
			replicaCount = [int]$Values.replicaCount
			resourceGroupName = $Values.resourceGroupName
			runbookExecution = $true
			sourceImageType = $Values.sourceImageType
			storageAccountResourceId = $Values.storageAccountResourceId
			subnetResourceId = $Values.subnetResourceId
			teamsInstaller = $Values.teamsInstaller
			userAssignedIdentityClientId = $Values.userAssignedIdentityClientId
			userAssignedIdentityPrincipalId = $Values.userAssignedIdentityPrincipalId
			userAssignedIdentityResourceId = $Values.userAssignedIdentityResourceId
			vcRedistInstaller = $Values.vcRedistInstaller
			vDOTInstaller = $Values.vDOTInstaller
			virtualMachineSize = $Values.virtualMachineSize
        }
		if($Values.customizations -ne '[]'){$TemplateParameters.Add('customizations', $Values.customizations)}
        if($Values.tags -ne '{}'){$TemplateParameters.Add('tags', $Values.tags)}
		New-AzDeployment -Location $Values.location -TemplateSpecId $Values.templateSpecResourceId -TemplateParameterObject $TemplateParameters -DefaultProfile $AzureContext
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build succeeded. New image version available in the destination Compute Gallery."
	}
	else 
	{
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build not required. The source image version is older than the latest destination image version."
	}
}
catch 
{
	Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build failed. Review the deployment errors in the Azure Portal and correct the issue."
	Write-Output $($Error[0] | Select-Object *)
	throw
}