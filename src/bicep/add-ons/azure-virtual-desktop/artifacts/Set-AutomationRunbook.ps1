[Cmdletbinding()]
Param (

    [parameter(Mandatory)]
    [string]
    $AutomationAccountName,

    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $ResourceGroupName,

    [parameter(Mandatory)]
    [string]
    $RunbookFileName,

    [parameter(Mandatory)]
    [string]
    $SubscriptionId,

    [parameter(Mandatory)]
    [string]
    $TenantId,

    [parameter(Mandatory)]
    [string]
    $UserAssignedIdentityClientId
    
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try 
{
    Connect-AzAccount `
        -Environment $Environment `
        -Tenant $TenantId `
        -Subscription $SubscriptionId `
        -Identity `
        -AccountId $UserAssignedIdentityClientId | Out-Null
    
    
    Import-AzAutomationRunbook `
        -Name $RunbookFileName.Replace('.ps1','') `
        -Path $RunbookFileName `
        -Type 'PowerShell' `
        -AutomationAccountName $AutomationAccountName `
        -ResourceGroupName $ResourceGroupName `
        -Published `
        -Force | Out-Null
    
    $Output = [pscustomobject][ordered]@{
        runbook = $RunBookName
    }

    Disconnect-AzAccount | Out-Null
    
    $JsonOutput = $Output | ConvertTo-Json
    return $JsonOutput  
}
catch 
{
    Write-Host $_ | Select-Object *
    throw  
}
