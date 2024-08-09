param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceManagerUri,

    [Parameter(Mandatory=$true)]
    [array]$RunCommands,

    [Parameter(Mandatory=$true)]
    [string]$UserAssignedIdentityClientId,


    [Parameter(Mandatory=$true)]
    [string]$VmResourceId   
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Try {
    # Fix the resource manager URI since only AzureCloud contains a trailing slash
    $ResourceManagerUriFixed = if($ResourceManagerUri[-1] -eq '/'){$ResourceManagerUri.Substring(0,$ResourceManagerUri.Length - 1)} else {$ResourceManagerUri}

    # Get an access token for Azure resources
    $AzureManagementAccessToken = (Invoke-RestMethod `
        -Headers @{Metadata="true"} `
        -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

    # Set header for Azure Management API
    $AzureManagementHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $AzureManagementAccessToken
    }

    ForEach($RunCommand in $RunCommands) {
       Invoke-RestMethod `
        -Headers $AzureManagementHeader `
        -Method 'Delete' `
        -Uri $($ResourceManagerUriFixed + $VmResourceId + '/runCommands/' + $RunCommand + '?api-version=2024-03-01')
    }
}
catch {
    throw
}