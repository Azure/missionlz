param (
    [String]$DomainAdminPassword,
    [String]$DomainAdminUserPrincipalName,
    [String]$FileServer,
    [String]$SecurityPrincipalNames,
    [String]$ShareNames
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

# Variables
# Convert parameters values from JSON array to a PowerShell array
[array]$SecurityPrincipalNames = $SecurityPrincipalNames.Replace('\','') | ConvertFrom-Json
[array]$Shares = $ShareNames.Replace('\','') | ConvertFrom-Json

# Create Domain credential
$DomainUsername = $DomainAdminUserPrincipalName
$DomainPassword = ConvertTo-SecureString -String $DomainAdminPassword -AsPlainText -Force
[pscredential]$DomainCredential = New-Object System.Management.Automation.PSCredential ($DomainUsername, $DomainPassword)

# Set NTFS permissions of file shares
foreach($Share in $Shares)
{
    # Mount file share
    $FileShare = '\\' + $FileServer + '\' + $Share
    New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $DomainCredential | Out-Null

    # Set recommended NTFS permissions on the file share
    $ACL = Get-Acl -Path 'Z:'
    $CreatorOwner = New-Object System.Security.Principal.Ntaccount ("Creator Owner")
    $ACL.PurgeAccessRules($CreatorOwner)
    $AuthenticatedUsers = New-Object System.Security.Principal.Ntaccount ("Authenticated Users")
    $ACL.PurgeAccessRules($AuthenticatedUsers)
    $Users = New-Object System.Security.Principal.Ntaccount ("Users")
    $ACL.PurgeAccessRules($Users)
    $DomainUsers = New-Object System.Security.AccessControl.FileSystemAccessRule("$Group","Modify","None","None","Allow")
    $ACL.SetAccessRule($DomainUsers)
    $CreatorOwner = New-Object System.Security.AccessControl.FileSystemAccessRule("Creator Owner","Modify","ContainerInherit,ObjectInherit","InheritOnly","Allow")
    $ACL.AddAccessRule($CreatorOwner)
    $ACL | Set-Acl -Path 'Z:' | Out-Null

    # Unmount file share
    Remove-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Force | Out-Null
    Start-Sleep -Seconds 5 | Out-Null
}
