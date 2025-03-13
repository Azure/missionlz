# Define parameters
param (
    [string]$ManagementGroupName = "applications"
)

# Get all custom policy definitions in the specified management group
$customPolicyDefinitions = Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName | Where-Object { $_.PolicyType -eq 'Custom' }

# Iterate through each custom policy definition and delete it
foreach ($policyDefinition in $customPolicyDefinitions) {
    Write-Output "Deleting policy definition: $($policyDefinition.DisplayName)"
    Remove-AzPolicyDefinition -Id $policyDefinition.Id -Force
    Write-Output "Deleted policy definition: $($policyDefinition.DisplayName)"
}

Write-Output "All custom policy definitions in management group '$ManagementGroupName' have been deleted."