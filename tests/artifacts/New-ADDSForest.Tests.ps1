<#
    Behavioral tests for src/artifacts/New-ADDSForest.ps1

    New-ADDSForest.ps1 is heavily Windows-specific (Get-Disk, Get-WindowsFeature,
    the ADDSDeployment module, DNS server cmdlets, Restart-Computer). None of those
    commands exist on the Linux CI runner or macOS, so this test uses the
    stub-and-invoke pattern: define no-op stubs for the absent commands, mock them,
    then invoke the real script (via &) with zero edits to the script. Coverage of
    this script is intentionally thin (honest-baseline goal, FR-002); the assertions
    still verify real observable behavior on the primary-domain-controller path.
#>

BeforeAll {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    $script:ScriptPath = Join-Path $RepoRoot 'src' 'artifacts' 'New-ADDSForest.ps1'

    # Stubs for Windows-only commands that are absent on the CI/macOS runner so
    # Pester can mock them. Declared with the parameters the script actually uses.
    function Get-Disk { }
    function Initialize-Disk { }
    function New-Partition { }
    function Format-Volume { }
    function Get-WindowsFeature { param([string]$Name) }
    function Install-WindowsFeature { param([string]$Name, [switch]$IncludeManagementTools) }
    function Get-ADForest { }
    function Get-DnsServerSetting { param([switch]$All) }
    function Set-DnsServerSetting { }
    function Get-DnsServerForwarder { }
    function Set-DnsServerForwarder { param([string[]]$IPAddress, [switch]$UseRootHint) }
    function Restart-Computer { param([switch]$Force) }

    $script:AddsArgs = @{
        AdminPassword         = 'P@ssw0rd!Admin1'
        AdminUsername         = 'adminuser'
        DomainControllerNumber = 1
        DomainName            = 'contoso.local'
        DNSForwarder          = '168.63.129.16'
        SafeModeAdminPassword = 'P@ssw0rd!Safe1'
    }
}

Describe 'New-ADDSForest (primary domain controller path)' {

    BeforeEach {
        Mock Get-Disk { }                                             # no raw data disk -> disk block skipped
        Mock Get-WindowsFeature { [pscustomobject]@{ Installed = $true } }
        Mock Import-Module { }                                        # ADDSDeployment not present
        Mock Get-ADForest { }                                         # forest "exists" -> Install-ADDSForest not called
        Mock Get-DnsServerSetting { [pscustomobject]@{ ListeningIpAddress = @('10.0.0.4') } }
        Mock Set-DnsServerSetting { }
        Mock Get-DnsServerForwarder { [pscustomobject]@{ IPAddress = '8.8.4.4' } }
        Mock Set-DnsServerForwarder { }
        Mock Restart-Computer { }
    }

    It 'checks whether the forest already exists' {
        & $ScriptPath @AddsArgs
        Should -Invoke Get-ADForest -Times 1 -Exactly
    }

    It 'configures the DNS forwarder passed to the script' {
        & $ScriptPath @AddsArgs
        Should -Invoke Set-DnsServerForwarder -Times 1 -Exactly -ParameterFilter {
            $IPAddress -contains '168.63.129.16'
        }
    }

    It 'restarts the computer to complete promotion' {
        & $ScriptPath @AddsArgs
        Should -Invoke Restart-Computer -Times 1 -Exactly
    }
}
