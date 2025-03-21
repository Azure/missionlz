[CmdletBinding()]
param (
    [string]$RootFolderPath,
    [string]$Location
)

# Iterate through the folder structure
$managementGroups = Get-ChildItem -Path $RootFolderPath -Directory

foreach ($mg in $managementGroups) {
    Write-Output "Processing management group: $($mg.Name)"
    $policySets = Get-ChildItem -Path $mg.FullName -Directory

    foreach ($ps in $policySets) {
        Write-Output "Processing policy set: $($ps.Name)"
        $policyDefinitions = @()
        $policyParameters = @{}
        $policySetParameters = @{}

        # Get policy definition files (excluding parameter files)
        $policyFiles = Get-ChildItem -Path $ps.FullName -Filter *.json | Where-Object { $_.Name -notlike '*-parameters.json' }

        # Get parameter files
        $parameterFiles = Get-ChildItem -Path $ps.FullName -Filter *-parameters.json

        foreach ($pf in $parameterFiles) {
            Write-Output "Processing parameter file: $($pf.FullName)"
            $policyParameter = Get-Content -Path $pf.FullName -Raw | ConvertFrom-Json
            $policyFileName = [System.IO.Path]::GetFileNameWithoutExtension($pf.Name)
            $policyFileName = $policyFileName -replace '-parameters$', ''
            if (-not $policyParameters.ContainsKey($policyFileName)) {
                $policyParameters[$policyFileName] = @{}
            }
            foreach ($key in $policyParameter.PSObject.Properties.Name) {
                $policyParameters[$policyFileName][$key] = @{
                    "type" = $policyParameter.$key.type
                    "metadata" = $policyParameter.$key.metadata
                    "value" = $policyParameter.$key.value
                }
                # Add to policy set parameters
                if (-not $policySetParameters.ContainsKey("$policyFileName-$key")) {
                    $policySetParameters["$policyFileName-$key"] = @{
                        "type" = $policyParameter.$key.type
                        "metadata" = $policyParameter.$key.metadata
                    }
                }
            }
        }

        foreach ($pd in $policyFiles) {
            Write-Output "Processing policy definition file: $($pd.FullName)"
            $policyDefinition = Get-Content -Path $pd.FullName -Raw | ConvertFrom-Json
            $policyFileName = [System.IO.Path]::GetFileNameWithoutExtension($pd.Name)
            # Create the policy definition object
            Write-Output "Creating policy definition: $policyFileName"
            $policyDefinitionObj = New-AzPolicyDefinition -Name $policyFileName -DisplayName $policyDefinition.properties.displayName -Policy $pd.FullName -ManagementGroupName $mg.Name
            Write-Output "Policy definition created: $($policyDefinitionObj | ConvertTo-Json -Depth 10)"
            
            # Initialize the parameters hashtable
            $parameters = @{}

            # Check if there are parameters for this policy definition
            if ($policyParameters.ContainsKey($policyFileName)) {
                foreach ($paramKey in $policyParameters[$policyFileName].Keys) {
                    $parameters[$paramKey] = @{
                        "value" = "[parameters('$policyFileName-$paramKey')]"
                    }
                }
            }

            $policyDefinitionEntry = @{
                "policyDefinitionId" = $policyDefinitionObj.Id
                "parameters" = $parameters
            }
            $policyDefinitions += $policyDefinitionEntry
        }

        # Create a new policy set using the folder name containing the policy files
        $policySetName = $ps.Name
        $policySetDisplayName = "Policy Set for $($ps.Name)"
        $policySetDescription = "Description of the policy set for $($ps.Name)"
        $policySetDefinitions = @()

        foreach ($policyDefinition in $policyDefinitions) {
            $policySetDefinitions += @{
                "policyDefinitionId" = $policyDefinition.policyDefinitionId
                "parameters" = $policyDefinition.parameters
            }
        }

        # Convert policy set definitions to JSON string
        $policySetDefinitionsJson = $policySetDefinitions | ConvertTo-Json -Depth 10

        # Convert policy set parameters to JSON string
        $policySetParametersJson = $policySetParameters | ConvertTo-Json -Depth 10

        # Debugging output to verify parameter types
        Write-Output "Policy Set Parameters JSON: $policySetParametersJson"
        Write-Output "Policy Set Definitions JSON: $policySetDefinitionsJson"

        # Create the policy set definition with parameters
        $policySet = New-AzPolicySetDefinition -Name $policySetName -DisplayName $policySetDisplayName -Description $policySetDescription -PolicyDefinition $policySetDefinitionsJson -Parameter $policySetParametersJson -ManagementGroupName $mg.Name
        Write-Output "Policy set created: $($policySet | ConvertTo-Json -Depth 10)"

        # Prepare the policy parameters for the assignment
        $policyAssignmentParameters = @{}
        foreach ($policyDefinition in $policyDefinitions) {
            $policyFileName = [System.IO.Path]::GetFileNameWithoutExtension($policyDefinition.policyDefinitionId)
            if ($policyParameters.ContainsKey($policyFileName)) {
                foreach ($paramKey in $policyParameters[$policyFileName].Keys) {
                    $policyAssignmentParameters["$policyFileName-$paramKey"] = @{
                        "value" = $policyParameters[$policyFileName][$paramKey].value
                    }
                }
            }
        }

        # Convert policy assignment parameters to JSON string
        $policyAssignmentParametersJson = $policyAssignmentParameters | ConvertTo-Json -Depth 10

        # Shorten the assignment name to ensure it does not exceed 24 characters
        $maxPolicySetNameLength = 24 - "Assign".Length
        if ($policySetName.Length -gt $maxPolicySetNameLength) {
            $policySetName = $policySetName.Substring(0, $maxPolicySetNameLength)
        }
        $assignmentName = "${policySetName}Assign"

        Write-Output "Assigning policy set to management group: $($mg.Name)"
        $scope = "/providers/Microsoft.Management/managementGroups/$($mg.Name)"

        # Create the policy assignment with a system-assigned managed identity
        $policyAssignment = New-AzPolicyAssignment -Name $assignmentName -Scope $scope -PolicySetDefinition $policySet.Id -PolicyParameter $policyAssignmentParametersJson -IdentityType SystemAssigned -Location $Location
        Write-Output "Policy set assigned: $($policyAssignment | ConvertTo-Json -Depth 10)"

        # Extract roleDefinitionIds from the policy set definition
        $roleDefinitionIds = @()
        foreach ($policyDefinition in $policySet.PolicyDefinition) {
            $policyDef = Get-AzPolicyDefinition -Id $policyDefinition.policyDefinitionId
            if ($null -ne $policyDef.PolicyRule.then.details) {
                $roleDefinitionIds += $policyDef.PolicyRule.then.details.roleDefinitionIds
            }
        }
        $roleDefinitionIds = $roleDefinitionIds | Select-Object -Unique

        # Assign necessary roles to the managed identity
        foreach ($roleDefinitionId in $roleDefinitionIds) {
            $roleDefinitionGuid = [Guid]::Parse($roleDefinitionId.Substring($roleDefinitionId.LastIndexOf('/') + 1))
            $existingRoleAssignment = Get-AzRoleAssignment -ObjectId $policyAssignment.IdentityPrincipalId -RoleDefinitionId $roleDefinitionGuid -Scope $scope -ErrorAction SilentlyContinue
            if (-not $existingRoleAssignment) {
                New-AzRoleAssignment -ObjectId $policyAssignment.IdentityPrincipalId -RoleDefinitionId $roleDefinitionGuid -Scope $scope
                Write-Output "Role assigned: $roleDefinitionGuid to $($policyAssignment.IdentityPrincipalId)"
            } else {
                Write-Output "Role assignment already exists: $roleDefinitionGuid to $($policyAssignment.IdentityPrincipalId)"
            }
        }
    }
}