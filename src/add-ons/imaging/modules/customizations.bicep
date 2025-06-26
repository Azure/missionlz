/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'resourceGroup'

param arcGisProInstaller string
param containerName string
param customizations array
param installAccess bool
param installArcGisPro bool
param installExcel bool
param installOneDrive bool
param installOneNote bool
param installOutlook bool
param installPowerPoint bool
param installProject bool
param installPublisher bool
param installSkypeForBusiness bool
param installTeams bool
param installVirtualDesktopOptimizationTool bool
param installVisio bool
param installWord bool
param location string
param mlzTags object
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param storageAccountName string
param storageEndpoint string
param tags object
param teamsInstaller string
param userAssignedIdentityObjectId string
param vcRedistInstaller string
param vDotInstaller string
param virtualMachineName string

var installAccessVar = '${installAccess}installAccess'
var installers = customizations
var installExcelVar = '${installExcel}installExcel'
var installOneDriveVar = '${installOneDrive}installOneDrive'
var installOneNoteVar = '${installOneNote}installOneNote'
var installOutlookVar = '${installOutlook}installOutlook'
var installPowerPointVar = '${installPowerPoint}installPowerPoint'
var installProjectVar = '${installProject}installProject'
var installPublisherVar = '${installPublisher}installPublisher'
var installSkypeForBusinessVar = '${installSkypeForBusiness}installSkypeForBusiness'
var installVisioVar = '${installVisio}installVisio'
var installWordVar = '${installWord}installWord'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: virtualMachineName
}

@batchSize(1)
resource applications 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [
  for installer in installers: if (installer.enabled) {
    parent: virtualMachine
    name: 'app-${installer.name}'
    location: location
    tags: union(
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    properties: {
      treatFailureAsDeploymentFailure: true
      asyncExecution: false
      parameters: [
        {
          name: 'UserAssignedIdentityObjectId'
          value: userAssignedIdentityObjectId
        }
        {
          name: 'StorageAccountName'
          value: storageAccountName
        }
        {
          name: 'ContainerName'
          value: containerName
        }
        {
          name: 'StorageEndpoint'
          value: storageEndpoint
        }
        {
          name: 'Blobname'
          value: installer.blobName
        }
        {
          name: 'Installer'
          value: installer.name
        }
        {
          name: 'Arguments'
          value: installer.arguments
        }
      ]
      source: {
        script: '''
        param(
          [string]$UserAssignedIdentityObjectId,
          [string]$StorageAccountName,
          [string]$ContainerName,
          [string]$StorageEndpoint,
          [string]$BlobName,
          [string]$Installer,
          [string]$Arguments
        )
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        $BlobFileName = $BlobName.Split("/")[-1]
        New-Item -Path $env:windir\temp -Name $Installer -ItemType "directory" -Force
        $InstallerDirectory = "$env:windir\temp\$Installer"
        Write-Host "Setting file copy to install directory: $InstallerDirectory"
        Set-Location -Path $InstallerDirectory
        Write-Host "Invoking WebClient download for file : $BlobFileName"
        #Invoking WebClient to download blobs because it is more efficient than Invoke-WebRequest for large files.
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add('x-ms-version', '2017-11-09')
        $webClient.Headers.Add("Authorization", "Bearer $AccessToken")
        $webClient.DownloadFile("$StorageAccountUrl$ContainerName/$BlobName", "$InstallerDirectory\$BlobName")
        Start-Sleep -Seconds 30
        $Path = (Get-ChildItem -Path "$InstallerDirectory\$BlobName" -Recurse | Where-Object {$_.Name -eq "$BlobName"}).FullName
        if($BlobName -like ("*.exe"))
        {
          Start-Process -FilePath $InstallerDirectory\$BlobName -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
          $wmistatus = Get-WmiObject -Class Win32_Product | Where-Object Name -like "*$($Installer)*"
          if($wmistatus)
          {
            Write-Host $wmistatus.Name "is installed"
          }
          $regstatus = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -like "*$($Installer)*" }
          if($regstatus)
          {
            Write-Host $regstatus.DisplayName "is installed"
          }
          $regstatusWow6432 = Get-ItemProperty 'HKLM:\Software\WOW6432Node\*' | Where-Object { $_.PSChildName -like "*$($Installer)*" }
          if($regstatusWow6432)
          {
            Write-Host $regstatusWow6432.PSChildName "is installed"
          }
          else
          {
            Write-host $Installer "did not install properly, please check arguments"
          }
        }
        if($BlobName -like ("*.msi"))
        {
          Write-Host "Invoking msiexec.exe for install path : $Path"
          Start-Process -FilePath msiexec.exe -ArgumentList "/i $Path $Arguments" -Wait
          $status = Get-WmiObject -Class Win32_Product | Where-Object Name -like "*$($installer)*"
          if($status)
          {
            Write-Host $status.Name "is installed"
          }
          else
          {
            Write-host $Installer "did not install properly, please check arguments"
          }
        }
        if($BlobName -like ("*.bat"))
        {
          Start-Process -FilePath cmd.exe -ArgumentList $InstallerDirectory\$Arguments -Wait
        }
        if($BlobName -like ("*.ps1"))
        {
          if($BlobName -like ("Install-BundleSoftware.ps1"))
          {
            Start-Process -FilePath PowerShell.exe -ArgumentList "-File $Path -UserAssignedIdentityObjectId $UserAssignedIdentityObjectId -StorageAccountName $StorageAccountName -ContainerName $ContainerName -StorageEndpoint $StorageEndpoint $Arguments" -Wait
          }
          else
          {
            Start-Process -FilePath PowerShell.exe -ArgumentList "-File $Path $Arguments" -Wait
          }
        }
        if($BlobName -like ("*.zip"))
        {
          Expand-Archive -Path $InstallerDirectory\$BlobName -DestinationPath $InstallerDirectory -Force
          Remove-Item -Path .\$BlobName -Force -Recurse
        }
        Write-Host "Removing $Installer Files"
        #Start-Sleep -Seconds 5
        Remove-item $env:windir\temp\$Installer -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
       '''
      }
    }
  }
]

resource office 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' =
  if (installAccess || installExcel || installOneDrive || installOneNote || installOutlook || installPowerPoint || installPublisher || installSkypeForBusiness || installWord || installVisio || installProject) {
    parent: virtualMachine
    name: 'office'
    location: location
    tags: union(
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    properties: {
      treatFailureAsDeploymentFailure: true
      asyncExecution: false
      parameters: [
        {
          name: 'InstallAccess'
          value: installAccessVar
        }
        {
          name: 'InstallWord'
          value: installWordVar
        }
        {
          name: 'InstallExcel'
          value: installExcelVar
        }
        {
          name: 'InstallOneDrive'
          value: installOneDriveVar
        }
        {
          name: 'InstallOneNote'
          value: installOneNoteVar
        }
        {
          name: 'InstallOutlook'
          value: installOutlookVar
        }
        {
          name: 'InstallPowerPoint'
          value: installPowerPointVar
        }
        {
          name: 'InstallProject'
          value: installProjectVar
        }
        {
          name: 'InstallPublisher'
          value: installPublisherVar
        }
        {
          name: 'InstallSkypeForBusiness'
          value: installSkypeForBusinessVar
        }
        {
          name: 'InstallVisio'
          value: installVisioVar
        }
        {
          name: 'UserAssignedIdentityObjectId'
          value: userAssignedIdentityObjectId
        }
        {
          name: 'StorageAccountName'
          value: storageAccountName
        }
        {
          name: 'ContainerName'
          value: containerName
        }
        {
          name: 'StorageEndpoint'
          value: storageEndpoint
        }
        {
          name: 'BlobName'
          value: officeInstaller
        }
      ]
      source: {
        script: '''
      param(
        [string]$InstallAccess,
        [string]$InstallExcel,
        [string]$InstallOneDrive,
        [string]$InstallOutlook,
        [string]$InstallProject,
        [string]$InstallPublisher,
        [string]$InstallSkypeForBusiness,
        [string]$InstallVisio,
        [string]$InstallWord,
        [string]$InstallOneNote,
        [string]$InstallPowerPoint,
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName
      )
      $ErrorActionPreference = 'Stop'
      $WarningPreference = 'SilentlyContinue'
      $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
      $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
      $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
      New-Item -Path "$env:windir\temp\office" -ItemType "directory" -Force
      $sku = (Get-ComputerInfo).OsName
      $o365ConfigHeader = Set-Content "$env:windir\temp\office\office365x64.xml" '<Configuration><Add OfficeClientEdition="64" Channel="Current">'
      $o365OfficeHeader = Add-Content "$env:windir\temp\office\office365x64.xml" '<Product ID="O365ProPlusRetail"><Language ID="en-us" /><ExcludeApp ID="Teams"/>'
      if($InstallAccess -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="Access" />'
      }
      if($InstallExcel -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="Excel" />'
      }
      if($InstallOneDrive -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="OneDrive" />'
      }
      if($InstallOneNote -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="OneNote" />'
      }
      if($InstallOutlook -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="Outlook" />'
      }
      if($InstallPowerPoint -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="PowerPoint" />'
      }
      if($InstallPublisher -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="Publisher" />'
      }
      if($InstallSkypeForBusiness -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="Lync" />'
      }
      if($InstallWord -notlike '*true*'){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<ExcludeApp ID="Word" />'
      }
      $addOfficefooter = Add-Content "$env:windir\temp\office\office365x64.xml" '</Product>'
      if($InstallProject -like '*true*'){
        Add-Content "$env:windir\temp\office\office365x64.xml" '<Product ID="ProjectProRetail"><Language ID="en-us" /></Product>'
      }
      if($InstallVisio -like '*true*'){
        Add-Content "$env:windir\temp\office\office365x64.xml" '<Product ID="VisioProRetail"><Language ID="en-us" /></Product>'
      }
      Add-Content "$env:windir\temp\office\office365x64.xml" '</Add><Updates Enabled="FALSE" /><Display Level="None" AcceptEULA="TRUE" /><Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>'
      $PerMachineConfiguration = if(($Sku).Contains("multi") -eq "true"){
          Add-Content "$env:windir\temp\office\office365x64.xml" '<Property Name="SharedComputerLicensing" Value="1"/>'
      }
      Add-Content "$env:windir\temp\office\office365x64.xml" '</Configuration>'
      $Installer = "$env:windir\temp\office\office.exe"
      #$DownloadLinks = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117" -UseBasicParsing
      #$URL = $DownloadLinks.Links.href | Where-Object {$_ -like "https://download.microsoft.com/download/*officedeploymenttool*"} | Select-Object -First 1
      #Invoke-WebRequest -Uri $URL -OutFile $Installer -UseBasicParsing
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $Installer
      Start-Process -FilePath $Installer -ArgumentList "/extract:$env:windir\temp\office /quiet /passive /norestart" -Wait -PassThru | Out-Null
      Write-Host "Downloaded & extracted the Office 365 Deployment Toolkit"
      Start-Process -FilePath "$env:windir\temp\office\setup.exe" -ArgumentList "/configure $env:windir\temp\office\office365x64.xml" -Wait -PassThru -ErrorAction "Stop" | Out-Null
      Write-Host "Installed the selected Office365 applications"
      Write-Host "Removing Office FIles"
      Remove-item -Path  "$env:windir\temp\office" -Force -Confirm:$false -Recurse
      '''
      }
    }
    dependsOn: [
      applications
    ]
  }

resource vdot 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' =
  if (installVirtualDesktopOptimizationTool) {
    parent: virtualMachine
    name: 'vdot'
    location: location
    tags: union(
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    properties: {
      treatFailureAsDeploymentFailure: true
      asyncExecution: false
      parameters: [
        {
          name: 'UserAssignedIdentityObjectId'
          value: userAssignedIdentityObjectId
        }
        {
          name: 'StorageAccountName'
          value: storageAccountName
        }
        {
          name: 'ContainerName'
          value: containerName
        }
        {
          name: 'StorageEndpoint'
          value: storageEndpoint
        }
        {
          name: 'BlobName'
          value: vDotInstaller
        }
      ]
      source: {
        script: '''
        param(
          [string]$UserAssignedIdentityObjectId,
          [string]$StorageAccountName,
          [string]$ContainerName,
          [string]$StorageEndpoint,
          [string]$BlobName
        )
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        $ZIP = "$env:windir\temp\VDOT.zip"
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $ZIP
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp
        Unblock-File -Path $ZIP
        Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp" -Force
        $Path = (Get-ChildItem -Path "$env:windir\temp" -Recurse | Where-Object {$_.Name -eq "Windows_VDOT.ps1"}).FullName
        $Script = Get-Content -Path $Path
        $ScriptUpdate = $Script.Replace("Set-NetAdapterAdvancedProperty","#Set-NetAdapterAdvancedProperty")
        $ScriptUpdate | Set-Content -Path $Path
        & $Path -Optimizations @("AppxPackages","Autologgers","DefaultUserSettings","LGPO";"NetworkOptimizations","ScheduledTasks","Services","WindowsMediaPlayer") -AdvancedOptimizations "All" -AcceptEULA
        Write-Host "Removing VDOT Files"
        # Expecting this format for vDot ZIP, update if using a different ZIP format for folder structure
        Remove-Item -Path $env:windir\temp\Virtual-Desktop-Optimization-Tool-main -Force -Recurse -Confirm:$false
        '''
      }
      timeoutInSeconds: 640
    }
    dependsOn: [
      teams
      applications
      office
    ]
  }

// resource fslogix 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = if (installFsLogix) {
//   parent: virtualMachine
//   name: 'fslogix'
//   location: location
//   tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
//   properties: {
//     treatFailureAsDeploymentFailure: true
//     asyncExecution: false
//     source: {
//       script: '''
//       $ErrorActionPreference = "Stop"
//       $ZIP = "$env:windir\temp\fslogix.zip"
//       Invoke-WebRequest -Uri "https://aka.ms/fslogix_download" -OutFile $ZIP
//       Unblock-File -Path $ZIP
//       Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp\fslogix" -Force
//       Write-Host "Downloaded the latest version of FSLogix"
//       $ErrorActionPreference = "Stop"
//       Start-Process -FilePath "$env:windir\temp\fslogix\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru | Out-Null
//       Write-Host "Installed the latest version of FSLogix"
//       '''
//     }
//     timeoutInSeconds: 640
//   }
//   dependsOn: [
//     applications
//     teams
//     office
//   ]
// }

resource teams 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' =
  if (installTeams) {
    parent: virtualMachine
    name: 'teams'
    location: location
    tags: union(
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    properties: {
      treatFailureAsDeploymentFailure: true
      asyncExecution: false
      parameters: [
        {
          name: 'UserAssignedIdentityObjectId'
          value: userAssignedIdentityObjectId
        }
        {
          name: 'StorageAccountName'
          value: storageAccountName
        }
        {
          name: 'ContainerName'
          value: containerName
        }
        {
          name: 'StorageEndpoint'
          value: storageEndpoint
        }
        {
          name: 'BlobName'
          value: teamsInstaller
        }
        {
          name: 'BlobName2'
          value: vcRedistInstaller
        }
        {
          name: 'BlobName3'
          value: msrdcwebrtcsvcInstaller
        }
      ]
      source: {
        script: '''
      param(
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName,
        [string]$BlobName2,
        [string]$BlobName3
      )
      $ErrorActionPreference = 'Stop'
      $WarningPreference = 'SilentlyContinue'
      $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
      $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
      $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
      $vcRedistFile = "$env:windir\temp\vc_redist.x64.exe"
      $webSocketFile = "$env:windir\temp\webSocketSvc.msi"
      $teamsFile = "$env:windir\temp\teams.msi"
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $teamsFile
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName2" -OutFile $vcRedistFile
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName3" -OutFile  $webSocketFile

      # Enable media optimizations for Team
      Start-Process "reg" -ArgumentList "add HKLM\SOFTWARE\Microsoft\Teams /v IsWVDEnvironment /t REG_DWORD /d 1 /f" -Wait -PassThru -ErrorAction "Stop"
      Write-Host "Enabled media optimizations for Teams"
      # Download & install the latest version of Microsoft Visual C++ Redistributable
      #$File = "$env:windir\temp\vc_redist.x64.exe"
      #Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile $File
      Start-Process -FilePath  $vcRedistFile -Args "/install /quiet /norestart /log vcdist.log" -Wait -PassThru | Out-Null
      Write-Host "Installed the latest version of Microsoft Visual C++ Redistributable"
      # Download & install the Remote Desktop WebRTC Redirector Service
      #$File = "$env:windir\temp\webSocketSvc.msi"
      #Invoke-WebRequest -Uri "https://aka.ms/msrdcwebrtcsvc/msi" -OutFile $File
      Start-Process -FilePath msiexec.exe -Args "/i  $webSocketFile /quiet /qn /norestart /passive /log webSocket.log" -Wait -PassThru | Out-Null
      Write-Host "Installed the Remote Desktop WebRTC Redirector Service"
      # Install Teams
      #$File = "$env:windir\temp\teams.msi"
      #Write-host $($TeamsUrl)
      #Invoke-WebRequest -Uri "$TeamsUrl" -OutFile $File
      $sku = (Get-ComputerInfo).OsName
      $PerMachineConfiguration = if(($Sku).Contains("multi") -eq "true"){"ALLUSER=1"}else{""}
      Start-Process -FilePath msiexec.exe -Args "/i $teamsFile /quiet /qn /norestart /passive /log teams.log $PerMachineConfiguration ALLUSERS=1" -Wait -PassThru | Out-Null
      Write-Host "Installed Teams"
      Write-Host "Removing Teams Files"
      Remove-Item "$teamsFile" -Force -Confirm:$false
      Remove-Item "$vcRedistFile" -Force -Confirm:$false
      Remove-Item "$webSocketFile" -Force -Confirm:$false
      '''
      }
    }
    dependsOn: [
      applications
      office
    ]
  }

resource argGisPro 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' =
  if (installArcGisPro) {
    parent: virtualMachine
    name: 'arcGisPro'
    location: location
    tags: union(
      contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
      mlzTags
    )
    properties: {
      treatFailureAsDeploymentFailure: true
      asyncExecution: false
      parameters: [
        {
          name: 'UserAssignedIdentityObjectId'
          value: userAssignedIdentityObjectId
        }
        {
          name: 'StorageAccountName'
          value: storageAccountName
        }
        {
          name: 'ContainerName'
          value: containerName
        }
        {
          name: 'StorageEndpoint'
          value: storageEndpoint
        }
        {
          name: 'BlobName'
          value: arcGisProInstaller
        }
      ]
      source: {
        script: '''
      param(
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName
      )
      $ErrorActionPreference = 'Stop'
      $WarningPreference = 'SilentlyContinue'
      $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
      $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
      $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
      # Retrieve Files
      New-Item -Path $env:windir\temp -Name arcgis -ItemType "directory" -Force
      $ZIP = "$env:windir\temp\arcgispro.zip"
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $ZIP
      Start-Sleep -Seconds 30
      Set-Location -Path $env:windir\temp
      Unblock-File -Path $ZIP
      Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp\arcgis" -Force

      # Install Arcgis
      $arcGisProMsi = (Get-ChildItem "$env:windir\temp\arcgis\" -Recurse | where {$_.Name -eq "ArcGisPro.msi"})
      $arcGisProMsp = (Get-ChildItem "$env:windir\temp\arcgis" -Recurse | where {$_.Extension -eq ".msp"})
      $winDesktopRuntime = (Get-ChildItem "$env:windir\temp\arcgis\" -Recurse | where {$_.Name -like "windowsdesktop-runtime-*"})

      # If found Install Windows Desktop Runtime Pre-Req
      try {
        if ($winDesktopRuntime ){
            Start-Process -FilePath "$($winDesktopRuntime.Directory.FullName)\$winDesktopRuntime" -ArgumentList "/install /quiet /norestart" -Wait -NoNewWindow -PassThru
        }
      }
      catch {
        Write-Output "Please validate all software requirements are included with the ArcGIS Pro Zip"
      }

      try {
        # Install ArcGis Pro
        $arcGisProArguments = "/i $($arcGisProMsi.Directory.FullName)\$arcGisProMsi ALLUSERS=1 ACCEPTEULA=yes ENABLEEUEI=0 SOFTWARE_CLASS=Professional AUTHORIZATION_TYPE=NAMED_USER LOCK_AUTH_SETTINGS=False ArcGIS_Connection=TRUE /qn /norestart"
        Start-Process "msiexec.exe" -ArgumentList $arcGisProArguments  -Wait -NoNewWindow -PassThru
      }
      catch {
        Write-Output "Please validate all software requirements are included with the ArcGIS Pro Zip"
      }

      try {
      # If MSP is found, patch ArcGisPro with MSP file
      if($arcGisProMsp){
          Start-Process "msiexec.exe" -ArgumentList "/p $($arcGisProMsp.Directory.FullName)\$arcGisProMsp /qn" -Wait -NoNewWindow -PassThru
      }
    }
    catch {
      Write-Output "Please validate all software requirements are included with the ArcGIS Pro Zip"
    }
    Write-Host "Removing ArcGis Files"
    Remove-Item $ZIP -Force -Confirm:$false -Recurse
    Remove-item -Path  "$env:windir\temp\arcgis" -Force -Confirm:$false -Recurse
    '''
      }
    }
    dependsOn: [
      applications
      office
      teams
      vdot
    ]
  }
