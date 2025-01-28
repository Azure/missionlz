#parameter and values
$emailSecurityContact = "brsteel@microsoft.com"
$logAnalyticsResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-operations-network-va-test/providers/Microsoft.OperationalInsights/workspaces/bws-log-operations-va-test"
$hubVnetResourceId = "/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/bws-rg-hub-network-va-test/providers/Microsoft.Network/virtualNetworks/bws-vnet-hub-va-test"

# Define the directory containing the guard rail policy definition JSON files
$policyDefinitionsDirectory = "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\policy-guardrails\test\potential-policy-definitions"

# Define the management group ID the policy intiative and definitions will be linked to
$managementGroupId = "operations_and_security"

# Define the policy set definition properties
$policySetDisplayName = "Test Guardrails Initiative"
$policySetName = "TestGuardrailsInitiative"
$policySetDescription = "A set of policies to manage the enterprise configurations."
$policySetMetadata = @{
    "category" = "All"
    "version" = "1.0.0"
}

# Initialize an array to hold the policy definitions
$policyDefinitions = @()

# Get all JSON files in the policy definitions directory
$policyFiles = Get-ChildItem -Path $policyDefinitionsDirectory -Filter *.json

# Loop through each policy definition file and create the policy definition in Azure
foreach ($policyFile in $policyFiles) {
    # Read the policy definition JSON file
    $policyJson = Get-Content -Raw -Path $policyFile.FullName | ConvertFrom-Json

    # Create the policy definitions in Azure
    $policyDefinition = @{
        "properties" = @{
            "displayName" = $policyJson.properties.displayName
            "policyType" = "Custom"
            "mode" = "All"
            "metadata" = @{
                "version" = $policyJson.properties.metadata.version
            }
            "parameters" = $policyJson.properties.parameters
            "policyRule" = $policyJson.properties.policyRule
        }
    }

    # Add the emailSecurityContact parameter if the policy definition requires it
    if ($policyJson.name -eq "Deploy-ASC-SecurityContacts") {
        $policyDefinition.properties.parameters.emailSecurityContact = @{
            "type" = "String"
            "defaultvalue" = $emailSecurityContact
        }
    }

    if ($policyJson.name -eq "Deploy-ActivityLogs-to-LA-workspace") {
        $policyDefinition.properties.parameters.logAnalytics = @{
            "type" = "String"
            "defaultvalue" = $logAnalyticsResourceId
        }
    }

    if ($policyJson.name -eq "Deny-VNET-Peering-To-Non-Approved-VNETs") {
        $policyDefinition.properties.parameters.logAnalytics = @{
            "type" = "String"
            "defaultvalue" = $hubVnetResourceId
        }
    }
    Deny-VNET-Peering-To-Non-Approved-VNETs

    $policyDefinitionJson = $policyDefinition | ConvertTo-Json -Depth 10
    Write-Host "Creating policy definition $($policyJson.name)"
    New-AzPolicyDefinition -Name $policyJson.name -Policy $policyDefinitionJson -ManagementGroupName $managementGroupId > $null

    # Add the policy definition to the policy definitions array for connecting into the policy set definition
    $policyDefinitions += @{
        "policyDefinitionId" = "/providers/Microsoft.Management/managementGroups/$managementGroupId/providers/Microsoft.Authorization/policyDefinitions/$($policyJson.name)"
    }
}

# Convert the policy definitions and metadata to JSON
$policyDefinitionsJson = $policyDefinitions | ConvertTo-Json -Depth 10
$policySetMetadataJson = $policySetMetadata | ConvertTo-Json -Depth 10

# Create the policy set definition (policy initiative)
$policySetDefinition = @{
    "name" = $policySetName
    "displayName" = $policySetDisplayName
    "description" = $policySetDescription
    "metadata" = $policySetMetadataJson
    "policyDefinition" = $policyDefinitionsJson
    "managementGroupName" = $managementGroupId
}

# Create the policy set definition in Azure
New-AzPolicySetDefinition @policySetDefinition

