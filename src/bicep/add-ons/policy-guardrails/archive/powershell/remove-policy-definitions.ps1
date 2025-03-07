# if your initiative is alread assigned, you must remove assignment first
# delete the intiative after removal of assignment in the portal in the definitions view of the policy
# this script will then remove all definitions attached to the specified management group, regardless of where they came from
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