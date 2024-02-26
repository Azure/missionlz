param location string
param imageVirtualMachineName string
param tags object
param updateService string
param wsusServer string

resource imageVm 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: imageVirtualMachineName
}

resource microsoftUpdates 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'install-microsoft-updates'
  location: location
  parent: imageVm
  properties: {
    asyncExecution: false
    parameters: updateService == 'WSUS' ? [
      {
        name: 'Service'
        value: updateService
      }
      {
        name: 'WSUSServer'
        value: wsusServer
      }
    ] : [
      {
        name: 'Service'
        value: updateService
      }
    ]   
    source: {
      script: '''
        param (
          # The App Name to pass to the WUA API as the calling application.
          [Parameter()]
          [String]$AppName = "Windows Update API Script",
          # The search criteria to be used.
          [Parameter()]
          [String]$Criteria = "IsInstalled=0 and Type='Software' and IsHidden=0",
          [Parameter()]
          [bool]$ExcludePreviewUpdates = $true,
          # Default service (WSUS if machine is configured to use it, or MU if opted in, or WU otherwise.)
          [Parameter()]
          [ValidateSet("WU","MU","WSUS","DCAT","STORE","OTHER")]
          [string]$Service = 'MU',
          # The http/https fqdn for the Windows Server Update Server
          [Parameter()]
          [string]$WSUSServer
        )
        
        Function ConvertFrom-InstallationResult {
        [CmdletBinding()]
            param (
                [Parameter()]
                [int]$Result
            )        
            switch ($Result) {
                2 { $Text = 'Succeeded' }
                3 { $Text = 'Succeeded with errors' }
                4 { $Text = 'Failed' }
                5 { $Text = 'Cancelled' }
                Default { $Text = "Unexpected ($Result)"}
            }        
            Return $Text
        }
        Start-Transcript -Path "$env:SystemRoot\Logs\ImageBuild\Install-Updates.log"
        Switch ($Service.ToUpper()) {
            'WU' { $ServerSelection = 2 }
            'MU' { $ServerSelection = 3; $ServiceId = "7971f918-a847-4430-9279-4a52d1efe18d" }
            'WSUS' { $ServerSelection = 1 }
            'DCAT' { $ServerSelection = 3; $ServiceId = "855E8A7C-ECB4-4CA3-B045-1DFA50104289" }
            'STORE' { $serverSelection = 3; $ServiceId = "117cab2d-82b1-4b5a-a08c-4d62dbee7782" }
            'OTHER' { $ServerSelection = 3; $ServiceId = $Service }
        }        
        If ($Service -eq 'MU') {
            $UpdateServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
            $UpdateServiceManager.ClientApplicationID = $AppName
            $UpdateServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")
            $null = cmd /c reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AllowMUUpdateService /t REG_DWORD /d 1 /f '2>&1'
            Write-Output "Added Registry entry to configure Microsoft Update. Exit Code: [$LastExitCode]"
        } Elseif ($Service -eq 'WSUS' -and $WSUSServer) {
            $null = cmd /c reg.exe ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUServer /t REG_SZ /d $WSUSServer /f '2>&1'
            $null = cmd /c reg.exe ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUStatusServer /t REG_SZ /d $WSUSServer /f '2>&1'
            Write-Output "Added Registry entry to configure WSUS Server. Exit Code: [$LastExitCode]"
        }        
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSession.ClientApplicationID = $AppName   
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $UpdateSearcher.ServerSelection = $ServerSelection
        If ($ServerSelection -eq 3) {
            $UpdateSearcher.ServiceId = $ServiceId
        }
        Write-Output "Searching for Updates..."
        $SearchResult = $UpdateSearcher.Search($Criteria)
        If ($SearchResult.Updates.Count -eq 0) {
            Write-Output "There are no applicable updates."
            Write-Output "Now Exiting"
            Exit $ExitCode
        }
        Write-Output "List of applicable items found for this computer:"
        For ($i = 0; $i -lt $SearchResult.Updates.Count; $i++) {
            $Update = $SearchResult.Updates[$i]
            Write-Output "$($i + 1) > $($update.Title)"
        }
        $AtLeastOneAdded = $false
        $ExclusiveAdded = $false   
        $UpdatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
        Write-Output "Checking search results:"
        For ($i = 0; $i -lt $SearchResult.Updates.Count; $i++) {
            $Update = $SearchResult.Updates[$i]
            $AddThisUpdate = $false        
            If ($ExclusiveAdded) {
                Write-Output "$($i + 1) > skipping: '$($update.Title)' because an exclusive update has already been selected."
            } Else {
                $AddThisUpdate = $true
            }        
            if ($ExcludePreviewUpdates -and $update.Title -like '*Preview*') {
                Write-Output "$($i + 1) > Skipping: '$($update.Title)' because it is a preview update."
                $AddThisUpdate = $false
            }        
            If ($AddThisUpdate) {
                $PropertyTest = 0
                $ErrorActionPreference = 'SilentlyContinue'
                $PropertyTest = $Update.InstallationBehavior.Impact
                $ErrorActionPreference = 'Stop'
                If ($PropertyTest -eq 2) {
                    If ($AtLeastOneAdded) {
                        Write-Output "$($i + 1) > skipping: '$($update.Title)' because it is exclusive and other updates are being installed first."
                        $AddThisUpdate = $false
                    }
                }
            }
            If ($AddThisUpdate) {
                Write-Output "$($i + 1) > adding: '$($update.Title)'"
                $UpdatesToDownload.Add($Update) | out-null
                $AtLeastOneAdded = $true
                $ErrorActionPreference = 'SilentlyContinue'
                $PropertyTest = $Update.InstallationBehavior.Impact
                $ErrorActionPreference = 'Stop'
                If ($PropertyTest -eq 2) {
                    Write-Output "This update is exclusive; skipping remaining updates"
                    $ExclusiveAdded = $true
                }
            }
        }        
        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        Write-Output "Downloading updates..."
        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToDownload
        $Downloader.Download()
        Write-Output "Successfully downloaded updates:"        
        For ($i = 0; $i -lt $UpdatesToDownload.Count; $i++) {
            $Update = $UpdatesToDownload[$i]
            If ($Update.IsDownloaded -eq $true) {
                Write-Output "$($i + 1) > $($update.title)"
                $UpdatesToInstall.Add($Update) | out-null
            }
        }        
        If ($UpdatesToInstall.Count -gt 0) {
            Write-Output "Now installing updates..."
            $Installer = $UpdateSession.CreateUpdateInstaller()
            $Installer.Updates = $UpdatesToInstall
            $InstallationResult = $Installer.Install()
            $Text = ConvertFrom-InstallationResult -Result $InstallationResult.ResultCode
            Write-Output "Installation Result: $($Text)"        
            If ($InstallationResult.RebootRequired) {
                Write-Output "Atleast one update requires a reboot to complete the installation."
            }
        }
        If ($service -eq 'MU') {
            Reg.exe DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AllowMUUpdateService /f
        } Elseif ($Service -eq 'WSUS' -and $WSUSServer) {
            reg.exe DELETE "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUServer /f
            reg.exe DELETE "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUStatusServer /f
        }
        Stop-Transcript
      '''
    }
    treatFailureAsDeploymentFailure: true
  }
  tags: tags
}
