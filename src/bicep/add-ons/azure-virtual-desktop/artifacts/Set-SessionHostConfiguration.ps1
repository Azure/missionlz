Param(
    [string]$ActiveDirectorySolution,
    [string]$AmdVmSize,
    [string]$Fslogix,
    [string]$FslogixContainerType,
    [string]$NetAppFileShares,
    [string]$NvidiaVmSize,
    [string]$StorageAccountPrefix,
    [int]$StorageCount,
    [int]$StorageIndex,
    [string]$StorageService,
    [string]$StorageSuffix,
    [string]$UniqueToken
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'


# Convert NetAppFiles share names from a JSON array to a PowerShell array
[array]$NetAppFileShares = $NetAppFileShares.Replace("'",'"') | ConvertFrom-Json
$NetAppFileShares | Add-Content -Path 'C:\cse.txt' -Force

#  Add Recommended Security Settings
$Settings = @(

    # Set Kerberos Encryption for STIG compliance
    [PSCustomObject]@{
        Name = 'SupportedEncryptionTypes'
        Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters'
        PropertyType = 'DWord'
        Value = 2147483640
    }
)

#  Add Recommended AVD Settings
$Settings = @(

    # Disable Automatic Updates: https://learn.microsoft.com/azure/virtual-desktop/set-up-customize-master-image#disable-automatic-updates
    [PSCustomObject]@{
        Name = 'NoAutoUpdate'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        PropertyType = 'DWord'
        Value = 1
    },

    # Enable Time Zone Redirection: https://learn.microsoft.com/azure/virtual-desktop/set-up-customize-master-image#set-up-time-zone-redirection
    [PSCustomObject]@{
        Name = 'fEnableTimeZoneRedirection'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    }
)


#  Add GPU Settings
# This setting applies to the VM Size's recommended for AVD with a GPU
if ($AmdVmSize -eq 'true' -or $NvidiaVmSize -eq 'true') 
{
    $Settings += @(

        # Configure GPU-accelerated app rendering: https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-app-rendering
        [PSCustomObject]@{
            Name = 'bEnumerateHWBeforeSW'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        },

        # Configure fullscreen video encoding: https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu#configure-fullscreen-video-encoding
        [PSCustomObject]@{
            Name = 'AVC444ModePreferred'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }
    )
}

# This setting applies only to VM Size's recommended for AVD with a Nvidia GPU
if($NvidiaVmSize -eq 'true')
{
    $Settings += @(

        # Configure GPU-accelerated frame encoding: https://learn.microsoft.com/azure/virtual-desktop/configure-vm-gpu#configure-gpu-accelerated-frame-encoding
        [PSCustomObject]@{
            Name = 'AVChardwareEncodePreferred'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }
    )
}

#  Add Fslogix Settings
if($Fslogix -eq 'true')
{
    $FilesSuffix = '.file.' + $StorageSuffix
    $CloudCacheOfficeContainers = @()
    $CloudCacheProfileContainers = @()
    $OfficeContainers = @()
    $ProfileContainers = @()
    switch($StorageService)
    {
        'AzureFiles' {
            for($i = $StorageIndex; $i -lt $($StorageIndex + $StorageCount); $i++)
            {
                $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $($StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $UniqueToken).Substring(0,15) + $FilesSuffix + '\office-containers;'
                $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $($StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $UniqueToken).Substring(0,15) + $FilesSuffix + '\profile-containers;'
                $OfficeContainers += '\\' + $($StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $UniqueToken).Substring(0,15) + $FilesSuffix + '\office-containers'
                $ProfileContainers += '\\' + $($StorageAccountPrefix + $i.ToString().PadLeft(2,'0') + $UniqueToken).Substring(0,15) + $FilesSuffix + '\profile-containers'
            }
        }
        'AzureNetAppFiles' {
            $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $NetAppFileShares[0] + '\office-containers;'
            $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $(if($NetAppFileShares.Length -gt 1){$NetAppFileShares[1]}else{$NetAppFileShares[0]}) + '\profile-containers;'
            $OfficeContainers += '\\' + $NetAppFileShares[0] + '\office-containers'
            $ProfileContainers += '\\' + $(if($NetAppFileShares.Length -gt 1){$NetAppFileShares[1]}else{$NetAppFileShares[0]}) + '\profile-containers'
        }
    }
    
    $Shares = @()
    $Shares += $OfficeContainers
    $Shares += $ProfileContainers

    $Settings += @(

        # Enables Fslogix profile containers: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#enabled
        [PSCustomObject]@{
            Name = 'Enabled'
            Path = 'HKLM:\SOFTWARE\Fslogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # Deletes a local profile if it exists and matches the profile being loaded from VHD: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#deletelocalprofilewhenvhdshouldapply
        [PSCustomObject]@{
            Name = 'DeleteLocalProfileWhenVHDShouldApply'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#flipflopprofiledirectoryname
        [PSCustomObject]@{
            Name = 'FlipFlopProfileDirectoryName'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 1
        },

        # Specifies the number of retries attempted when a VHD(x) file is locked: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#lockedretrycount
        [PSCustomObject]@{
            Name = 'LockedRetryCount'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 3
        },

        # Specifies the number of seconds to wait between retries: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#lockedretryinterval
        [PSCustomObject]@{
            Name = 'LockedRetryInterval'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 15
        },

        # Specifies if the profile container can be accessed concurrently: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#profiletype
        [PSCustomObject]@{
            Name = 'ProfileType'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 0
        },

        # Specifies the number of seconds to wait between retries when attempting to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#reattachintervalseconds
        [PSCustomObject]@{
            Name = 'ReAttachIntervalSeconds'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 15
        },

        # Specifies the number of times the system should attempt to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#reattachretrycount
        [PSCustomObject]@{
            Name = 'ReAttachRetryCount'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 3
        },

        # Specifies the maximum size of the user's container in megabytes. Newly created VHD(x) containers are of this size: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#sizeinmbs
        [PSCustomObject]@{
            Name = 'SizeInMBs'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'DWord'
            Value = 30000
        },

        # Specifies the file extension for the profile containers: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=profiles#volumetype
        [PSCustomObject]@{
            Name = 'VolumeType'
            Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
            PropertyType = 'String'
            Value = 'VHDX'
        }
    )

    if($FslogixContainerType -like "CloudCache*")
    {
        $Settings += @(
            # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#vhdlocations
            [PSCustomObject]@{
                Name = 'CCDLocations'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'MultiString'
                Value = $CloudCacheProfileContainers
            }
        )           
    }
    else
    {
        $Settings += @(
            # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#vhdlocations
            [PSCustomObject]@{
                Name = 'VHDLocations'
                Path = 'HKLM:\SOFTWARE\FSLogix\Profiles'
                PropertyType = 'MultiString'
                Value = $ProfileContainers
            }
        )
    }

    if($FslogixContainerType -like "*OfficeContainer")
    {
        $Settings += @(

            # Enables Fslogix office containers: https://learn.microsoft.com/fslogix/office-container-configuration-reference#enabled
            [PSCustomObject]@{
                Name = 'Enabled'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 1
            },

            # The folder created in the Fslogix fileshare will begin with the username instead of the SID: https://learn.microsoft.com/fslogix/office-container-configuration-reference#flipflopprofiledirectoryname
            [PSCustomObject]@{
                Name = 'FlipFlopProfileDirectoryName'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 1
            },         
            
            # Teams data is redirected to the container: https://learn.microsoft.com/fslogix/office-container-configuration-reference#includeteams
            [PSCustomObject]@{
                Name = 'IncludeTeams'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 1
            },                  

            # Specifies the number of retries attempted when a VHD(x) file is locked: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#lockedretrycount
            [PSCustomObject]@{
                Name = 'LockedRetryCount'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 3
            },

            # Specifies the number of seconds to wait between retries: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#lockedretryinterval
            [PSCustomObject]@{
                Name = 'LockedRetryInterval'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 15
            },

            # Specifies the number of seconds to wait between retries when attempting to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#reattachintervalseconds
            [PSCustomObject]@{
                Name = 'ReAttachIntervalSeconds'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 15
            },

            # Specifies the number of times the system should attempt to reattach the VHD(x) container if it's disconnected unexpectedly: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#reattachretrycount
            [PSCustomObject]@{
                Name = 'ReAttachRetryCount'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 3
            },

            # Specifies the maximum size of the user's container in megabytes: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#sizeinmbs
            [PSCustomObject]@{
                Name = 'SizeInMBs'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'DWord'
                Value = 30000
            },

            # Specifies the type of container: https://learn.microsoft.com/fslogix/reference-configuration-settings?tabs=odfc#volumetype
            [PSCustomObject]@{
                Name = 'VolumeType'
                Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                PropertyType = 'String'
                Value = 'VHDX'
            }
        )

        if($FslogixContainerType -like "CloudCache*")
        {
            $Settings += @(
                # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/profile-container-configuration-reference#vhdlocations
                [PSCustomObject]@{
                    Name = 'CCDLocations'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'MultiString'
                    Value = $CloudCacheOfficeContainers
                }
            )           
        }
        else
        {
            $Settings += @(
                # List of file system locations to search for the user's profile VHD(X) file: https://learn.microsoft.com/fslogix/office-container-configuration-reference#vhdlocations
                [PSCustomObject]@{
                    Name = 'VHDLocations'
                    Path = 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC'
                    PropertyType = 'MultiString'
                    Value = $OfficeContainers
                }
            )
        }
    }
}


# Set registry settings
foreach($Setting in $Settings)
{
    # Create registry key(s) if necessary
    if(!(Test-Path -Path $Setting.Path))
    {
        New-Item -Path $Setting.Path -Force | Out-Null
    }

    # Checks for existing registry setting
    $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
    
    # Creates the registry setting when it does not exist
    if(!$Value)
    {
        New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force | Out-Null
    }
    # Updates the registry setting when it already exists
    elseif($Value.$($Setting.Name) -ne $Setting.Value)
    {
        Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force | Out-Null
    }
    Start-Sleep -Seconds 1 | Out-Null
}
