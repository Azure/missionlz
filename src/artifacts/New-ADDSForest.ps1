param(
    [Parameter(Mandatory = $true)]
    [string]$AdminPassword,

    [Parameter(Mandatory = $true)]
    [string]$AdminUsername,

    [Parameter(Mandatory = $true)]
    [int]$DomainControllerNumber,

    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $true)]
    [string]$DNSForwarder,

    [Parameter(Mandatory = $true)]
    [string]$SafeModeAdminPassword
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

$SecureAdminPassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
$DomainCredential = New-Object System.Management.Automation.PSCredential ("$($DomainName.Split('.')[0])\$($AdminUsername)", $SecureAdminPassword)
$SecureSafeModePassword = ConvertTo-SecureString -String $SafeModeAdminPassword -AsPlainText -Force

# Initialize, partition, and format data disk
$DiskNumber = (Get-Disk | Where-Object { $_.PartitionStyle -eq 'Raw' }).Number
if ($DiskNumber) {
    Initialize-Disk -Number $DiskNumber -PartitionStyle 'GPT' | Out-Null
    New-Partition -DiskNumber $DiskNumber -DriveLetter 'F' -UseMaximumSize | Out-Null
    Format-Volume -DriveLetter 'F' -FileSystem 'NTFS' -NewFileSystemLabel 'ADDS' -Confirm:$false | Out-Null
}

# Install AD DS role
$FeatureInstalled = (Get-WindowsFeature -Name 'AD-Domain-Services').Installed
if ( -not $FeatureInstalled ) {
    Install-WindowsFeature -Name 'AD-Domain-Services' -IncludeManagementTools | Out-Null
}

# Import ADDSDeployment module
Import-Module -Name 'ADDSDeployment'

# Create new forest
if ( $DomainControllerNumber -eq 1 ) {
    try {
        Get-ADForest | Out-Null
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Install-ADDSForest `
            -DatabasePath 'F:\NTDS' `
            -DomainMode 'WinThreshold' `
            -DomainName $DomainName `
            -DomainNetbiosName $DomainName.Split('.')[0] `
            -Force `
            -ForestMode 'WinThreshold' `
            -InstallDNS `
            -LogPath 'F:\Logs' `
            -NoRebootOnCompletion `
            -SafeModeAdministratorPassword $SecureSafeModePassword `
            -SysvolPath 'F:\SYSVOL' | Out-Null
    }
}

# Add domain controller to the forest
if ( $DomainControllerNumber -eq 2 ) {
    # Join to the domain, if not already joined
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    if ( -not $ComputerSystem.PartOfDomain) {
        $joined = $false
        while (-not $joined) {
            try {
                Add-Computer -DomainName $DomainName -Credential $DomainCredential -ErrorAction Stop

                $joined = $true
            }
            catch {
                Start-Sleep -Seconds 15
            }
        }
    }

    # Loop until an Active Directory domain controller is returned
    while ( -not (Get-ADDomainController -Discover -ErrorAction 'SilentlyContinue') ) {
        Start-Sleep -Seconds 10
    }

    [array]$ExistingDomainControllers = (Get-ADDomainController).Name
    if ( $ExistingDomainControllers -notcontains $env:COMPUTERNAME ) {
        # Wait for secure channel using nltest directly in condition
        do {
            nltest /sc_verify:$DomainName 2>$null
            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0) {
              Start-Sleep -Seconds 5
            }
        } while ($exitCode -ne 0)

        Install-ADDSDomainController `
            -Credential $DomainCredential `
            -DatabasePath 'F:\NTDS' `
            -DomainName $DomainName `
            -Force `
            -InstallDNS `
            -LogPath 'F:\Logs' `
            -NoRebootOnCompletion `
            -SafeModeAdministratorPassword $SecureSafeModePassword `
            -SysvolPath 'F:\SYSVOL' | Out-Null
    }
}

# Set DNS server Listening Address to IPv4 address
$DNSServerSettings = Get-DnsServerSetting -All
$IPv4Address = $DNSServerSettings.ListeningIpAddress | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' }
$DNSServerSettings.ListeningIpAddress = $IPv4Address
$DNSServerSettings | Set-DnsServerSetting | Out-Null

# Set DNS forwarder on the DNS server
$ExistingDNSForwarder = (Get-DnsServerForwarder -ErrorAction 'SilentlyContinue').IPAddress
if ( $ExistingDNSForwarder -ne $DNSForwarder ) {
    Set-DnsServerForwarder `
        -IPAddress $DNSForwarder `
        -UseRootHint:$true | Out-Null
}
Restart-Computer -Force

