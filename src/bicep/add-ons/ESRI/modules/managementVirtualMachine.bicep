param containerName string
param diskEncryptionSetResourceId string
param hybridUseBenefit bool
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
param storageAccountName string
param subnetResourceId string
param tags object
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param virtualMachineName string
param portalLicenseFile string
param portalLicenseFileName string
param serverLicenseFile string
param serverLicenseFileName string

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'nic-${virtualMachineName}'
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
        sku: '2019-datacenter-core-g2'
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
        name: 'disk-${virtualMachineName}'
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

resource modules 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'appAzModules'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
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
        $BlobNames = @('az.accounts.2.12.1.nupkg','az.automation.1.9.0.nupkg','az.compute.5.7.0.nupkg','az.resources.6.6.0.nupkg','az.keyvault.4.12.0.nupkg', 'az.storage.5.1.0.nupkg')
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
}


resource artifacts 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'artifacts'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
      }
      {
        name: 'StorageEndpoint'
        value: environment().suffixes.storage
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
        name: 'TenantId'
        value: subscription().tenantId
      }
    ]
    source: {
      script: '''
        param(
          [string]$ContainerName,
          [string]$StorageAccountName,
          [string]$StorageEndpoint,
          [string]$UserAssignedIdentityObjectId,
          [string]$PortalLicenseFileName,
          [string]$ServerLicensefile,
          [string]$ServerLicenseFileName,
          [string]$TenantId
        )
        $ErrorActionPreference = 'Stop'
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
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
    }
  }
  dependsOn: [
    modules
  ]
}
output name string = virtualMachine.name
