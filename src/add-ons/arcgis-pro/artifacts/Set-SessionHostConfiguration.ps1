$ErrorActionPreference = 'Stop'
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
    },

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