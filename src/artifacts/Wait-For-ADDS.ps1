param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $true)]
    [string]$FirstDcIp,

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSeconds = 900,

    [Parameter(Mandatory = $false)]
    [int]$SleepSeconds = 15
)

$ErrorActionPreference = 'Stop'
$end = (Get-Date).AddSeconds($TimeoutSeconds)

Write-Host "Waiting for AD DS readiness on $FirstDcIp for domain $DomainName (timeout: $TimeoutSeconds s)"

function Test-AdReady {
    param([string]$Dom,[string]$DcIp)
    try {
        # LDAP port open
        $ldap = Test-NetConnection -ComputerName $DcIp -Port 389 -InformationLevel Quiet
        if(-not $ldap){ return $false }

        # DNS A record resolves via first DC
        $a = Resolve-DnsName -Name $Dom -Server $DcIp -ErrorAction SilentlyContinue
        if(-not $a){ return $false }

        # SRV for LDAP _ldap._tcp.dc._msdcs.<domain>
        $srvName = "_ldap._tcp.dc._msdcs.$Dom"
        $srv = Resolve-DnsName -Name $srvName -Type SRV -Server $DcIp -ErrorAction SilentlyContinue
        if(-not $srv){ return $false }
        return $true
    }
    catch { return $false }
}

while((Get-Date) -lt $end){
    if(Test-AdReady -Dom $DomainName -DcIp $FirstDcIp){
        Write-Host "AD DS is ready."
        exit 0
    }
    Start-Sleep -Seconds $SleepSeconds
}

throw "Timed out waiting for AD DS readiness on $FirstDcIp for domain $DomainName"
