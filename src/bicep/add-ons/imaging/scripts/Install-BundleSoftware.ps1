<#
.SYNOPSIS
    This script installs software on an Azure Virtual Machine from a Storage Account.

.DESCRIPTION
    The Install-BundleSoftware function installs specified piece of software from a
    Storage Account. It determines the software installation method by first downloading
    the software installation file name and parameters from the Bundle Manifest json file.

.PARAMETER UserAssignedIdentityObjectId
    Specifies the user Assigned Identity Object Id that is assigned to the virtual machine
    and has access to the storage account.

.PARAMETER StorageAccountName
    Specifies the storage account name where the software installation files are stored.

.PARAMETER ContainerName
    Specifies the container in the storage account where the software installation files
    are stored.

.PARAMETER StorageEndpoint
    Specifies the endpoint for the storage account. This changes depending on which cloud
    the storage account is in. Ex: core.windows.net, core.chinacloudapi.cn, core.cloudapi.de
    core.usgovcloudapi.net, etc.

.PARAMETER BundleManifestBlob
    Specifies the blob name of the Bundle Manifest json file that contains the software
    installation file names and parameters.

.EXAMPLE
    $UserAssignedIdentityObjectId = '00000000-0000-0000-0000-000000000000'
    $StorageAccountName = 'myStorageAccount'
    $ContainerName = 'myContainer'
    $StorageEndpoint = 'core.windows.net'
    $BundleManifestBlob = 'BundleManifest.json'
    Install-BundleSoftware.ps1 -UserAssignedIdentityObjectId $UserAssignedIdentityObjectId
    -StorageAccountName $StorageAccountName -ContainerName $ContainerName -StorageEndpoint
    $StorageEndpoint -BundleManifestBlob $BundleManifestBlob
    
#>

param(
    [string]$UserAssignedIdentityObjectId,
    [string]$StorageAccountName,
    [string]$ContainerName,
    [string]$StorageEndpoint,
    [string]$BundleManifestBlob
  )
  $ErrorActionPreference = 'Stop'
  $WarningPreference = 'SilentlyContinue'
  $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
  $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
  $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
  
  $BundleManifest = "$env:windir\temp\bundlemanifest.json"
  Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName$BundleManifestBlob" -OutFile $BundleManifest
  $Bundle = Get-Content -Raw -Path $BundleManifest | ConvertFrom-Json
  Start-Sleep -Seconds 5
  
  foreach ($item in $Bundle) {
  
    If ($true -eq $item.Enabled) {
        $Installer = $item.name
        $BlobName = $item.blobName
        $Arguments = $item.arguments
        Write-Host "Downloading $Installer from $BlobName"
        $BlobFileName = $BlobName.Split("/")[-1]
        # Special case for VSIX files (.vsix and Install-Vsix scripts)
        if ($BlobFileName -like ("*.vsix") -or $BlobFileName -like ("Install-Vsix.ps1") -or $BlobFileName -like ("Install-Vsix-All.ps1"))
        {
          New-Item -Path $env:SystemDrive -Name 'VSCode' -ItemType "directory" -Force
          New-Item -Path $env:SystemDrive\VSCode -Name 'extensions' -ItemType "directory" -Force
          $InstallerDirectory = "$env:SystemDrive\VSCode\extensions"
          Write-Host "VSIX related file path. Altering storage container copy to custom VS Code directory with user read and execute permissions"
        }
        else
        {
          New-Item -Path $env:windir\temp -Name $Installer -ItemType "directory" -Force
          $InstallerDirectory = "$env:windir\temp\$Installer"
        }
        Write-Host "Setting file copy to install directory: $InstallerDirectory"

        # Copy the file from the storage account - Special case for vsix files that need a recursive copy
        if ($BlobFileName -notlike ("*.vsix"))
        {
          Write-Host "Invoking WebClient download for file : $BlobFileName"
          #Invoking WebClient to download blobs because it is more efficient than Invoke-WebRequest for large files.
          $WebClient = New-Object System.Net.WebClient
          $WebClient.Headers.Add('x-ms-version', '2017-11-09')
          $webClient.Headers.Add("Authorization", "Bearer $AccessToken")
          $webClient.DownloadFile("$StorageAccountUrl$ContainerName$BlobName", "$InstallerDirectory\$BlobFileName")
          Start-Sleep -Seconds 30
        }
        else
        {
          #BlobName is a comma delimited list of files to download - parse and download each file
          $BlobNameList = $BlobName.Split(',')
          Write-Host "Comma delimited list parsed from blob name: $BlobNameList"
          foreach ($BlobNameItem in $BlobNameList)
          {
            $BlobFileName = $BlobNameItem.Split("/")[-1]
            Write-Host "Iterating comma delimited list for blob item: $BlobNameItem"
            Write-Host "Invoking WebClient download for file : $BlobFileName"
            #Invoking WebClient to download blobs because it is more efficient than Invoke-WebRequest for large files.
            $WebClient = New-Object System.Net.WebClient
            $WebClient.Headers.Add('x-ms-version', '2017-11-09')
            $webClient.Headers.Add("Authorization", "Bearer $AccessToken")
            $webClient.DownloadFile("$StorageAccountUrl$ContainerName$BlobNameItem", "$InstallerDirectory\$BlobFileName")
            Start-Sleep -Seconds 5
          }
        }
        if($BlobFileName -like ("*.exe"))
        {
          Start-Process -FilePath $env:windir\temp\$Installer\$BlobFileName -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
          $wmistatus = Get-WmiObject -Class Win32_Product | Where-Object Name -like "*$($installer)*"
          if($wmistatus)
          {
            Write-Host $wmistatus.Name "is installed"
          }
          $regstatus = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -like "*$($installer)*" }
          if($regstatus)
          {
            Write-Host $regstatus.DisplayName "is installed"
          }
          $regstatusWow6432 = Get-ItemProperty 'HKLM:\Software\WOW6432Node\*' | Where-Object { $_.PSChildName -like "*$($installer)*" }
          if($regstatusWow6432)
          {
            Write-Host $regstatusWow6432.PSChildName "is installed"
          }
          else
          {
            Write-host $Installer "did not install properly, please check arguments"
          }
        }
        if($BlobFileName -like ("*.msi"))
        {
          Set-Location -Path $env:windir\temp\$Installer
          $Path = (Get-ChildItem -Path "$env:windir\temp\$Installer\$BlobFileName" -Recurse | Where-Object {$_.Name -eq "$BlobFileName"}).FullName  
          Write-Host "Invoking msiexec.exe for install path : $Path"
          #NOTE: Must include the package/i path for the full msi installer file path
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
        if($BlobFileName -like ("*.bat"))
        {
          Set-Location -Path $env:windir\temp\$Installer
          Start-Process -FilePath cmd.exe -ArgumentList $env:windir\temp\$Installer\$Arguments -Wait
        }
        if($BlobFileName -like ("*.ps1"))
        {
          if($BlobFileName -like ("Install-Vsix.ps1") -or $BlobFileName -like ("Install-Vsix-All.ps1"))
          {
            Set-Location -Path $env:SystemDrive\VSCode\extensions
            #NOTE: This is a manual script to run on user first time logon - do not run it as system
          }
          elseif($BlobFileName -like ("Install-BundleSoftware.ps1"))
          {
            Set-Location -Path $env:windir\temp\$Installer
            $Path = (Get-ChildItem -Path "$env:windir\temp\$Installer\$BlobFileName" -Recurse | Where-Object {$_.Name -eq "$BlobFileName"}).FullName  
            #Comment out to prevent loop
            #Start-Process -FilePath PowerShell.exe -ArgumentList "-File $Path -UserAssignedIdentityObjectId $UserAssignedIdentityObjectId -StorageAccountName $StorageAccountName -ContainerName $ContainerName -StorageEndpoint $StorageEndpoint $Arguments" -Wait
          }
          else
          {
            Set-Location -Path $env:windir\temp\$Installer
            $Path = (Get-ChildItem -Path "$env:windir\temp\$Installer\$BlobFileName" -Recurse | Where-Object {$_.Name -eq "$BlobFileName"}).FullName  
            Start-Process -FilePath PowerShell.exe -ArgumentList "-File $Path $Arguments" -Wait
          }
        }
        if($BlobFileName -like ("*.zip"))
        {
          Set-Location -Path $env:windir\temp\$Installer
          Expand-Archive -Path $env:windir\temp\$Installer\$BlobFileName -DestinationPath $env:windir\temp\$Installer -Force
          Remove-Item -Path .\$BlobFileName -Force -Recurse
        }
        
        #NOTE: Verify customers that are expected to persist for future users (ex. VSIX files ands scripts) are not removed
        #Write-Host "Removing $Installer Files"
        #Start-Sleep -Seconds 5
        #Remove-item $env:windir\temp\$Installer -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
    }
}