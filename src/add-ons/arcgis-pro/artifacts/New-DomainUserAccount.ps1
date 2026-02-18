param (
    [string]$DomainUserPassword,
    [string]$DomainUserUsername
)
Import-Module ActiveDirectory -ErrorAction Stop
$SecureDomainUserPassword = ConvertTo-SecureString -String $DomainUserPassword -AsPlainText -Force
New-ADUser `
    -Name $DomainUserUsername `
    -AccountPassword $SecureDomainUserPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -PasswordNeverExpires $true