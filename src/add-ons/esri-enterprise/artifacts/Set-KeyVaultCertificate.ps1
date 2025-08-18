param(
    [string]$CertificateFileName,
    [string]$CertificatePassword,
    [string]$ContainerName,
    [string]$Environment,
    [string]$EsriStorageAccount,
    [string]$EsriStorageAccountContainer,
    [string]$Fqdn,
    [string]$KeyVaultName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$StorageEndpoint,
    [string]$Subscription,
    [string]$UserAssignedIdentityClientId,
    [string]$UserAssignedIdentityObjectId
)

Import-Module az.keyvault
Connect-AzAccount -Environment $Environment -Subscription $Subscription -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
$ctx = New-AzStorageContext -StorageAccountName $esriStorageAccount -UseConnectedAccount
$StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint
$TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
$AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
$BlobNames = @($certificateFileName)
Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl/$ContainerName/$BlobNames" -OutFile $env:windir\temp\$certificateFileName -Verbose
$pfx = "$env:windir\temp\$CertificateFileName"
Set-AzStorageBlobContent -File $pfx -Container $esriStorageAccountContainer -Blob $CertificateFileName -Context $ctx -Force
[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($pfx))
$Password = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force
Import-AzKeyVaultCertificate -VaultName $keyVaultName -Name "pfx$location" -FilePath $pfx -Password $Password
$azKeyVaultCert = Get-AzKeyVaultCertificate -VaultName  $keyVaultName -Name "pfx$location"
$azKeyVaultCertBytes = $azKeyVaultCert.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
$publicCertificateName = "wildcard$fqdn-PublicKey.cer"
$cerCertFile = "$env:windir\temp\$publicCertificateName"
[System.IO.File]::WriteAllBytes($cerCertFile, $azKeyVaultCertBytes)
Set-AzStorageBlobContent -File $cerCertFile -Container $esriStorageAccountContainer -Blob $publicCertificateName -Context $ctx -Force