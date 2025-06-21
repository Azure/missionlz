param(
    [string]$Domain
)

# Get Ethernet Connections
$NetworkInterfaceCards = Get-DnsClient | Where-Object -Property 'InterfaceAlias' -Match 'Ethernet'

# Add Suffix To Each Ethernet Connection
foreach($NetworkInterfaceCard in $NetworkInterfaceCards) 
{
    Set-DnsClient -ConnectionSpecificSuffix $Domain -InterfaceIndex $NetworkInterfaceCard.InterfaceIndex -confirm:$false
}