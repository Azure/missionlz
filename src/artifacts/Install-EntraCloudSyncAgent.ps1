param (
    [Parameter(Mandatory = $true)]
    [string]$AzureEnvironment,

    [Parameter(Mandatory = $true)]
    [string]$AzureResourceManagerUri,

    [Parameter(Mandatory = $true)]
    [string]$DomainAdministratorPassword,

    [Parameter(Mandatory = $true)]
    [string]$DomainAdministratorUsername,

    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $true)]
    [string]$HybridIdentityAdministratorPassword,

    [Parameter(Mandatory = $true)]
    [string]$HybridIdentityAdministratorUserPrincipalName,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

# Variables
$AzureResourceManagerDomain = $AzureResourceManagerUri.Split('/')[2]
$AzureDomainSuffix = switch ($AzureEnvironment) {
    'AzureCloud' { 'net' }
    'AzureUSGovernment' { 'us' }
    Default { $AzureResourceManagerDomain.Replace('management.azure.', '') }
}
$Netbios = $DomainName.Split('.')[0]

# Download the provisioning agent installer
Invoke-WebRequest `
    -Uri $('https://download.msappproxy.' + $AzureDomainSuffix + '/Subscription/' + $SubscriptionId + '/Connector/previewProvisioningAgentInstaller') `
    -OutFile 'C:\Temp\AADConnectProvisioningAgentSetup.exe'

# Install the provisioning agent in quiet mode
Start-Process `
    -FilePath 'C:\Temp\AADConnectProvisioningAgentSetup.exe' `
    -ArgumentList "/quiet ENVIRONMENTNAME=$AzureEnvironment" `
    -NoNewWindow `
    -PassThru `
    -Wait

# Import the provisioning agent PowerShell module
Import-Module 'C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\Microsoft.CloudSync.PowerShell.dll'

# Connect to Microsoft Entra ID using an account with the hybrid identity role
$CloudAdminPassword = ConvertTo-SecureString -String $HybridIdentityAdministratorPassword -AsPlainText -Force
$CloudAdminCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($HybridIdentityAdministratorUserPrincipalName, $CloudAdminPassword)
Connect-AADCloudSyncAzureAD -Credential $CloudAdminCreds

# Add the gMSA account
$DomainAdminPassword = ConvertTo-SecureString -String $DomainAdministratorPassword -AsPlainText -Force
$DomainAdminCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ("$Netbios\$DomainAdministratorUsername", $DomainAdminPassword)
Add-AADCloudSyncGMSA -Credential $DomainAdminCreds

# Add the domain
Add-AADCloudSyncADDomain -DomainName $DomainName -Credential $DomainAdminCreds

# Restart the service
Restart-Service -Name 'AADConnectProvisioningAgent'