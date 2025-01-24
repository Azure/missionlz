$keyVaultName = "<ReplaceWithYourKeyVaultName>" # Replace with your Azure Key Vault name
$certificateName = "testcert" # Replace with your desired certificate name
$certificatePassword = "Password123" # Replace with a strong password
$location = "westus3" # Replace with the Azure region of your Key Vault
$certFilePath = "C:\Users\example\OneDrive - Microsoft\Code\$certificateName.pfx" # Path to store the local certificate file


# Login to Azure (if not already logged in)
Install-Module -Name Az -AllowClobber -Force 
Import-Module Az
Connect-AzAccount

# Ensure you have the required modules
Install-Module -Name Az.KeyVault -Force -AllowClobber

# Create a wildcard self-signed certificate
Write-Host "Creating wildcard self-signed certificate..."
$cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" `
    -DnsName "*.poc.local" `
    -FriendlyName "$certificateName" `
    -NotAfter (Get-Date).AddYears(1)
Write-Host "Wildcard self-signed certificate created."

# Export the certificate to a .pfx file
Write-Host "Exporting certificate to .pfx file..."
Export-PfxCertificate -Cert $cert -FilePath $certFilePath -Password (ConvertTo-SecureString -String $certificatePassword -Force -AsPlainText)
Write-Host "Certificate exported to $certFilePath."

# Retrieve the Key Vault
Write-Host "Retrieving Key Vault..."
$keyVault = Get-AzKeyVault -VaultName $keyVaultName
Write-Host "Key Vault retrieved."

# Read the certificate content
Write-Host "Reading certificate content..."
$certContentBytes = [System.IO.File]::ReadAllBytes($certFilePath)
$certContentBase64 = [System.Convert]::ToBase64String($certContentBytes)
Write-Host "Certificate content read."

# Create the certificate policy
Write-Host "Creating certificate policy..."
$keyVaultCertPolicy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -ValidityInMonths 12 -IssuerName "Self" -SubjectName "CN=$($certificateName)"
Write-Host "Certificate policy created."

# Add the certificate to Azure Key Vault
Write-Host "Adding certificate to Azure Key Vault..."
try {
    Import-AzKeyVaultCertificate -VaultName $keyVaultName -Name $certificateName -FilePath $certFilePath -Password (ConvertTo-SecureString -String $certificatePassword -Force -AsPlainText)
    Write-Host "Certificate '$certificateName' created and uploaded to Azure Key Vault '$keyVaultName' successfully."
} catch {
    Write-Error "Failed to add certificate to Azure Key Vault: $_"
    return
}

# Clean up local certificate file (optional)
Write-Host "Cleaning up local certificate file..."
Remove-Item -Path $certFilePath -Force
Write-Host "Local certificate file cleaned up."