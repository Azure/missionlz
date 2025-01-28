# Define the management group ID
$managementGroupId = "DoDIaCManagementGroup"

# Get all policy definitions for the specified management group
$policyDefinitions = Get-AzPolicyDefinition -ManagementGroupName $managementGroupId

# Filter out the custom policy definitions
$customPolicyDefinitions = @()
foreach ($policyDefinition in $policyDefinitions) {
    if ($policyDefinition.policyType -eq "Custom") {
        $customPolicyDefinitions += $policyDefinition
    }
}

# Remove each custom policy definition
foreach ($policyDefinition in $customPolicyDefinitions) {
    Write-Host "Removing policy definition: $($policyDefinition.Name)"
    Remove-AzPolicyDefinition -Name $policyDefinition.Name -ManagementGroupName $managementGroupId -Force
}