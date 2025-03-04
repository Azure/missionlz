

<#
/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
.SYNOPSIS
    This script retrieves prerequisites for a specific environment.

.DESCRIPTION
    The script connects to an Azure account using the provided Azure environment and subscription ID.
    It then registers the "EncryptionAtHost" feature for the "Microsoft.Compute" provider.
    Next, it defines a function to generate a unique string.
    The script reads location information from a JSON file and retrieves the abbreviation for the specified Azure environment and location.
    It constructs resource group and storage account names using the provided parameters and the retrieved abbreviation.
    The script creates a new resource group and storage account in the specified location.
    It also creates a new storage container named "artifacts" in the storage account.
    Finally, the script downloads and uploads a list of URLs to the storage container.

.PARAMETER AzureEnvironment
    Specifies the Azure environment to connect to.

.PARAMETER Location
    Specifies the location for the resource group and storage account.

.PARAMETER SubscriptionId
    Specifies the Azure subscription ID to use.

.PARAMETER ResourceNamingPrefix
    Specifies the prefix to use for resource naming.

.PARAMETER MLZEnvironmentName
    Specifies the MLZ environment name.

.EXAMPLE
    Get-PreReqs.ps1 -AzureEnvironment "AzureCloud" -Location "eastus" -SubscriptionId "12345678-1234-1234-1234-1234567890ab" -ResourceNamingPrefix "myapp" -MLZEnvironmentName "dev"
    Retrieves prerequisites for the "dev" MLZ environment in the "eastus" location using the specified Azure environment and subscription ID.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    $AzureEnvironment,
    [Parameter(Mandatory)]
    $Location,
    [Parameter(Mandatory)]
    $SubscriptionId,
    [Parameter(Mandatory)]
    [ValidateLength(3,6)]
    [ValidatePattern("^[a-z0-9]+$")]
    [string]
    $ResourceNamingPrefix,
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'test', 'prod')]
    $MLZEnvironmentName
)

function Get-UniqueString ([string]$id, $length=6)
{
    $hashArray = (new-object System.Security.Cryptography.SHA512Managed).ComputeHash($id.ToCharArray())
    -join ($hashArray[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}

try{
    Connect-AzAccount -Environment $AzureEnvironment -Subscription $SubscriptionId | Out-Null
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
    # Use JSON to get location information from json
    $locationInfo = Get-Content -Path '.\locations.json'  -Raw | ConvertFrom-Json

    # Find abbreviation
    $abbreviation = $locationInfo.$($AzureEnvironment).$($location).abbreviation

    # Resource Group naming
    $ResourceGroupName = $ResourceNamingPrefix + "-rg" + "-fl-" + $MLZEnvironmentName + "-$abbreviation"

    # New Resource Group
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $location

    # Storage account naming
    $uid = Get-UniqueString -id $(Get-AzResourceGroup $ResourceGroupName).ResourceID
    $storageAccountName = $ResourceNamingPrefix + "stfl" + $MLZEnvironmentName + "$abbreviation" + "$uid"

    # New Storage Account
    $StorageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
    -Name $storageAccountName `
    -Location $Location `
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
    'https://github.com/Esri/arcgis-azure-templates/raw/main/Releases/11.1/DSC.zip',
    'https://github.com/Esri/arcgis-azure-templates/raw/main/Releases/11.1/GenerateSSLCerts.ps1'
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