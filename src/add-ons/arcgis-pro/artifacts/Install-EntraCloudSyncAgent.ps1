param (
    [Parameter(Mandatory = $false)]
    [string]$AccessToken,

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
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Variables
$ErrorActionPreference = 'Stop'
$AzureResourceManagerDomain = $AzureResourceManagerUri.Split('/')[2]
$AzureDomainSuffix = switch ($AzureEnvironment) {
    'AzureCloud' { 'net' }
    'AzureUSGovernment' { 'us' }
    Default { $AzureResourceManagerDomain.Replace('management.azure.', '') }
}
$Netbios = $DomainName.Split('.')[0]
$ProvisioningAgentInstallerPath = 'C:\Temp\AADConnectProvisioningAgentSetup.exe'

# Download the provisioning agent for Entra Cloud Sync
Invoke-WebRequest `
    -Uri $('https://download.msappproxy.' + $AzureDomainSuffix + '/Subscription/' + $SubscriptionId + '/Connector/previewProvisioningAgentInstaller') `
    -OutFile $ProvisioningAgentInstallerPath

# Install the provisioning agent for Entra Cloud Sync
Start-Process `
    -FilePath $ProvisioningAgentInstallerPath `
    -ArgumentList "/quiet ENVIRONMENTNAME=$AzureEnvironment" `
    -NoNewWindow `
    -PassThru `
    -Wait

if ($AzureEnvironment -eq 'AzureCloud')
{
    # Import the provisioning agent PowerShell module
    Import-Module 'C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\Microsoft.CloudSync.PowerShell.dll'

    # Connect to Microsoft Entra ID using the access token and UPN of an Hybrid Identity Administrator
    Connect-AADCloudSyncAzureAD -AccessToken $AccessToken -TenantId $TenantId -UserPrincipalName $UserPrincipalName

    # Create the KDS root key if it does not exist
    Add-KdsRootKey -EffectiveTime ((get-date).addhours(-10))

    # Add the gMSA account
    $SecureDomainAdministratorPassword = ConvertTo-SecureString -String $DomainAdministratorPassword -AsPlainText -Force
    $DomainAdministratorCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ("$Netbios\$DomainAdministratorUsername", $SecureDomainAdministratorPassword)
    Add-AADCloudSyncGMSA -Credential $DomainAdministratorCredential

    # Add the domain
    Add-AADCloudSyncADDomain -DomainName $DomainName -Credential $DomainAdministratorCredential

    # Restart the service
    Restart-Service -Name 'AADConnectProvisioningAgent'
}