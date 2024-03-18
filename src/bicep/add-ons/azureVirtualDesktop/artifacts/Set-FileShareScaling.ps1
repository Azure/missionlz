[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]$Environment,

	[Parameter(Mandatory)]
	[string]$FileShareName,

	[Parameter(Mandatory)]
	[string]$ResourceGroupName,

	[Parameter(Mandatory)]
	[string]$StorageAccountName,

	[Parameter(Mandatory)]
	[string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'

# Connect to Azure and Import Az Module
Import-Module -Name 'Az.Accounts'
Import-Module -Name 'Az.Storage'
Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId -Identity | Out-Null

# Get file share
$PFS = Get-AzRmStorageShare -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -Name $FileShareName -GetShareUsage

# Get provisioned capacity and used capacity
$ProvisionedCapacity = $PFS.QuotaGiB
$UsedCapacity = $PFS.ShareUsageBytes
Write-Output "[$StorageAccountName] [$FileShareName] Share Capacity: $($ProvisionedCapacity)GB"
Write-Output "[$StorageAccountName] [$FileShareName] Share Usage: $([math]::Round($UsedCapacity/1GB, 0))GB"

# Get storage account
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName

# GB Based Scaling
# No scaling if no usage
if($UsedCapacity -eq 0)
{
	Write-Output "[$StorageAccountName] [$FileShareName] Share Usage is 0GB. No Changes."
}
# Slow scaling up to 500GB
# Increases share quota by 100GB if less than 50GB remains on the share
# This allows time for an AVD Stamp to be rolled out 
elseif ($ProvisionedCapacity -lt 500)
{
	if (($ProvisionedCapacity - ($UsedCapacity / ([Math]::Pow(2,30)))) -lt 50) {
		Write-Output "[$StorageAccountName] [$FileShareName] Share Usage has surpassed the Share Quota remaining threshold of 50GB. Increasing the file share quota by 100GB." 
		$Quota = $ProvisionedCapacity + 100
		Update-AzRmStorageShare -StorageAccount $StorageAccount -Name $FileShareName -QuotaGiB $Quota | Out-Null
		Write-Output "[$StorageAccountName] [$FileShareName] New Capacity: $($Quota)GB"
	}
	else {
		Write-Output "[$StorageAccountName] [$FileShareName] Share Usage is below Share Quota remaining threshold of 50GB. No Changes."
	}
}
# Aggressive scaling
# Increases share quota by 500GB if less than 500GB remains on the share
# This ensures plenty of space is available during mass onboarding
else 
{
	if (($ProvisionedCapacity - ($UsedCapacity / ([Math]::Pow(2,30)))) -lt 500) {
		Write-Output "[$StorageAccountName] [$FileShareName] Share Usage has surpassed the Share Quota remaining threshold of 500GB. Increasing the file share quota by 500GB." 
		$Quota = $ProvisionedCapacity + 500
		Update-AzRmStorageShare -StorageAccount $StorageAccount -Name $FileShareName -QuotaGiB $Quota | Out-Null
		Write-Output "[$StorageAccountName] [$FileShareName] New Capacity: $($Quota)GB"
	}
	else {
		Write-Output "[$StorageAccountName] [$FileShareName] Share Usage is below Share Quota remaining threshold of 500GB. No Changes."
	}
}