[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Environment,

    [Parameter()]
    [string]
    $NetworkSecurityGroupName,

    [Parameter()]
    [string]
    $NetworkSecurityGroupResourceGroupName,

    [Parameter()]
    [string]
    $SubscriptionId,

    [Parameter()]
    [string]
    $TenantId,

    [Parameter()]
    [string]
    $UserAssignedIdentityClientId
)

Connect-AzAccount `
    -Environment $Environment `
    -Tenant $TenantId `
    -Subscription $SubscriptionId `
    -Identity `
    -AccountId $UserAssignedIdentityClientId

$Rules = @(
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = '*'
        DestinationPortRange = '5986'
        Direction = 'Inbound'
        Name = 'Allow_WinRM_EntraDS'
        Priority = '300'
        Protocol = 'TCP'
        SourceAddressPrefix = 'AzureActiveDirectoryDomainServices'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'AzureActiveDirectoryDomainServices'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_EntraDS'
        Priority = '300'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'AzureMonitor'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_AzureMonitor'
        Priority = '305'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'Storage'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_Storage'
        Priority = '310'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'AzureActiveDirectory'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_MicrosoftEntraID'
        Priority = '315'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'AzureUpdateDelivery'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_AzureUpdateDelivery'
        Priority = '320'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'AzureFrontDoor.FirstParty'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_AzureFrontDoor'
        Priority = '325'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    },
    [PSCustomObject]@{
        Access = 'Allow'
        DestinationAddressPrefix = 'GuestAndHybridManagement'
        DestinationPortRange = '443'
        Direction = 'Outbound'
        Name = 'Allow_HTTPS_GuestAndHybridManagement'
        Priority = '330'
        Protocol = 'TCP'
        SourceAddressPrefix = '*'
        SourcePortRange = '*'
    }
)

$Configuration = Get-AzNetworkSecurityGroup `
    -ResourceGroupName $NetworkSecurityGroupResourceGroupName `
    -Name $NetworkSecurityGroupName

foreach ($Rule in $Rules)
{
    $Configuration | Add-AzNetworkSecurityRuleConfig `
        -Name $Rule.Name `
        -Access $Rule.Access `
        -Protocol $Rule.Protocol `
        -Direction $Rule.Direction `
        -Priority $Rule.Priority `
        -SourceAddressPrefix $Rule.SourceAddressPrefix `
        -SourcePortRange $Rule.SourcePortRange `
        -DestinationPortRange $Rule.DestinationPortRange `
        -DestinationAddressPrefix $Rule.DestinationAddressPrefix
}

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $Configuration