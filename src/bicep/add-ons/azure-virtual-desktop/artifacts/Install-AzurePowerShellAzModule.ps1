[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $Installer
)

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try 
{
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $Installer /quiet /qn /norestart /passive" -Wait -Passthru | Out-Null
    Write-Log -Message 'Installed Azure PowerShell AZ Module' -Type 'INFO'
    $Output = [pscustomobject][ordered]@{
        installer = $Installer
    }
    $Output | ConvertTo-Json
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}