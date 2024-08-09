param(

    [parameter(Mandatory)]
    [string]$ApplicationGroupReferences,

    [parameter(Mandatory)]
    [string]$Environment,

    [parameter(Mandatory)]
    [string]$ResourceGroupName,

    [parameter(Mandatory)]
    [string]$SubscriptionId,

    [parameter(Mandatory)]
    [string]$TenantId,

    [parameter(Mandatory)]
    [string]$UserAssignedIdentityClientId,

    [parameter(Mandatory)]
    [string]$WorkspaceName

)

$ErrorActionPreference = 'Stop'

try
{
    Connect-AzAccount `
        -Environment $Environment `
        -Tenant $TenantId `
        -Subscription $SubscriptionId `
        -Identity `
        -AccountId $UserAssignedIdentityClientId | Out-Null

    $OldAppGroupReferences = (Get-AzWvdWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName).ApplicationGroupReference
    [array]$NewAppGroupReferences = $ApplicationGroupReferences.Replace("'",'"') | ConvertFrom-Json
    $OldAppGroupReferences = $OldAppGroupReferences -ne $NewAppGroupReferences
    $CombinedApplicationGroupReferences = $OldAppGroupReferences + $NewAppGroupReferences

    Update-AzWvdWorkspace `
        -ResourceGroupName $ResourceGroupName `
        -Name $WorkspaceName `
        -ApplicationGroupReference $CombinedApplicationGroupReferences | Out-Null

    Disconnect-AzAccount | Out-Null

    $Output = [pscustomobject][ordered]@{
        workspaceName = $WorkspaceName
    }
    $JsonOutput = $Output | ConvertTo-Json
    return $JsonOutput
}
catch 
{
    Write-Host $_ | Select-Object *
    throw
}