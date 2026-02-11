param artifactsContainerName string
param diskEncryptionSetResourceId string
param hybridUseBenefit bool
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
param artifactsStorageAccountName string
param subnetResourceId string
param tags object
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param virtualMachineName string
param portalLicenseFile string
param portalLicenseFileName string
param serverLicenseFile string
param serverLicenseFileName string
param keyVaultName string
@secure()
param certificatePassword string
param certificateFileName string
param externalDnsHostname string
param esriStorageAccountName string
param esriStorageAccountContainer string
param resourcePrefix string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: artifactsStorageAccountName
}

resource esriStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: esriStorageAccountName
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${resourcePrefix}-nic-${virtualMachineName}'
  location: location
  tags: tags[?'Microsoft.Network/networkInterfaces'] ?? {}
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachineName
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: localAdministratorUsername
      adminPassword: localAdministratorPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-core-g2'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: 'Premium_LRS'
        }
        name: '${resourcePrefix}-disk-${virtualMachineName}'
        osType: 'Windows'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    securityProfile: {
      encryptionAtHost: true
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    licenseType: hybridUseBenefit ? 'Windows_Server' : null
  }
}

resource artifacts 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'rc-licenseAndCertificateArtifacts'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ContainerName'
        value: artifactsContainerName
      }
      {
        name: 'StorageAccountName'
        value: storageAccount.name
      }
      {
        name: 'StorageEndpoint'
        value: environment().suffixes.storage
      }
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityPrincipalId
      }
      {
        name: 'PortalLicensefile'
        value: portalLicenseFile
      }
      {
        name: 'PortalLicenseFileName'
        value: portalLicenseFileName
      }
      {
        name: 'ServerLicensefile'
        value: serverLicenseFile
      }
      {
        name: 'ServerLicenseFileName'
        value: serverLicenseFileName
      }
      {
        name: 'location'
        value: location
      }
      {
        name: 'fqdn'
        value: externalDnsHostname
      }
      {
        name: 'keyVault'
        value: keyVaultName
      }
      {
        name: 'certificateFileName'
        value: certificateFileName
      }
      {
        name: 'certificatePassword'
        value: certificatePassword
      }
      {
        name: 'subscription'
        value: subscription().subscriptionId
      }
      {
        name: 'EsriStorageAccount'
        value: esriStorageAccount.name
      }
      {
        name: 'esriStorageAccountContainer'
        value: esriStorageAccountContainer
      }
    ]
    source: {
      script: '''
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
        [string]$PortalLicenseFile,
        [string]$PortalLicenseFileName,
        [string]$ServerLicensefile,
        [string]$ServerLicenseFileName,
        [string]$StorageAccountName,
        [string]$StorageEndpoint,
        [string]$Subscription,
        [string]$TenantId,
        [string]$UserAssignedIdentityClientId,
        [string]$UserAssignedIdentityObjectId
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
      $base64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($pfx))
      $Password = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force
      $cert = Import-AzKeyVaultCertificate -VaultName $keyVaultName -Name "pfx$location" -FilePath $pfx -Password $Password
      $azKeyVaultCert = Get-AzKeyVaultCertificate -VaultName  $keyVaultName -Name "pfx$location"
      $azKeyVaultCertBytes = $azKeyVaultCert.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
      $publicCertificateName = "wildcard$fqdn-PublicKey.cer"
      $cerCertFile = "$env:windir\temp\$publicCertificateName"
      Write-Output $cerCertFile
      [System.IO.File]::WriteAllBytes($cerCertFile, $azKeyVaultCertBytes)
      #$ctx = New-AzStorageContext -StorageAccountName $esriStorageAccount -UseConnectedAccount
      Set-AzStorageBlobContent -File $cerCertFile -Container $esriStorageAccountContainer -Blob $publicCertificateName -Context $ctx -Force
      #Set-AzStorageBlobContent -File $pfx -Container $esriStorageAccountContainer -Blob $CertificateFileName -Context $ctx -Force
      Set-AzStorageBlobContent -File $plf -Container $esriStorageAccountContainer -Properties @{"ContentEncoding" = "UTF-8"} -Blob $portalLicenseFileName -Context $ctx -Force
      Set-AzStorageBlobContent -File $slf -Container $esriStorageAccountContainer -Properties @{"ContentEncoding" = "UTF-8"} -Blob $serverLicenseFileName -Context $ctx -Force
      '''
    }
  }
  dependsOn: [
    storageAccount
  ]
}

resource esriMarketplaceImageTerms 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'rc-esriMarketplaceImageTerms'
  location: location
  tags: tags[?'Microsoft.Compute/virtualMachines'] ?? {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ImageOffer'
        value: 'arcgis-enterprise'
      }
      {
        name: 'ImagePublisher'
        value: 'esri'
      }
      
      {
        name: 'ImageSku'
        value: 'byol-111'
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
    ]
    source: {
      script: loadTextContent('../artifacts/Set-AzureMarketplaceTerms.ps1')
    }
  }
  dependsOn: [
    storageAccount
  ]
}

output name string = virtualMachine.name
