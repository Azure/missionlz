<#
.SYNOPSIS
This script sets up the necessary Azure resources and downloads necessary pre-req files for MLZ, and MLZ add-on environment.

.DESCRIPTION
The script first connects to the Azure account associated with the provided environment and subscription ID.
It then creates a new resource group and storage account in the specified location.
A new container named "artifacts" is created in the storage account.

The script then waits until the storage account is created.

Next, the script downloads a list of URLs. If the URL is from the PowerShell Gallery, it downloads the package and uploads it to the "artifacts" container.
If the URL is from GitHub, it downloads the file and uploads it to the "artifacts" container.

.PARAMETER Environment
The Azure environment to connect to.

.PARAMETER StorageAccountName
The name of the Azure storage account to create.

.PARAMETER location
The location to create the Azure resources in.

.PARAMETER ResourceGroupName
The name of the Azure resource group to create.

.PARAMETER subscriptionId
The subscription ID to use when connecting to Azure.

.EXAMPLE
.\Get-PreReqs.ps1 -Environment "AzureCloud" -StorageAccountName "mystorageaccount" -location "westus" -ResourceGroupName "myresourcegroup" -subscriptionId "my-subscription-id"
#>


[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    $Environment,
    [Parameter(Mandatory)]
    $StorageAccountName,
    [Parameter(Mandatory)]
    $location,
    [Parameter(Mandatory)]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    $subscriptionId
)

try {
    Connect-AzAccount -Environment $Environment -Subscription $subscriptionId | Out-Null

}
catch {
    Write-Output -Message $_ -Type 'ERROR'
    throw
}
try {

    Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
    do {
        Write-Host "Waiting for EncryptionAtHost feature to be registered"
    } until (
        (Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute").RegistrationState -eq "Registered"
    )
}
catch {
    Write-Output -Message $_ -Type 'ERROR'
    throw
}
try {
    # New Resource Group
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $location

    # New Storage Account
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
    -Name $StorageAccountName `
    -Location $location `
    -SkuName Standard_LRS `
    -Kind StorageV2 `
    -AllowBlobPublicAccess $true

    # Retrieve the Storage Account
    $storageContext = Get-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccount.StorageAccountName

    # Retrieve the Context from the Storage Account
    $storageContext = $storageAccount.Context

    # Create a new container
    $container = New-AzStorageContainer -Name "artifacts" -Context $storageAccount.Context -Permission Container
}
catch {
    Write-Output -Message $_ -Type 'ERROR'
    throw
}

do {
    Write-Host "Waiting for storage account to be created"
} until (
    Get-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName -Name $storageAccount.StorageAccountName
)

$urls = @(
    "https://github.com/Azure/azure-powershell/releases/download/v10.2.0-August2023/Az-Cmdlets-10.2.0.37547-x64.msi"
    "https://raw.githubusercontent.com/Azure/missionlz/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Get-Validations.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Install-AzurePowerShellAzModule.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Set-AutomationRunbook.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Set-AvdDrainMode.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Set-FileShareScaling.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Set-HostPoolScaling.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Set-NtfsPermissions.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Set-SessionHostConfiguration.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Update-AvdDesktop.ps1"
    "https://github.com/Azure/missionlz/blob/main/src/bicep/add-ons/azureVirtualDesktop/artifacts/Update-AvdWorkspace.ps1"
    "https://www.powershellgallery.com/api/v2/package/az.accounts/2.12.1"
    "https://www.powershellgallery.com/api/v2/package/az.automation/1.9.0"
    "https://www.powershellgallery.com/api/v2/package/az.compute/5.7.0"
    "https://www.powershellgallery.com/api/v2/package/az.resources/6.6.0"
    "https://www.powershellgallery.com/api/v2/package/az.accounts/2.13.1"
    "https://www.powershellgallery.com/api/v2/package/az.resources/6.6.0"
    "https://www.powershellgallery.com/api/v2/package/az.keyVault/4.12.0"
    "https://www.powershellgallery.com/api/v2/package/az.storage/5.1.0"
    "https://www.powershellgallery.com/api/v2/package/az.marketplaceOrdering/2.0.0"
)
foreach ($url in $urls)
{
    Set-Location -Path "$env:windir\temp"
    if($url.Contains("powershellgallery"))
    {
        try {
            $filename = $url.Split("/")[6]
            $extension = "nupkg"
            $version = $url.Split("/")[7]
            $file = $filename + "." + $version + "." + $extension
            Write-Host "downloading $file"
            Invoke-WebRequest -Uri $url -OutFile $file
            Write-Host "uploading $file to $container.name"
            Set-AzStorageBlobContent -File $env:windir\temp\$file -Container $container.name -Blob $file -Context $storageContext -Force
        }
        catch {
            Write-Output -Message $_ -Type 'ERROR'
            throw
        }
    }
    elseif($url.Contains("github"))
    {
        try {
            $filename = $url.Substring($url.LastIndexOf('/') + 1)
            Write-host "downloading $filename"
            Invoke-WebRequest -Uri $url -OutFile "$env:windir\temp\$filename"
            Write-Host "uploading $filename to $container.name"
            Set-AzStorageBlobContent -File $env:windir\temp\$filename -Container $container.name -Blob $filename -Context $storageContext -Force
        }
        catch {
            Write-Output -Message $_ -Type 'ERROR'
            throw
        }
    }
}