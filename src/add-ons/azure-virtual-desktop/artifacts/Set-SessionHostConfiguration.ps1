Param(
    [string]$ActiveDirectorySolution,
    [string]$AmdVmSize,
    [string]$Fslogix,
    [string]$FslogixContainerType,
    [string]$NetAppFileServer,
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

#  Add Recommended AVD Settings
$Settings = @(

    # Enable Time Zone Redirection: https://learn.microsoft.com/azure/virtual-desktop/set-up-customize-master-image#set-up-time-zone-redirection
    [PSCustomObject]@{
        Name = 'fEnableTimeZoneRedirection'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    },

    # Disable Automatic Updates: https://learn.microsoft.com/azure/virtual-desktop/set-up-customize-master-image#disable-automatic-updates
    [PSCustomObject]@{
        Name = 'NoAutoUpdate'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        PropertyType = 'DWord'
        Value = 1
    }
)


# AMD & NVIDIA GPU settings
if ($AmdVmSize -eq 'true' -or $NvidiaVmSize -eq 'true') 
{
    $Settings += @(

        # GPU-accelerated application rendering: Use hardware graphics adapters for all RDS sessions - https://learn.microsoft.com/azure/virtual-desktop/graphics-enable-gpu-acceleration?tabs=group-policy#enable-gpu-accelerated-application-rendering-and-remote-frame-encoding
        [PSCustomObject]@{
            Name = 'bEnumerateHWBeforeSW'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        },

        # Configure the refresh rate for the display
        [PSCustomObject]@{
            Name = 'DisplayRefreshRate'
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
            PropertyType = 'DWord'
            Value = '0x60'
        },

        # Configure DWM frame interval: https://learn.microsoft.com/troubleshoot/windows-server/remote/frame-rate-limited-to-30-fps
        [PSCustomObject]@{
            Name = 'DWMFRAMEINTERVAL'
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
            PropertyType = 'DWord'
            Value = 15
        },

        # Graphics logging: Connection graphics data - https://learn.microsoft.com/azure/virtual-desktop/connection-latency#connection-graphics-data-preview
        [PSCustomObject]@{
            Name = 'fEnableConnectionIntervalGraphicsData'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        },

        # Increase Chroma value to 4:4:4 for RDP sessions using AVC: Configure image quality for RemoteFX Adaptive Graphics - https://learn.microsoft.com/azure/virtual-desktop/graphics-chroma-value-increase-4-4-4?tabs=group-policy
        [PSCustomObject]@{
            Name = 'ImageQuality'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 2
        }
    )
}

# NVIDIA GPUs settings
if ($NvidiaVmSize -eq 'true') 
{
    $Settings += @(

        # GPU-accelerated remote frame encoding using H.264/AVC: Prioritize H.264/AVC 444 graphics mode for Remote Desktop Connections - https://learn.microsoft.com/azure/virtual-desktop/graphics-enable-gpu-acceleration?tabs=group-policy#enable-gpu-accelerated-application-rendering-and-remote-frame-encoding
        [PSCustomObject]@{
            Name = 'AVC444ModePreferred'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        }

        # GPU-accelerated remote frame encoding using H.264/AVC: Configure H.264/AVC hardware encoding for Remote Desktop Connections - https://learn.microsoft.com/azure/virtual-desktop/graphics-enable-gpu-acceleration?tabs=group-policy#enable-gpu-accelerated-application-rendering-and-remote-frame-encoding
        [PSCustomObject]@{
            Name = 'AVCHardwareEncodePreferred'
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            PropertyType = 'DWord'
            Value = 1
        },

        # GPU-accelerated remote frame encoding using H.265/HEVC: Configure H.265/HEVC hardware encoding for Remote Desktop Connections - https://learn.microsoft.com/azure/virtual-desktop/graphics-enable-gpu-acceleration?tabs=group-policy#enable-gpu-accelerated-application-rendering-and-remote-frame-encoding
        [PSCustomObject]@{
            Name = 'HEVCHardwareEncodePreferred'
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
            $CloudCacheOfficeContainers += 'type=smb,connectionString=\\' + $NetAppFileServer + '\office-containers;'
            $CloudCacheProfileContainers += 'type=smb,connectionString=\\' + $NetAppFileServer + '\profile-containers;'
            $OfficeContainers += '\\' + $NetAppFileServer + '\office-containers'
            $ProfileContainers += '\\' + $NetAppFileServer + '\profile-containers'
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
