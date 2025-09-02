param (
    [string]$AzureEnvironment,
    [string]$AzureResourceManagerUri,
    [string]$DomainAdministratorPassword,
    [string]$SubscriptionId
)

# Download the provisioning agent installer
$AzureResourceManagerDomain = $AzureResourceManagerUri.Split('/')[2]
$AzureDomainSuffix = switch ($AzureEnvironment) {
    'AzureCloud' { 'net' }
    'AzureUSGovernment' { 'us' }
    Default { $AzureResourceManagerDomain.Replace('management.azure.', '') }
}

Invoke-WebRequest `
    -Uri $('https://download.msappproxy.' + $AzureDomainSuffix + '/Subscription/' + $SubscriptionId + '/Connector/previewProvisioningAgentInstaller') `
    -OutFile 'C:\Temp\AADConnectProvisioningAgentSetup.exe'

# Install the provisioning agent in quiet mode
$installerProcess = Start-Process `
    -FilePath 'C:\Temp\AADConnectProvisioningAgentSetup.exe' `
    -ArgumentList "/quiet ENVIRONMENTNAME=$AzureEnvironment" `
    -NoNewWindow `
    -PassThru

$installerProcess.WaitForExit()

# Import the provisioning agent PowerShell module
Import-Module 'C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\Microsoft.CloudSync.PowerShell.dll'

# Connect to Microsoft Entra ID using an account with the hybrid identity role
$hybridAdminPassword = ConvertTo-SecureString -String 'Hybrid Identity Administrator password' -AsPlainText -Force 
$hybridAdminCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ("HybridIDAdmin@contoso.onmicrosoft.com", $hybridAdminPassword) 
Connect-AADCloudSyncAzureAD -Credential $hybridAdminCreds

# Add the gMSA account
$domainAdminPassword = ConvertTo-SecureString -String 'Domain admin password' -AsPlainText -Force 
$domainAdminCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ("DomainName\DomainAdminAccountName", $domainAdminPassword) 
Add-AADCloudSyncGMSA -Credential $domainAdminCreds

# Add the domain
$contosoDomainAdminPassword = ConvertTo-SecureString -String "Domain admin password" -AsPlainText -Force
$contosoDomainAdminCreds = New-Object 'System.Management.Automation.PSCredential' -ArgumentList ("DomainName\DomainAdminAccountName", $contosoDomainAdminPassword) 
Add-AADCloudSyncADDomain -DomainName 'contoso.com' -Credential $contosoDomainAdminCreds

# Restart the service
Restart-Service -Name 'AADConnectProvisioningAgent'