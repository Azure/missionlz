param(
    [string]$Environment,
    [string]$EsriStorageAccount,
    [string]$EsriStorageAccountContainer,
    [string]$PortalLicenseFile,
    [string]$PortalLicenseFileName,
    [string]$ServerLicensefile,
    [string]$ServerLicenseFileName,
    [string]$StorageAccountName,
    [string]$Subscription,
    [string]$UserAssignedIdentityClientId
)
      
New-Item -ItemType File "$env:windir\temp\$portalLicenseFileName"
New-Item -ItemType File "$env:windir\temp\$serverLicenseFileName"

$plf = "$env:windir\temp\$portalLicenseFileName"
$slf = "$env:windir\temp\$serverLicenseFileName"

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

$portalLicense = [System.Text.UTF8Encoding]::UTF8.GetString([System.Convert]::FromBase64String($portalLicensefile))
[System.IO.File]::WriteAllLines($plf, $portalLicense, $Utf8NoBomEncoding)

$serverLicense = [System.Text.UTF8Encoding]::UTF8.GetString([System.Convert]::FromBase64String($serverLicensefile))
[System.IO.File]::WriteAllLines($slf, $serverLicense, $Utf8NoBomEncoding)

Connect-AzAccount -Environment $Environment -Subscription $Subscription -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
$ctx = New-AzStorageContext -StorageAccountName $esriStorageAccount -UseConnectedAccount
Set-AzStorageBlobContent -File $plf -Container $esriStorageAccountContainer -Properties @{"ContentEncoding" = "UTF-8"} -Blob $portalLicenseFileName -Context $ctx -Force
Set-AzStorageBlobContent -File $slf -Container $esriStorageAccountContainer -Properties @{"ContentEncoding" = "UTF-8"} -Blob $serverLicenseFileName -Context $ctx -Force