# before running script, verify the folderScope is where the policy definitions are located in JSON format
# before running script, verify the managementGroupId is the management group ID the policy initiative and definitions will be linked to
# before running script, verify the policy parameter values are set properly, if that policy definition is used

#policy definition parameters and values, see lower in script to see the policy definitions they are used in
#if the policy definition that requires the parameter is not used, the parameter value will not be used, so leave it in the script for future reference with no value
$emailSecurityContactenterprise = "brsteel@microsoft.com"
$logAnalyticsResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/mlz-rg-operations-network-va-dev/providers/Microsoft.OperationalInsights/workspaces/mlz-log-operations-va-dev"
$hubVnetResourceId = "/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/mlz-rg-hub-network-va-dev/providers/Microsoft.Network/virtualNetworks/mlz-vnet-hub-va-dev"
$vulnerabilityAssessmentsEmail = @("brsteel@microsoft.com")
$vulnerabilityAssessmentsStorageID = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/mlz-rg-operations-network-va-dev/providers/Microsoft.Storage/storageAccounts/lceg2vlqmwmjq"
$hubRegion = "usgovvirginia"
$hubRgName = "mlz-vnet-hub-va-dev"

#name ddos protection plan
$ddosName = "mlz-ddos-va-test"

# Define the expected next hop IP address for the Audit-Route-Table-For-Specific-Route policy definition
$nextHopIpAddress = "10.0.128.4"
# Define the exempt route table names parameter value
$exemptRouteTableNames = @("mlz-rt-hub-va-dev")

#script variables

# Define the folder scope where the policy definitions are located, it will define part of the policy initiative name that is created
$folderScope = "Global"

# Define the directory containing the guard rail policy definition JSON file.   folder structure should map to intiative
$policyDefinitionsDirectory = ".\src\bicep\add-ons\policy-guardrails\powershell\$($folderScope)"

# Define the management group ID the policy intiative and definitions will be linked to
# could also be mapped to folder scope name, but not necessary
$managementGroupId = "DoDIaCManagementGroup"

# Define the policy set definition properties
# assumes all policy definitions cross all categories, if not, adjust the category value for the intiative to match the policies
$policySetDisplayName = "Test $($folderScope) Guardrails Initiative"
$policySetName = "Test$($folderScope)GuardrailsInitiative"
$policySetDescription = "A set of policies to manage the $($folderScope) configurations."
$policySetMetadata = @{
    "category" = "All"
    "version" = "1.0.0"
}


# script work
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

    # some specific policy definitions require additional parameters, here is where they are added as "defaultvalue"
    # possible to do this in other ways, such as a parameters.json file for these specific json policies that is retreived if exist, or a powershell included script separate from this main script
    # Add the emailSecurityContact parameter if the policy definition requires it
    if ($policyJson.name -eq "Deploy-ASC-SecurityContacts-enterprise") {
        $policyDefinition.properties.parameters.emailSecurityContact = @{
            "type" = "String"
            "defaultvalue" = $emailSecurityContactenterprise
        }
    }

    if ($policyJson.name -eq "Deploy-ActivityLogs-to-LA-workspace") {
        $policyDefinition.properties.parameters.logAnalytics = @{
            "type" = "String"
            "defaultvalue" = $logAnalyticsResourceId
        }
    }

    if ($policyJson.name -like "Deploy-Diagnostics-*") {
        $policyDefinition.properties.parameters.logAnalytics = @{
            "type" = "String"
            "defaultvalue" = $logAnalyticsResourceId
        }
    }

    if ($policyJson.name -eq "Deny-VNET-Peering-To-Non-Approved-VNETs") {
        $policyDefinition.properties.parameters.allowedVnets = @{
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

    # Add the allowed routes parameter to the policy definition
    if ($policyJson.name -eq "Audit-Route-Table-For-Default-Route") {
        $policyDefinition.properties.parameters.nextHopIpAddress = @{
            "type" = "String"
            "defaultValue" = $nextHopIpAddress
        }
        $policyDefinition.properties.parameters.exemptRouteTableNames = @{
            "type" = "Array"
            "defaultValue" = $exemptRouteTableNames
        }
    }

    #convert powershell hashtable to JSON for the definition to be created
    $policyDefinitionJson = $policyDefinition | ConvertTo-Json -Depth 20

    # Create the policy definition in Azure
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

# Create the policy set definition (policy initiative) with all the policy definitions included
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
