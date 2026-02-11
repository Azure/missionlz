param (
    [string]$DomainUserPassword,
    [string]$DomainUserUsername
)

# Ensure the ActiveDirectory module is loaded
Import-Module ActiveDirectory -ErrorAction Stop

# Convert password to secure string
$SecureDomainUserPassword = ConvertTo-SecureString -String $DomainUserPassword -AsPlainText -Force

# Create the new AD user
New-ADUser `
    -Name $DomainUserUsername `
    -AccountPassword $SecureDomainUserPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -PasswordNeverExpires $true
        