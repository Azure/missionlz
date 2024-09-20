param($Timer)

try
{
	[string]$BeginPeakTime = $env:BeginPeakTime
	[string]$EndPeakTime = $env:EndPeakTime
	[string]$EnvironmentName = $env:EnvironmentName
	[string]$HostPoolName = $env:HostPoolName
	[string]$HostPoolResourceGroupName = $env:HostPoolResourceGroupName
	[int]$LimitSecondsToForceLogOffUser = $env:LimitSecondsToForceLogOffUser
	[string]$LogOffMessageBody = $env:LogOffMessageBody
	[string]$LogOffMessageTitle = $env:LogOffMessageTitle
	[string]$MaintenanceTagName = $env:MaintenanceTagName
	[int]$MinimumNumberOfRDSH = $env:MinimumNumberOfRDSH
	[string]$ResourceManagerUrl = $env:ResourceManagerUrl
	[double]$SessionThresholdPerCPU = $env:SessionThresholdPerCPU
	[string]$SubscriptionId = $env:SubscriptionId
	[string]$TenantId = $env:TenantId
	[string]$TimeDifference = $env:TimeDifference
	[string[]]$DesiredRunningStates = @('Available', 'NeedsAssistance')
	[string[]]$TimeDiffHrsMin = "$($TimeDifference):0".Split(':')


	#region Functions
	function Get-LocalDateTime
    {
		return (Get-Date).ToUniversalTime().AddHours($TimeDiffHrsMin[0]).AddMinutes($TimeDiffHrsMin[1])
	}

	function Write-Log 
    {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $false)]
			[switch]$Err,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolName,

			[Parameter(Mandatory = $true)]
			[string]$Message,

			[Parameter(Mandatory = $false)]
			[switch]$Warn
		)

		[string]$MessageTimeStamp = (Get-LocalDateTime).ToString('yyyy-MM-dd HH:mm:ss')
		$Message = "[$($MyInvocation.ScriptLineNumber)] [$($HostPoolName)] $Message"
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

	function Set-nVMsToStartOrStop 
    {
		param (
			[Parameter(Mandatory = $true)]
			[string]$HostPoolName,

			[Parameter(Mandatory = $false)]
			[switch]$InPeakHours,

			[Parameter(Mandatory = $true)]
			[int]$MaxUserSessionsPerVM,
		
			[Parameter(Mandatory = $true)]
			[int]$nRunningCores,

			[Parameter(Mandatory = $true)]
			[int]$nRunningVMs,
			
			[Parameter(Mandatory = $true)]
			[int]$nUserSessions,

			[Parameter(Mandatory = $true)]
			[hashtable]$Res
		)

		# check if need to adjust min num of running session hosts required if the number of user sessions is close to the max allowed by the min num of running session hosts required
		[double]$MaxUserSessionsThreshold = 0.9
		[int]$MaxUserSessionsThresholdCapacity = [math]::Floor($MinimumNumberOfRDSH * $MaxUserSessionsPerVM * $MaxUserSessionsThreshold)
		if ($nUserSessions -gt $MaxUserSessionsThresholdCapacity)
        {
			$MinimumNumberOfRDSH = [math]::Ceiling($nUserSessions / ($MaxUserSessionsPerVM * $MaxUserSessionsThreshold))
			Write-Log -HostPoolName $HostPoolName -Message "Number of user sessions is more than $($MaxUserSessionsThreshold * 100) % of the max number of sessions allowed with minimum number of running session hosts required ($MaxUserSessionsThresholdCapacity). Adjusted minimum number of running session hosts required to $MinimumNumberOfRDSH"
		}

		# Check if minimum number of session hosts are running
		if ($nRunningVMs -lt $MinimumNumberOfRDSH)
        {
			$res.nVMsToStart = $MinimumNumberOfRDSH - $nRunningVMs
			Write-Log -HostPoolName $HostPoolName -Message "Number of running session host is less than minimum required. Need to start $($res.nVMsToStart) VMs"
		}
		
		if ($InPeakHours)
        {
			[double]$nUserSessionsPerCore = $nUserSessions / $nRunningCores
			# In peak hours: check if current capacity is meeting the user demands
			if ($nUserSessionsPerCore -gt $SessionThresholdPerCPU)
            {
				$res.nCoresToStart = [math]::Ceiling(($nUserSessions / $SessionThresholdPerCPU) - $nRunningCores)
				Write-Log -HostPoolName $HostPoolName -Message "[In peak hours] Number of user sessions per Core is more than the threshold. Need to start $($res.nCoresToStart) cores"
			}

			return
		}

		if ($nRunningVMs -gt $MinimumNumberOfRDSH)
        {
			# Calculate the number of session hosts to stop
			$res.nVMsToStop = $nRunningVMs - $MinimumNumberOfRDSH
			Write-Log -HostPoolName $HostPoolName -Message "[Off peak hours] Number of running session host is greater than minimum required. Need to stop $($res.nVMsToStop) VMs"
		}
	}

	function TryUpdateSessionHostDrainMode
    {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[bool]$AllowNewSession,

			[Parameter(Mandatory = $true)]
			[hashtable]$Header,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolName,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolResourceGroupName,

			[Parameter(Mandatory = $true)]
			[string]$ResourceManagerUrl,

			[Parameter(Mandatory = $true)]
			[string]$SessionHostName,

			[Parameter(Mandatory = $true)]
			[string]$SubscriptionId
		)
		Begin { }
		Process 
        {
			Write-Log -HostPoolName $HostPoolName -Message "Update session host '$SessionHostName' to set allow new sessions to $AllowNewSession"
			try 
			{
				$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts/' + $SessionHostName + '?api-version=2022-02-10-preview'
				Invoke-RestMethod -Headers $Header -Body (@{properties = @{allowNewSession = $AllowNewSession}} | ConvertTo-Json) -Method 'Patch' -Uri $Uri | Out-Null
			}
			catch
			{
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Failed to update the session host '$SessionHostName' to set allow new sessions to $($AllowNewSession): $($PSItem | Format-List -Force | Out-String)"
			}
		}
		End { }
	}

	function TryForceLogOffUser
    {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[hashtable]$Header,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolName,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolResourceGroupName,

			[Parameter(Mandatory = $true)]
			[string]$ResourceManagerUrl,

			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			$Session,

			[Parameter(Mandatory = $true)]
			[string]$SubscriptionId
		)
		Begin { }
		Process
        {
            [string[]]$Toks = $Session.Name.Split('/')
            [string]$SessionHostName = $Toks[1]
            [string]$SessionID = $Toks[-1]
            [string]$User = $Session.ActiveDirectoryUserName

			try 
			{
				Write-Log -HostPoolName $HostPoolName -Message "Force log off user: '$User', session ID: $SessionID"

				$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts/' + $SessionHostName + '/userSessions/' + $SessionID + '?api-version=2022-02-10-preview&force=True'
				Invoke-RestMethod -Headers $Header -Method 'Delete' -Uri $Uri | Out-Null
			}
			catch 
			{
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Failed to force log off user: '$User', session ID: $SessionID $($PSItem | Format-List -Force | Out-String)"
			}
		}
		End { }
	}

	function TryResetSessionHostDrainModeAndUserSessions
    {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[hashtable]$Header,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolName,

			[Parameter(Mandatory = $true)]
			[string]$HostPoolResourceGroupName,

			[Parameter(Mandatory = $true)]
			[string]$ResourceManagerUrl,

			[Parameter(Mandatory = $true)]
			[string]$SessionHostName,

			[Parameter(Mandatory = $true)]
			[int]$SessionHostSessions,

			[Parameter(Mandatory = $true)]
			[string]$SubscriptionId
		)
		Begin { }
		Process 
        {
			TryUpdateSessionHostDrainMode -AllowNewSession $true -Header $Header -HostPoolName $HostPoolName -HostPoolResourceGroupName $HostPoolResourceGroupName -ResourceManagerUrl $ResourceManagerUrl -SessionHostName $SessionHostName -SubscriptionId $SubscriptionId

			if ($SessionHostSessions -eq 0)
            {
				return
			}

			Write-Log -HostPoolName $HostPoolName -Warn -Message "Session host '$SessionHostName' still has $SessionHostSessions) sessions left behind in broker DB"

			Write-Log -HostPoolName $HostPoolName -Message "Get all user sessions from session host '$SessionHostName'"
			try 
			{
				$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts/' + $SessionHostName + '/userSessions?api-version=2022-02-10-preview'
				$UserSessions = Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri
			}
			catch 
			{
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Failed to retrieve user sessions of session host '$SessionHostName': $($PSItem | Format-List -Force | Out-String)"
				return
			}

			Write-Log -HostPoolName $HostPoolName -Message "Force log off $($UserSessions.Count) users on session host: '$SessionHostName'"
			$UserSessions | TryForceLogOffUser -Header $Header -HostPoolName $HostPoolName -HostPoolResourceGroupName $HostPoolResourceGroupName -ResourceManagerUrl $ResourceManagerUrl -SubscriptionId $SubscriptionId
		}
		End { }
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
    Write-Log -HostPoolName $HostPoolName -Message "Successfully authenticated with Azure using a managed identity"
	#endregion Azure Authentication


	#region validate host pool, validate / update HostPool load balancer type, ensure there is at least 1 session host, get num of user sessions
	# Validate and get host pool info
	$HostPool = $null
	try 
	{
		Write-Log -HostPoolName $HostPoolName -Message "Get host pool information"
		$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '?api-version=2022-02-10-preview'
		$HostPool = Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri

		if (!$HostPool) 
		{
			throw $HostPool
		}
	}
	catch 
	{
		throw [System.Exception]::new("Failed to get host pool info of '$HostPoolName' in resource group '$HostPoolResourceGroupName'. Ensure that you have entered the correct values", $PSItem.Exception)
	}

	# Ensure HostPool load balancer type is not persistent
	if ($HostPool.properties.loadBalancerType -ieq 'Persistent')
    {
		throw "HostPool '$HostPoolName' is configured with 'Persistent' load balancer type. Scaling tool only supports these load balancer types: BreadthFirst, DepthFirst"
	}

	Write-Log -HostPoolName $HostPoolName -Message 'Get session hosts'
	$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts?api-version=2022-02-10-preview'
	$SessionHosts = (Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri).value

	if (!$SessionHosts)
    {
		Write-Log -HostPoolName $HostPoolName -Message "There are no session hosts in the host pool '$HostPoolName'. Ensure that hostpool has session hosts"
		Write-Log -HostPoolName $HostPoolName -Message 'End'
		return
	}

	Write-Log -HostPoolName $HostPoolName -Message 'Get number of user sessions in host pool'
	$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/userSessions?api-version=2022-02-10-preview'
	[int]$nUserSessions = (Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri).value.Count

	# Set up breadth 1st load balacing type
	# Note: breadth 1st is enforced on AND off peak hours to simplify the things with scaling in the start/end of peak hours
	if (!$SkipUpdateLoadBalancerType -and $HostPool.properties.loadBalancerType -ine 'BreadthFirst')
    {
		Write-Log -HostPoolName $HostPoolName -Message "Update HostPool with 'BreadthFirst' load balancer type (current: '$($HostPool.properties.loadBalancerType)')"

		$Body = @{
			properties = @{
				loadBalancerType = 'BreadthFirst'
			}
		}
		$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '?api-version=2022-02-10-preview'
		$HostPool = Invoke-RestMethod -Headers $Header -Body $($Body | ConvertTo-Json) -Method 'Patch' -Uri $Uri
	}
	Write-Log -HostPoolName $HostPoolName -Message "Number of session hosts in the HostPool: $($SessionHosts.Count)"
	#endregion
	

	# region Peak Hours #
	# Convert local time, begin peak time & end peak time from UTC to local time
	$CurrentDateTime = Get-LocalDateTime
	$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

	# Adjust peak times to make sure begin peak time is always before end peak time
	if ($EndPeakDateTime -lt $BeginPeakDateTime)
    {
		if ($CurrentDateTime -lt $EndPeakDateTime)
        {
			$BeginPeakDateTime = $BeginPeakDateTime.AddDays(-1)
		}
		else
        {
			$EndPeakDateTime = $EndPeakDateTime.AddDays(1)
		}
	}

	Write-Log -HostPoolName $HostPoolName -Message "Using current time: $($CurrentDateTime.ToString('yyyy-MM-dd HH:mm:ss')), begin peak time: $($BeginPeakDateTime.ToString('yyyy-MM-dd HH:mm:ss')), end peak time: $($EndPeakDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"

	[bool]$InPeakHours = ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime)
	if ($InPeakHours)
    {
		Write-Log -HostPoolName $HostPoolName -Message 'In peak hours'
	}
	else
    {
		Write-Log -HostPoolName $HostPoolName -Message 'Off peak hours'
	}
	# endregion Peak Hours #


	#region get session hosts, VMs & user sessions info and compute workload
	# Note: session host is considered "running" if its running AND is in desired states AND allowing new sessions
	# Number of session hosts that are running, are in desired states and allowing new sessions
	[int]$nRunningVMs = 0
	# Number of cores that are running, are in desired states and allowing new sessions
	[int]$nRunningCores = 0
	# Array that contains all the virtual machine objects that are session hosts except the ones that are tagged for maintenance
	$VMs = @()
	# Object that contains the number of cores for each VM size SKU
	$VMSizeCores = @{}
	# Number of user sessions reported by each session host that is running, is in desired state and allowing new sessions
	[int]$nUserSessionsFromAllRunningVMs = 0

	# Populate all session hosts objects
	foreach ($SessionHost in $SessionHosts)
    {
		[string]$VirtualMachineResourceId = $SessionHost.properties.resourceId
		[string]$VirtualMachineName = $VirtualMachineResourceId.Split('/')[8]
		[string]$VirtualMachineResourceGroupName = $VirtualMachineResourceId.Split('/')[4]
		$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $VirtualMachineResourceGroupName + '/providers/Microsoft.Compute/virtualMachines/' + $VirtualMachineName + '?api-version=2024-03-01&$expand=instanceView'
		$VirtualMachine = Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri

		# Throw an error if the virtual machine for the session host does not exist
		if ($VirtualMachine.error)
		{
			throw "The virtual machine for session host '$VirtualMachineName' does not exist"
		}
		# Ignore session hosts tagged for maintenance or missing virtual machine
		elseif($VirtualMachine.tags.Keys -contains $MaintenanceTagName)
        {
			Write-Log -HostPoolName $HostPoolName -Message "VM '$VirtualMachineName' is in maintenance and will be ignored"
			continue
		}
		else 
		{
			$VMs += $VirtualMachine
		}

		$PowerState = $VirtualMachine.properties.instanceView.statuses[1].displayStatus
		Write-Log -HostPoolName $HostPoolName -Message "Session host: '$($VirtualMachineName)', power state: '$PowerState', status: '$($SessionHost.properties.status)', update state: '$($SessionHost.properties.updateState)', sessions: $($SessionHost.properties.sessions), allow new session: $($SessionHost.properties.allowNewSession)"
		
		# Get the number of cores for VM size SKU
		if (!$VMSizeCores.ContainsKey($VirtualMachine.properties.hardwareProfile.vmSize))
        {
			Write-Log -HostPoolName $HostPoolName -Message "Get VM sizes in $($VirtualMachine.location)"

			$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId + '/providers/Microsoft.Compute/locations/' + $VirtualMachine.location + '/vmSizes?api-version=2024-03-01'
			$VMSizes = (Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri).value

			foreach ($VMSize in $VMSizes)
            {
				if (!$VMSizeCores.ContainsKey($VMSize.name))
                {
					$VMSizeCores.Add($VMSize.name, $VMSize.numberOfCores)
				}
			}
		}

		if ($PowerState -ieq 'VM running')
        {
			if ($SessionHost.properties.status -notin $DesiredRunningStates)
            {
				Write-Log -HostPoolName $HostPoolName -Warn -Message 'VM is in running state but session host is not and so it will be ignored (this could be because the VM was just started and has not connected to broker yet)'
			}
			if (!$SessionHost.properties.allowNewSession)
            {
				Write-Log -HostPoolName $HostPoolName -Warn -Message 'VM is in running state but session host is not allowing new sessions and so it will be ignored'
			}

			if ($SessionHost.properties.status -in $DesiredRunningStates -and $SessionHost.properties.allowNewSession)
            {
				++$nRunningVMs
				$nRunningCores += $VMSizeCores[$VirtualMachine.properties.hardwareProfile.vmSize]
				$nUserSessionsFromAllRunningVMs += $SessionHost.properties.sessions
			}
		}
		else 
        {
			if ($SessionHost.properties.status -in $DesiredRunningStates)
            {
				Write-Log -HostPoolName $HostPoolName -Warn -Message "VM is not in running state but session host is (this could be because the VM was just stopped and broker doesn't know that yet)"
			}
		}
	}

	if ($nUserSessionsFromAllRunningVMs -ne $nUserSessions)
    {
		Write-Log -HostPoolName $HostPoolName -Warn -Message "Sum of user sessions reported by every running session host ($nUserSessionsFromAllRunningVMs) is not equal to the total number of user sessions reported by the host pool ($nUserSessions)"
	}


	if (!$nRunningCores)
    {
		$nRunningCores = 1
	}

	Write-Log -HostPoolName $HostPoolName -Message "Number of running session hosts: $nRunningVMs of total $($VMs.Count)"
	Write-Log -HostPoolName $HostPoolName -Message "Number of user sessions: $nUserSessions of total allowed $($nRunningVMs * $HostPool.properties.maxSessionLimit)"
	Write-Log -HostPoolName $HostPoolName -Message "Number of user sessions per Core: $($nUserSessions / $nRunningCores), threshold: $SessionThresholdPerCPU"
	Write-Log -HostPoolName $HostPoolName -Message "Minimum number of running session hosts required: $MinimumNumberOfRDSH"

	# Check if minimum num of running session hosts required is higher than max allowed
	if ($VMs.Count -le $MinimumNumberOfRDSH)
    {
		Write-Log -HostPoolName $HostPoolName -Warn -Message 'Minimum number of RDSH is set higher than or equal to total number of session hosts'
	}
	#endregion


	#region determine number of session hosts to start/stop if any
	# Now that we have all the info about the session hosts & their usage, figure how many session hosts to start/stop depending on in/off peak hours and the demand [Ops = operations to perform]
	$Ops = @{
		nVMsToStart   = 0
		nCoresToStart = 0
		nVMsToStop    = 0
	}

	Set-nVMsToStartOrStop -HostPoolName $HostPoolName -nRunningVMs $nRunningVMs -nRunningCores $nRunningCores -nUserSessions $nUserSessions -MaxUserSessionsPerVM $HostPool.properties.maxSessionLimit -InPeakHours:$InPeakHours -Res $Ops
	#endregion


	#region start any session hosts if need to
	# Check if we have any session hosts to start
	if ($Ops.nVMsToStart -or $Ops.nCoresToStart)
    {
		if ($nRunningVMs -eq $VMs.Count)
        {
			Write-Log -HostPoolName $HostPoolName -Message 'All session hosts are running'
			Write-Log -HostPoolName $HostPoolName -Message 'End'
			return
		}

		# Object that contains names of session hosts that will be started
		# $StartSessionHostFullNames = @{ }
		# Array that contains jobs of starting the session hosts
		[array]$StartedVMs = @()

		Write-Log -HostPoolName $HostPoolName -Message 'Find session hosts that are stopped and allowing new sessions'
		foreach ($SessionHost in $SessionHosts)
        {
			$VM = $VMs | Where-Object { $_.id -ieq $SessionHost.properties.resourceId }
			if (!$Ops.nVMsToStart -and !$Ops.nCoresToStart)
            {
				# Done with starting session hosts that needed to be
				break
			}
			if ($VM.properties.instanceView.statuses[1].displayStatus -ieq 'VM running')
            {
				continue
			}
			if ($SessionHost.properties.updateState -ine 'Succeeded')
            {
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Session host '$($VM.name)' may not be healthy"
			}

			if (!$SessionHost.properties.allowNewSession)
            {
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Session host '$($VM.name)' is not allowing new sessions and so it will not be started"
				continue
			}

			Write-Log -HostPoolName $HostPoolName -Message "Start session host '$($VM.name)'"

			$Uri = $ResourceManagerUrl + $VM.id.TrimStart('/') + '/start?api-version=2023-09-01'
			Invoke-RestMethod -Headers $Header -Method 'Post' -Uri $Uri | Out-Null
			$StartedVMs += $VM
				
			--$Ops.nVMsToStart
			if ($Ops.nVMsToStart -lt 0)
            {
				$Ops.nVMsToStart = 0
			}

			$Ops.nCoresToStart -= $VMSizeCores[$VM.properties.hardwareProfile.vmSize]
			if ($Ops.nCoresToStart -lt 0)
            {
				$Ops.nCoresToStart = 0
			}
		}

		# Check if there were enough number of session hosts to start
		if ($Ops.nVMsToStart -or $Ops.nCoresToStart)
        {
			Write-Log -HostPoolName $HostPoolName -Warn -Message "Not enough session hosts to start. Still need to start maximum of either $($Ops.nVMsToStart) VMs or $($Ops.nCoresToStart) cores"
		}

		# Wait for session hosts to start
		while($StartedVMs.Count -gt 0)
		{
			foreach($StartedVM in $StartedVMs)
			{
				$Uri = $ResourceManagerUrl + $StartedVM.id.TrimStart('/') + '?api-version=2024-03-01'
				$VMAgentStatus = (Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri).properties.instanceView.vmAgent
				if ($VMAgentStatus)
				{
					Write-Log -HostPoolName $HostPoolName -Message "Session host '$($StartedVM.name)' is running"
					$StartedVMs = $StartedVMs -ne $StartedVM
				}
			}
			Start-Sleep -Seconds 30
		}

		Write-Log -HostPoolName $HostPoolName -Message 'All session hosts have started'
		Write-Log -HostPoolName $HostPoolName -Message 'End'
		return
	}
	#endregion


	#region stop any session hosts if need to
	if (!$Ops.nVMsToStop)
    {
		Write-Log -HostPoolName $HostPoolName -Message 'No need to start/stop any session hosts'
		Write-Log -HostPoolName $HostPoolName -Message 'End'
		return
	}

	# Object that contains names of session hosts that will be stopped
	$VMsToStop = @()
	[array]$VMsToStopAfterLogOffTimeOut = @()

	Write-Log -HostPoolName $HostPoolName -Message 'Find session hosts that are running and allowing new sessions, sort them by number of user sessions'
	foreach ($SessionHost in ($SessionHosts | Where-Object { $_.properties.allowNewSession } | Sort-Object { $_.properties.sessions }))
    {
		$VM = $VMs | Where-Object { $_.id -ieq $SessionHost.properties.resourceId }
		if ($VM.properties.instanceView.statuses[1].displayStatus -ieq 'VM running')
		{
			if (!$Ops.nVMsToStop)
			{
				# Done with stopping session hosts that needed to be
				break
			}
			
			if ($SessionHost.properties.sessions -gt 0 -and !$LimitSecondsToForceLogOffUser)
			{
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Session host '$($VM.name)' has $($SessionHost.properties.sessions) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
				# Note: why break ? Because the list this loop iterates through is sorted by number of sessions, if it hits this, the rest of items in the loop will also hit this
				break
			}
			
			TryUpdateSessionHostDrainMode -AllowNewSession $false -Header $Header -HostPoolName $HostPoolName -HostPoolResourceGroupName $HostPoolResourceGroupName -ResourceManagerUrl $ResourceManagerUrl -SessionHostName $VM.name -SubscriptionId $SubscriptionId

			# Note: check if there were new user sessions since session host info was 1st fetched
			if ($SessionHost.properties.sessions -gt 0 -and !$LimitSecondsToForceLogOffUser)
			{
				Write-Log -HostPoolName $HostPoolName -Warn -Message "Session host '$($VM.name)' has $($SessionHost.properties.sessions) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
				TryUpdateSessionHostDrainMode -AllowNewSession $true -Header $Header -HostPoolName $HostPoolName -HostPoolResourceGroupName $HostPoolResourceGroupName -ResourceManagerUrl $ResourceManagerUrl -SessionHostName $VM.name -SubscriptionId $SubscriptionId 
				continue
			}

			if ($SessionHost.properties.sessions -gt 0)
			{
				Write-Log -HostPoolName $HostPoolName -Message "Get all user sessions from session host '$($VM.name)'"
				try 
				{
					$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts/' + $VM.name + '/userSessions?api-version=2022-02-10-preview'
					$UserSessions = Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri
				}
				catch
				{
					Write-Log -HostPoolName $HostPoolName -Warn -Message "Failed to retrieve user sessions of session host '$($VM.name)': $($PSItem | Format-List -Force | Out-String)"
				}

				Write-Log -HostPoolName $HostPoolName -Message "Send log off message to active user sessions on session host: '$($VM.name)'"
				foreach ($UserSession in $UserSessions)
				{
					if($UserSession.properties.sessionState -ine 'Active')
					{
						continue
					}

					[string]$SessionID = $UserSession.name.Split('/')[-1]
					[string]$User = $UserSession.properties.activeDirectoryUserName
					
					try 
					{
						Write-Log -HostPoolName $HostPoolName -Message "Send a log off message to user: '$User', session ID: $SessionID"

						$Uri = $ResourceManagerUrl + 'subscriptions/' + $SubscriptionId  + '/resourceGroups/' + $HostPoolResourceGroupName + '/providers/Microsoft.DesktopVirtualization/hostPools/' + $HostPoolName + '/sessionHosts/' + $VM.name + '/userSessions/' + $SessionID + '/sendMessage?api-version=2022-02-10-preview'
						Invoke-RestMethod -Headers $Header -Method 'Post' -Uri $Uri -Body (@{ 'messageTitle' = $LogOffMessageTitle; 'messageBody' = "$LogOffMessageBody You will be logged off in $LimitSecondsToForceLogOffUser seconds" } | ConvertTo-Json) | Out-Null
					}
					catch 
					{
						Write-Log -HostPoolName $HostPoolName -Warn -Message "Failed to send a log off message to user: '$User', session ID: $SessionID $($PSItem | Format-List -Force | Out-String)"
					}
				}
				$VMsToStopAfterLogOffTimeOut += $VM
			}
			else
			{
				Write-Log -HostPoolName $HostPoolName -Message "Stop session host '$($VM.name)'"
				$Uri = $ResourceManagerUrl + $VM.id.TrimStart('/') + '/deallocate?api-version=2023-09-01'
				Invoke-RestMethod -Headers $Header -Method 'Post' -Uri $Uri | Out-Null
				$VMsToStop += $VM
			}

			--$Ops.nVMsToStop
			if ($Ops.nVMsToStop -lt 0) {
				$Ops.nVMsToStop = 0
			}
		}
	}

	if ($VMsToStopAfterLogOffTimeOut)
    {
		Write-Log -HostPoolName $HostPoolName -Message "Wait $LimitSecondsToForceLogOffUser seconds for users to log off"

		Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

		Write-Log -HostPoolName $HostPoolName -Message "Force log off users and stop remaining $($VMsToStopAfterLogOffTimeOut.Count) session hosts"
		foreach ($VM in $VMsToStopAfterLogOffTimeOut)
        {
			$SessionHost = $SessionHosts | Where-Object { $_.properties.resourceId -ieq $VM.id }
			Write-Log -HostPoolName $HostPoolName -Message "Force log off $($SessionHost.sessions) users on session host: '$($VM.name)'"
			$VM.UserSessions | TryForceLogOffUser -Header $Header -HostPoolName $HostPoolName -HostPoolResourceGroupName $HostPoolResourceGroupName -ResourceManagerUrl $ResourceManagerUrl -SubscriptionId $SubscriptionId
			
			Write-Log -HostPoolName $HostPoolName -Message "Stop session host '$($VM.name)'"
			$Uri = $ResourceManagerUrl + $VM.id.TrimStart('/') + '/deallocate?api-version=2023-09-01'
			Invoke-RestMethod -Headers $Header -Method 'Post' -Uri $Uri | Out-Null
			$VMsToStop += $VM
		}
	}

	# Check if there were enough number of session hosts to stop
	if ($Ops.nVMsToStop)
    {
		Write-Log -HostPoolName $HostPoolName -Warn -Message "Not enough session hosts to stop. Still need to stop $($Ops.nVMsToStop) VMs"
	}

	# Wait for the session hosts to stop / deallocate
	Write-Log -HostPoolName $HostPoolName -Message "Wait for session hosts to stop / deallocate"
	while($VMsToStop.Count -gt 0)
	{
		foreach($VMToStop in $VMsToStop)
		{
			$Uri = $ResourceManagerUrl + $VMToStop.id.TrimStart('/') + '?$expand=instanceView&api-version=2024-03-01'
			$VMPowerState = (Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri).properties.instanceView.statuses[1].displayStatus
			if ($VMPowerState -eq 'VM deallocated')
			{
				Write-Log -HostPoolName $HostPoolName -Message "Session host '$($VMToStop.name)' is stopping"
				$SessionHost = $SessionHosts | Where-Object { $_.properties.resourceId -ieq $VMToStop.id }
				TryResetSessionHostDrainModeAndUserSessions -Header $Header -HostPoolName $HostPoolName -HostPoolResourceGroupName $HostPoolResourceGroupName -ResourceManagerUrl $ResourceManagerUrl -SessionHostName $VMToStop.name -SessionHostSessions $SessionHost.properties.sessions -SubscriptionId $SubscriptionId
				$VMsToStop = $VMsToStop -ne $VMToStop
			}
		}
		Start-Sleep -Seconds 30
	}

	Write-Log -HostPoolName $HostPoolName -Message 'All required session hosts have stopped.'
	Write-Log -HostPoolName $HostPoolName -Message 'End'
	return
	#endregion
}
catch 
{
	$ErrContainer = $PSItem
	# $ErrContainer = $_

	[string]$ErrMsg = $ErrContainer | Format-List -Force | Out-String
	$ErrMsg += "Version: $Version`n"

	if (Get-Command 'Write-Log' -ErrorAction:SilentlyContinue)
    {
		Write-Log -HostPoolName $HostPoolName -Err -Message $ErrMsg -ErrorAction:Continue
	}
	else
    {
		Write-Error $ErrMsg -ErrorAction:Continue
	}

	throw [System.Exception]::new($ErrMsg, $ErrContainer.Exception)
}