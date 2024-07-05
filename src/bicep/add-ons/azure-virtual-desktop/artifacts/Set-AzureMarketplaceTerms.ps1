[CmdletBinding()]
param (

    [Parameter(Mandatory)]
    [String]$ImageOffer,

    [Parameter(Mandatory)]
    [String]$ImagePublisher,

    [Parameter(Mandatory)]
    [String]$ImageSku
)

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

try 
{
   # Accept Terms for Image Usage
    $Terms = Get-AzMarketplaceTerms -Publisher $ImagePublisher -Product $ImageOffer -Name $ImageSku -ErrorAction 'SilentlyContinue'
    if(!($Terms.Accepted))
    {
        Set-AzMarketplaceTerms `
            -Publisher $ImagePublisher `
            -Product $ImageOffer `
            -Name $ImageSku `
            -Accept | Out-Null
    }
    Write-Log -Message "Set the Azure Marketplace terms for $($ImagePublisher):$($ImageOffer):$($ImageSku)" -Type 'INFO'
}
catch
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}