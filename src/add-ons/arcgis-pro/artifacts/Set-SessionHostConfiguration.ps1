$ErrorActionPreference = 'Stop'
$Settings = @(

    [PSCustomObject]@{
        Name = 'NoAutoUpdate'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        PropertyType = 'DWord'
        Value = 1
    },

    [PSCustomObject]@{
        Name = 'fEnableTimeZoneRedirection'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    },

    [PSCustomObject]@{
        Name = 'AVC444ModePreferred'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    }

    [PSCustomObject]@{
        Name = 'AVCHardwareEncodePreferred'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    },

    [PSCustomObject]@{
        Name = 'bEnumerateHWBeforeSW'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    },

    [PSCustomObject]@{
        Name = 'DisplayRefreshRate'
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
        PropertyType = 'DWord'
        Value = 60
    },

    [PSCustomObject]@{
        Name = 'DWMFRAMEINTERVAL'
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
        PropertyType = 'DWord'
        Value = 15
    },

    [PSCustomObject]@{
        Name = 'fEnableConnectionIntervalGraphicsData'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    },

    [PSCustomObject]@{
        Name = 'HEVCHardwareEncodePreferred'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 1
    },

    [PSCustomObject]@{
        Name = 'ImageQuality'
        Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        PropertyType = 'DWord'
        Value = 2
    }
)

foreach($Setting in $Settings)
{
    if(!(Test-Path -Path $Setting.Path))
    {
        New-Item -Path $Setting.Path -Force | Out-Null
    }
    $Value = Get-ItemProperty -Path $Setting.Path -Name $Setting.Name -ErrorAction 'SilentlyContinue'
    if(!$Value)
    {
        New-ItemProperty -Path $Setting.Path -Name $Setting.Name -PropertyType $Setting.PropertyType -Value $Setting.Value -Force | Out-Null
    }
    elseif($Value.$($Setting.Name) -ne $Setting.Value)
    {
        Set-ItemProperty -Path $Setting.Path -Name $Setting.Name -Value $Setting.Value -Force | Out-Null
    }
    Start-Sleep -Seconds 1 | Out-Null
}