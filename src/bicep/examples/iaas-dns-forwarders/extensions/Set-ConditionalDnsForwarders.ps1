# Script to set Windows DNS Server Conditional DNS Forwarders
[CmdletBinding()]
param (
    [Parameter(Position = 0,
        HelpMessage = "JSON Array of DNS Conditional Forwarders to configure",
        Mandatory = $true)]
    [String]
    $ConditionalDnsForwardersJSON
)

# Convert from JSON
$conditionalDnsForwarders = $ConditionalDnsForwardersJSON | ConvertFrom-Json
if (!($conditionalDnsForwarders)) { throw("Could not convert from JSON:`r`n" + $ConditionalDnsForwardersJSON) }

# Loop through conditional forwarders
foreach ($conditionalDnsForwarder in $conditionalDnsForwarders) {
    # Get existing zone
    $existingZone = Get-DnsServerZone -Name $conditionalDnsForwarder.Name -ErrorAction:SilentlyContinue
    if ($existingZone) {Write-Output ("Found existing zone for " + [char]34 + $conditionalDnsForwarder.Name + [char]34 + "...")}
    # Create conditional forwarder
    else {
        Add-DnsServerConditionalForwarderZone -Name $conditionalDnsForwarder.Name -MasterServers $conditionalDnsForwarder.Forwarders
        # Verify forwarder was created
        $fwdGet = Get-DnsServerZone -Name $conditionalDnsForwarder.Name -ErrorAction:SilentlyContinue
        if ($fwdGet) {
            Write-Output ([char]34 + $conditionalDnsForwarder.Name + [char]34 + " was successfully created...")
        }   
        else{throw("Could not create Conditional DNS Forwarder for name " + [char]34 + $conditionalDnsForwarder.Name + [char]34 + ".")}
    }
}