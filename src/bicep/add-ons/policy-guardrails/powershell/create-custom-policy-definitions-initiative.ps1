#parameter and values
$emailSecurityContact = "brsteel@microsoft.com"
$logAnalyticsResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-operations-network-va-test/providers/Microsoft.OperationalInsights/workspaces/bws-log-operations-va-test"
$hubVnetResourceId = "/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/bws-rg-hub-network-va-test/providers/Microsoft.Network/virtualNetworks/bws-vnet-hub-va-test"
$folderScope = "Global"
$vulnerabilityAssessmentsEmail = @("brsteel@microsoft.com")
$vulnerabilityAssessmentsStorageID = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-operations-network-va-test/providers/Microsoft.Storage/storageAccounts/5bdj25z4mllp6"
$hubRegion = "usgovvirginia"
$hubRgName = "bws-rg-hub-network-va-test"
$ddosName = "bws-ddos-va-test"

# Define the directory containing the guard rail policy definition JSON files
$policyDefinitionsDirectory = ".\src\bicep\add-ons\policy-guardrails\powershell\$($folderScope)"

# Define the management group ID the policy intiative and definitions will be linked to
$managementGroupId = "DoDIaCManagementGroup"

# Define the policy set definition properties
$policySetDisplayName = "Test $($folderScope) Guardrails Initiative"
$policySetName = "Test$($folderScope)GuardrailsInitiative"
$policySetDescription = "A set of policies to manage the $($folderScope) configurations."
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
            "policyType" = $policyJson.properties.policyType
            "mode" = $policyJson.properties.mode
            "metadata" = @{
                "version" = $policyJson.properties.metadata.version
            }
            "parameters" = $policyJson.properties.parameters
            "policyRule" = $policyJson.properties.policyRule
        }
    }

    # Add the emailSecurityContact parameter if the policy definition requires it
    if ($policyJson.name -eq "Deploy-ASC-SecurityContacts-enterprise") {
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

    if ($policyJson.name -eq "Deploy-Sql-vulnerabilityAssessments") {
        $policyDefinition.properties.parameters.vulnerabilityAssessmentsEmail = @{
            "type" = "Array"
            "defaultvalue" = $vulnerabilityAssessmentsEmail
        }
        $policyDefinition.properties.parameters.vulnerabilityAssessmentsStorageID = @{
            "type" = "String"
            "defaultvalue" = $vulnerabilityAssessmentsStorageID
        }
    }

    if ($policyJson.name -eq "Deploy-DDoSProtection") {
        $policyDefinition.properties.parameters.rgName = @{
            "type" = "String"
            "defaultvalue" = $hubRgName
        }
        $policyDefinition.properties.parameters.ddosRegion = @{
            "type" = "String"
            "defaultvalue" = $hubRegion
        }
        $policyDefinition.properties.parameters.ddosName = @{
            "type" = "String"
            "defaultvalue" = $ddosName
        }
    }

    $policyDefinitionJson = $policyDefinition | ConvertTo-Json -Depth 20

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

