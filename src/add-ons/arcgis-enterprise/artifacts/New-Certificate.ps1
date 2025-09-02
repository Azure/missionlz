param(
    [string] $KeyVaultName,
    [string] $Location
)

$CertificateName = "EsriEnterpriseCertificate"
$CertificatePassword = (New-Guid).Guid
$CertificateFilePath = "C:\$CertificateName.pfx"

# Create a wildcard self-signed certificate
$Certificate = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" `
    -DnsName "*.poc.local" `
    -FriendlyName "$CertificateName" `
    -NotAfter (Get-Date).AddYears(1)

# Export the certificate to a .pfx file
Export-PfxCertificate -Cert $Certificate -FilePath $CertificateFilePath -Password (ConvertTo-SecureString -String $CertificatePassword -Force -AsPlainText)

# Add the certificate to Azure Key Vault
Import-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName -FilePath $CertificateFilePath -Password (ConvertTo-SecureString -String $CertificatePassword -Force -AsPlainText)

# Clean up local certificate file
Remove-Item -Path $CertificateFilePath -Force