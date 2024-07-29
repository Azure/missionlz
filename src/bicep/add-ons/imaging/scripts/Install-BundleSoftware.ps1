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
  
    If($true -eq $item.Enabled) {
        $Installer = $item.name
        $BlobName = $item.blobName
        $Arguments = $item.arguments
        Write-Host "Downloading $Installer from $BlobName"
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
        if($BlobName -like ("*.ps1") -and $BlobName -notlike ("Install-BundleSoftware.ps1"))
        {
          Start-Process -FilePath PowerShell.exe -ArgumentList "-File $Path $Arguments" -Wait
        }
        if($BlobName -like ("*.zip"))
        {
          Expand-Archive -Path $InstallerDirectory\$BlobName -DestinationPath $InstallerDirectory -Force
          Remove-Item -Path .\$BlobName -Force -Recurse
        }
        Write-Host "Removing $Installer Files"
        Start-Sleep -Seconds 5
        Remove-item $InstallerDirectory -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
    }
}