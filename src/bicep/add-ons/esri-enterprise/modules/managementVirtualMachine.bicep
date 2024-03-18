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
  tags: contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}
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
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
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
  dependsOn: [
  ]
}

resource modules 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'rc-azModules'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
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
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityPrincipalId
      }
    ]
    source: {
      script: '''
        param(
          [string]$ContainerName,
          [string]$StorageAccountName,
          [string]$StorageEndpoint,
          [string]$UserAssignedIdentityObjectId
        )
        $ErrorActionPreference = "Stop"
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        $BlobNames = @('az.accounts.2.13.1.nupkg','az.automation.1.9.0.nupkg','az.compute.5.7.0.nupkg','az.resources.6.6.0.nupkg','az.keyvault.4.12.0.nupkg', 'az.storage.5.1.0.nupkg', 'az.marketplaceordering.2.0.0.nupkg')
        foreach($BlobName in $BlobNames)
        {
          do
          {
              try
              {
                  Write-Output "Download Attempt $i"
                  Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile "$env:windir\temp\$BlobName"
              }
              catch [System.Net.WebException]
              {
                  Start-Sleep -Seconds 60
                  $i++
                  if($i -gt 10){throw}
                  continue
              }
              catch
              {
                  $Output = $_ | select *
                  Write-Output $Output
                  throw
              }
          }
          until(Test-Path -Path $env:windir\temp\$BlobName)
          Start-Sleep -Seconds 5
          Unblock-File -Path $env:windir\temp\$BlobName
          $BlobZipName = $Blobname.Replace('nupkg','zip')
          Rename-Item -Path $env:windir\temp\$BlobName -NewName $BlobZipName
          $BlobNameArray = $BlobName.Split('.')
          $ModuleFolderName = $BlobNameArray[0] + '.' + $BlobNameArray[1]
          $VersionFolderName = $BlobNameArray[2] + '.' + $BlobNameArray[3]+ '.' + $BlobNameArray[4]
          $ModulesDirectory = "C:\Program Files\WindowsPowerShell\Modules"
          New-Item -Path $ModulesDirectory -Name $ModuleFolderName -ItemType "Directory" -Force
          Expand-Archive -Path $env:windir\temp\$BlobZipName -DestinationPath "$ModulesDirectory\$ModuleFolderName\$VersionFolderName" -Force
          Remove-Item -Path "$ModulesDirectory\$ModuleFolderName\$VersionFolderName\_rels" -Force -Recurse
          Remove-Item -Path "$ModulesDirectory\$ModuleFolderName\$VersionFolderName\package" -Force -Recurse
          Remove-Item -LiteralPath "$ModulesDirectory\$ModuleFolderName\$VersionFolderName\[Content_Types].xml" -Force
          Remove-Item -Path "$ModulesDirectory\$ModuleFolderName\$VersionFolderName\$ModuleFolderName.nuspec" -Force
        }
        Remove-Item -Path "$env:windir\temp\az*" -Force
      '''
    }
  }
  dependsOn: [
  ]
}

resource esriArtifacts 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'rc-esriScriptArtifacts'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
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
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'StorageAccountName'
        value: esriStorageAccount.name
      }
      {
        name: 'StorageEndpoint'
        value: environment().suffixes.storage
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
        name: 'location'
        value: location
      }
      {
        name: 'subscription'
        value: subscription().subscriptionId
      }
    ]
    source: {
      script: '''
      param(
        [string]$ContainerName,
        [string]$certificatePassword,
        [string]$environment,
        [string]$StorageAccountName,
        [string]$UserAssignedIdentityObjectId,
        [string]$UserAssignedIdentityClientId,
        [string]$location,
        [string]$fqdn,
        [string]$subscription
      )
      $ErrorActionPreference = 'Stop'
      Connect-AzAccount -Environment $Environment -Subscription $subscription -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
      Invoke-WebRequest https://github.com/Esri/arcgis-azure-templates/raw/main/Releases/11.1/DSC.zip -OutFile ./DSC.zip
      Invoke-WebRequest https://github.com/Esri/arcgis-azure-templates/raw/main/Releases/11.1/GenerateSSLCerts.ps1 -OutFile ./GenerateSSLCerts.ps1
      $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
      Set-AzStorageBlobContent -File ./DSC.zip -Container $containerName -Blob DSC.zip -Context $ctx -Force
      Set-AzStorageBlobContent -File ./GenerateSSLCerts.ps1 -Container $containerName -Blob GenerateSSLCerts.ps1 -Context $ctx -Force
      '''
    }
  }
  dependsOn: [
    modules
    storageAccount
  ]
}

resource artifacts 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'rc-licenseAndCertificateArtifacts'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
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
    ]
    source: {
      script: '''
      param(
        [string]$ContainerName,
        [string]$CertificateFileName,
        [string]$CertificatePassword,
        [string]$StorageAccountName,
        [string]$StorageEndpoint,
        [string]$UserAssignedIdentityObjectId,
        [string]$UserAssignedIdentityClientId,
        [string]$PortalLicenseFileName,
        [string]$PortalLicenseFile,
        [string]$ServerLicensefile,
        [string]$ServerLicenseFileName,
        [string]$TenantId,
        [string]$Location,
        [string]$Fqdn,
        [string]$Subscription,
        [string]$KeyVaultName,
        [string]$EsriStorageAccount,
        [string]$Environment
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
      Set-AzStorageBlobContent -File $pfx -Container $containerName -Blob $CertificateFileName -Context $ctx -Force
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
      Set-AzStorageBlobContent -File $cerCertFile -Container $containerName -Blob $publicCertificateName -Context $ctx -Force
      #Set-AzStorageBlobContent -File $pfx -Container $containerName -Blob $CertificateFileName -Context $ctx -Force
      Set-AzStorageBlobContent -File $plf -Container $containerName -Properties @{"ContentEncoding" = "UTF-8"} -Blob $portalLicenseFileName -Context $ctx -Force
      Set-AzStorageBlobContent -File $slf -Container $containerName -Properties @{"ContentEncoding" = "UTF-8"} -Blob $serverLicenseFileName -Context $ctx -Force
      '''
    }
  }
  dependsOn: [
    modules
    esriArtifacts
    storageAccount
  ]
}

resource esriMarketplaceImageTerms 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'rc-esriMarketplaceImageTerms'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
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
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'StorageAccountName'
        value: esriStorageAccount.name
      }
      {
        name: 'StorageEndpoint'
        value: environment().suffixes.storage
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
        name: 'location'
        value: location
      }
      {
        name: 'subscription'
        value: subscription().subscriptionId
      }
    ]
    source: {
      script: '''
      param(
        [string]$Environment,
        [string]$UserAssignedIdentityObjectId,
        [string]$UserAssignedIdentityClientId,
        [string]$subscription
      )
      $ErrorActionPreference = 'Stop'
      Connect-AzAccount -Environment $Environment -Subscription $subscription -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
      $name = 'byol-111'
      $product = 'arcgis-enterprise'
      $publisher = 'esri'
      Get-AzMarketplaceTerms -Publisher $publisher -Name $name -Product $product -OfferType 'virtualmachine' | Set-AzMarketplaceTerms -Accept
      '''
    }
  }
  dependsOn: [
    modules
    storageAccount
  ]
}

output name string = virtualMachine.name
