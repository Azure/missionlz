$json = Get-Content -Raw 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\policy-guardrails\test\Initiative_v1.json' | ConvertFrom-Json
$policies = $json.properties.policyDefinitions | ConvertTo-Json -Depth 10
$policyGroups = $json.properties.policyDefinitionGroups | ConvertTo-Json -Depth 10
$params = $json.properties.parameters | ConvertTo-Json -Depth 10
$displayName = $json.properties.displayName 
$description = $json.properties.description
 
$metadata = $json.properties.metadata 
$paramScopeOverride = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24"
$metadata.parameterScopes."nsgRegion : Configure network security groups to enable traffic analytics_1" = $paramScopeOverride
 
$metaData = $metadata | ConvertTo-Json -Depth 10
 
New-AzPolicySetDefinition -Name $displayName -Description $description -Parameter "$params" -PolicyDefinition "$policies" -GroupDefinition "$policyGroups" -Metadata "$metadata"