param($Timer)

try
{
	[string]$FileShareName = $env:FileShareName
	[string]$ResourceGroupName = $env:ResourceGroupName
	[string]$ResourceManagerUrl = $env:ResourceManagerUrl
	[string]$StorageSuffix = $env:StorageSuffix
	[string]$SubscriptionId = $env:SubscriptionId

	$ErrorActionPreference = 'Stop'
	$WarningPreference = 'SilentlyContinue'

	#region Functions
	function Write-Log 
    {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $false)]
			[switch]$Err,

			[Parameter(Mandatory = $true)]
			[string]$Message,

			[Parameter(Mandatory = $true)]
			[string]$ResourceName,

			[Parameter(Mandatory = $false)]
			[switch]$Warn
		)

		[string]$MessageTimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
		$Message = "[$($MyInvocation.ScriptLineNumber)] [$($ResourceName)] $Message"
		[string]$WriteMessage = "[$($MessageTimeStamp)] $Message"

		if ($Err)
        {
			Write-Error $WriteMessage
			$Message = "ERROR: $Message"
		}
		elseif ($Warn)
        {
			Write-Warning $WriteMessage
			$Message = "WARN: $Message"
		}
		else 
        {
			Write-Output $WriteMessage
		}
	}
	#endregion Functions

	# Note: https://stackoverflow.com/questions/41674518/powershell-setting-security-protocol-to-tls-1-2
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


	#region Azure Authentication
    $AccessToken = $null
    try
    {
		$TokenAuthURI = $env:IDENTITY_ENDPOINT + '?resource=' + $ResourceManagerUrl + '&api-version=2019-08-01'
		$TokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $TokenAuthURI
		$AccessToken = $TokenResponse.access_token
		$Header = @{
			'Content-Type'='application/json'
			'Authorization'='Bearer ' + $AccessToken
		}
    }
    catch
    {
        throw [System.Exception]::new('Failed to authenticate Azure with application ID, tenant ID, subscription ID', $PSItem.Exception)
    }
    Write-Log -ResourceName "$SubscriptionId" -Message "Successfully authenticated with Azure using a managed identity"
	#endregion Azure Authentication

	# Get storage accounts
	$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.Storage/storageAccounts?api-version=2023-05-01'
	$StorageAccountNames = (Invoke-RestMethod -Headers $Header -Method 'GET' -Uri $Uri).value.name

	foreach($StorageAccountName in $StorageAccountNames)
	{
		$ShareUpdateUri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/fileServices/default/shares/' + $FileShareName + '?api-version=2023-05-01'

		# Get file share info
		$ShareGetUri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/fileServices/default/shares/' + $FileShareName + '?api-version=2023-05-01&$expand=stats'
		$PFS = (Invoke-RestMethod -Headers $Header -Method 'GET' -Uri $ShareGetUri).properties

		# Set variables for provisioned capacity and used capacity
		$ProvisionedCapacity = $PFS.shareQuota
		$UsedCapacity = $PFS.ShareUsageBytes
		Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Capacity: $($ProvisionedCapacity)GB"
		Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Usage: $([math]::Round($UsedCapacity/1GB, 0))GB"

		# GB Based Scaling
		# No scaling if no usage
		if($UsedCapacity -eq 0)
		{
			Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Usage is 0GB. No Changes."
		}
		# Slow scaling up to 500GB
		# Increases share quota by 100GB if less than 50GB remains on the share
		# This allows time for an AVD Stamp to be rolled out 
		elseif ($ProvisionedCapacity -lt 500)
		{
			if (($ProvisionedCapacity - ($UsedCapacity / ([Math]::Pow(2,30)))) -lt 50) {
				Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Usage has surpassed the Share Quota remaining threshold of 50GB. Increasing the file share quota by 100GB." 
				$Quota = $ProvisionedCapacity + 100
				Invoke-RestMethod `
					-Body (@{properties = @{shareQuota = $Quota}} | ConvertTo-Json) `
					-Headers $Header `
					-Method 'PATCH' `
					-Uri $ShareUpdateUri | Out-Null
				Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "New Capacity: $($Quota)GB"
			}
			else {
				Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Usage is below Share Quota remaining threshold of 50GB. No Changes."
			}
		}
		# Aggressive scaling
		# Increases share quota by 500GB if less than 500GB remains on the share
		# This ensures plenty of space is available during mass onboarding
		else 
		{
			if (($ProvisionedCapacity - ($UsedCapacity / ([Math]::Pow(2,30)))) -lt 500) {
				Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Usage has surpassed the Share Quota remaining threshold of 500GB. Increasing the file share quota by 500GB." 
				$Quota = $ProvisionedCapacity + 500
				Invoke-RestMethod `
					-Body (@{properties = @{shareQuota = $Quota}} | ConvertTo-Json) `
					-Headers $Header `
					-Method 'PATCH' `
					-Uri $ShareUpdateUri | Out-Null
				Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "New Capacity: $($Quota)GB"
			}
			else {
				Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Message "Share Usage is below Share Quota remaining threshold of 500GB. No Changes."
			}
		}
	}
}
catch 
{
	$ErrContainer = $PSItem
	# $ErrContainer = $_

	[string]$ErrMsg = $ErrContainer | Format-List -Force | Out-String
	$ErrMsg += "Version: $Version`n"

	if (Get-Command 'Write-Log' -ErrorAction:SilentlyContinue)
    {
		Write-Log -ResourceName "$StorageAccountName/$FileShareName" -Err -Message $ErrMsg -ErrorAction:Continue
	}
	else
    {
		Write-Error $ErrMsg -ErrorAction:Continue
	}

	throw [System.Exception]::new($ErrMsg, $ErrContainer.Exception)
}