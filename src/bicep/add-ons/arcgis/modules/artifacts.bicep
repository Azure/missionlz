param containerName string
param identityId string
// param keyVaultName string
param location string
param portalLicenseFile string
param portalLicenseFileName string
param serverLicenseFile string
param serverLicenseFileName string
param storageAccountName string
// param tags object
param utcValue string = utcNow()

// var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource licenseFiles 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'licenseFiles'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  kind: 'AzurePowerShell'
  properties: {
  arguments: '-Location ${location} -portalLicensefile ${portalLicenseFile} -portalLicenseFileName ${portalLicenseFileName} -serverLicenseFileName ${serverLicenseFileName} -serverLicensefile ${serverLicenseFile} -StorageAccountName ${storageAccount.name} -ContainerName ${containerName} -utcValue ${utcValue}'
  environmentVariables:[
  ]
  containerSettings:{
  }
    forceUpdateTag: utcValue
    azPowerShellVersion: '8.3'
    timeout: 'PT30M'
    scriptContent: '''
        param(
        [string]$ContainerName,
        [string]$PortalLicensefile,
        [string]$PortalLicenseFileName,
        [string]$ServerLicensefile,
        [string]$ServerLicenseFileName,
        [string]$StorageAccountName
      )
      New-Item -ItemType File $portalLicenseFileName
      New-Item -ItemType File $serverLicenseFileName
      $plf = "/mnt/azscripts/azscriptinput/$portalLicenseFileName"
      $slf = "/mnt/azscripts/azscriptinput/$serverLicenseFileName"
      $portalLicense = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($portalLicensefile))
      $portalLicense | Out-File $plf
      $serverLicense = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($serverLicensefile))
      $serverLicense | Out-File $slf
      # upload blobs to container using managed identity assigned to deployment script
      $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
      Set-AzStorageBlobContent -File $plf -Container $containerName -Blob $portalLicenseFileName -Context $ctx -Force
      Set-AzStorageBlobContent -File $slf -Container $containerName -Blob $serverLicenseFileName -Context $ctx -Force
    '''
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
  ]
}

// // REWRITE THIS TO USE THE CERTIFICATE FROM THE KEY VAULT
// resource certificate 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'createAddCertificate'
//   location: location
//   tags: contains(tags, 'Microsoft.Resources/deploymentScripts') ? tags['Microsoft.Resources/deploymentScripts'] : {}
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${identityId}': {}
//     }
//   }
//   kind: 'AzurePowerShell'
//   properties: {
//   arguments: '-Location ${location} -KeyVaultName ${keyVaultName} -StorageAccountName ${storageAccount.name} -ContainerName ${containerName} -CloudSuffix ${cloudSuffix} -utcValue ${utcValue}'
//   environmentVariables:[
//   ]
//   containerSettings:{
//   }
//     forceUpdateTag: utcValue
//     azPowerShellVersion: '8.3'
//     timeout: 'PT30M'
//     scriptContent: '''
//         param(
//         [string]$ContainerName,
//         [string]$KeyVaultName,
//         [string]$Location,
//         [string]$StorageAccountName,
//         [string]$CloudSuffix
//       )
//       # download required files from ESRI github repo
//       Invoke-WebRequest https://github.com/Esri/arcgis-azure-templates/raw/main/Releases/11.1/DSC.zip -OutFile ./DSC.zip
//       Invoke-WebRequest https://github.com/Esri/arcgis-azure-templates/raw/main/Releases/11.1/GenerateSSLCerts.ps1 -OutFile ./GenerateSSLCerts.ps1
//       #Invoke-WebRequest https://github.com/Esri/arcgis-azure-templates/raw/main/SelfSignedCertificates/wildcard.${location}.cloudapp.usgovcloudapi.net.pfx -OutFile ./wildcard.usgovvirginia.cloudapp.usgovcloudapi.net.pfx
//       Invoke-WebRequest https://github.com/mikedzikowski/testcert/raw/main/wildcard_mikedzikowski_com.pfx -OutFile ./wildcard_mikedzikowski_com.pfx

//       # import self-signed certificate into key vault
//       $file = "wildcard_mikedzikowski_com.pfx"
//       $password = ConvertTo-SecureString -String "miked123" -AsPlainText -Force
//       $cert = Get-Content ./wildcard_mikedzikowski_com.pfx -AsByteStream
//       $base64String = ([System.Convert]::ToBase64String($Cert))
//       Import-AzKeyVaultCertificate -VaultName $keyVaultName -FilePath ./wildcard_mikedzikowski_com.pfx -Name "pfx$location" -Password $password
//       Start-Sleep 10
//       # export Azure Key Vault certificate to .cer file
//       $azKeyVaultCert = Get-AzKeyVaultCertificate -VaultName $keyVaultName -Name "pfx$location"
//       Write-Output $azKeyVaultCert
//       $azKeyVaultCertBytes = $azKeyVaultCert.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
//       Write-Output $azKeyVaultCertBytes
//       $certificateName = "wildcardesri.mikedzikowski.com-PublicKey.cer"
//       Write-Output $certificateName
//       $cerCertFile = "/mnt/azscripts/azscriptinput/$certificateName"
//       Write-Output $cerCertFile
//       [System.IO.File]::WriteAllBytes($cerCertFile, $azKeyVaultCertBytes)
//       if((Test-Path -Path $cerCertFile) -eq $true)
//       {
//           Write-Host "Exported certificate to file - $certificateName"
//       }
//       else {
//           Write-Host "Public key was not exported"
//       }
//       # upload blobs to container using managed identity assigned to deployment script
//       $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
//       Set-AzStorageBlobContent -File $certificateName -Container $containerName -Blob $certificateName -Context $ctx -Force
//       Set-AzStorageBlobContent -File ./DSC.zip -Container $containerName -Blob DSC.zip -Context $ctx -Force
//       Set-AzStorageBlobContent -File ./wildcard_mikedzikowski_com.pfx -Container $containerName -Blob "wildcard_mikedzikowski_com.pfx" -Context $ctx -Force
//       Set-AzStorageBlobContent -File ./GenerateSSLCerts.ps1 -Container $containerName -Blob GenerateSSLCerts.ps1 -Context $ctx -Force
//       $DeploymentScriptOutputs = @{}
//       $DeploymentScriptOutputs['text'] = $Base64String
//     '''
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
//   dependsOn: [
//   ]
// }

output frontendCertificate string = certificate.properties.outputs.text
