# Define parameters
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ManagementGroupName
)

# Get all custom policy definitions in the specified management group
$customPolicyDefinitions = Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName -PolicyType 'Custom'

# Initialize a counter for deleted policy definitions
$deletedCount = 0

# Iterate through each custom policy definition and delete it
foreach ($policyDefinition in $customPolicyDefinitions) {
    Write-Output "Deleting policy definition: $($policyDefinition.DisplayName)"
    Remove-AzPolicyDefinition -Id $policyDefinition.Id -Force
    Write-Output "Deleted policy definition: $($policyDefinition.DisplayName)"
    $deletedCount++
}

Write-Output "All $deletedCount custom policy definitions in management group '$ManagementGroupName' have been deleted."