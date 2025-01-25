$json = Get-Content -Raw "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\policy-guardrails\test\Initiative_v1.json" | ConvertFrom-Json
$policies = $json.properties.policyDefinitions | ConvertTo-Json -Depth 10
$policyGroups = $json.properties.policyDefinitionGroups | ConvertTo-Json -Depth 10
$params = $json.properties.parameters | ConvertTo-Json -Depth 10
$displayName = $json.properties.displayName 
$description = $json.properties.description
 
$metadata = $json.properties.metadata
Write-Output $metadata.parameterScopes

$metaData = $metadata | ConvertTo-Json -Depth 10

# Create each policy definition
foreach ($policy in $json.properties.policyDefinitions) {
    $policyDefinition = @{
        "properties" = @{
            "displayName" = $policy.policyDefinitionReferenceId
            "policyType" = "Custom"
            "mode" = "All"
            "metadata" = @{
                "version" = $policy.definitionVersion
            }
            "parameters" = $policy.parameters
        }
    }
    $policyDefinitionJson = $policyDefinition | ConvertTo-Json -Depth 10
    New-AzPolicyDefinition -Name $policy.policyDefinitionReferenceId -Policy $policyDefinitionJson
}

New-AzPolicySetDefinition -Name $displayName -Description $description -Parameter "$params" -PolicyDefinition "$policies" -GroupDefinition "$policyGroups" -Metadata "$metadata" -