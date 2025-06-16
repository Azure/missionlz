[CmdletBinding()]
param(

    [Parameter(Mandatory)]
    [ValidateSet('China','Global','USGov','USGovDoD')]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$TenantId
)

# Install the Microsoft Graph module
if (!$(Get-Module -ListAvailable | Where-Object {$_.Name -eq 'Microsoft.Graph'}))
{
    Install-Module -Name 'Microsoft.Graph' -Scope 'CurrentUser'
}

# Connect to Azure AD
Connect-MgGraph `
    -Environment $Environment `
    -TenantId $TenantId

# Determine the correct application ID for the 'Domain Controller Services' service principal
$ApplicationId = switch($Environment)
{
    Global { '2565bd9d-da50-47d4-8b85-4c97f669dc36' }
    default { '6ba9a5d4-8456-4118-b521-9c5ca10cdf84' }

}
# Register the 'Domain Controller Services' service principal to the subscription
New-MgServicePrincipal `
    -AppId $ApplicationId

# If the group doesn't exist, create it
if (!$(Get-MgGroup -Filter "DisplayName eq 'AAD DC Administrators'"))
{
  New-MgGroup `
    -DisplayName "AAD DC Administrators" `
    -Description "Delegated group to administer Microsoft Entra Domain Services" `
    -SecurityEnabled:$true `
    -MailEnabled:$false `
    -MailNickName "AADDCAdministrators"
} 
else 
{
  Write-Output "Admin group already exists."
}

$AzureEnvironment = switch($Environment)
{
    China { 'AzureChinaCloud' }
    Global { 'AzureCloud' }
    USGov { 'AzureUSGovernment' }
    USGovDoD { 'AzureUSGovernment' }
}

# Install the Az module
if (!$(Get-Module -ListAvailable | Where-Object {$_.Name -eq 'Az.Resources'}))
{
    Install-Module -Name 'Az.Resources' -Scope 'CurrentUser'
}

# Connect to Azure
Connect-AzAccount `
    -Environment $AzureEnvironment `
    -Tenant $TenantId `
    -Subscription $SubscriptionId

# Register the 'Microsoft.AAD' provider to the subscription, if not already registered
Register-AzResourceProvider `
    -ProviderNamespace 'Microsoft.AAD'