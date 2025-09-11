param(
    [string]$CloudSuffix,
    [string]$DomainName
)

# Variables
$ErrorActionPreference = "Stop"
$MicrosoftGraphEndpoint = "https://graph.microsoft." + $CloudSuffix

# Get an access token for Microsoft Graph using IMDS
$TokenResponse = Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Method 'GET' `
    -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $MicrosoftGraphEndpoint)
     
$AccessToken = $TokenResponse.access_token

$Headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Create a cloud sync configuration
$CloudProvisioningBody = @{
    displayName = "MyCloudSyncConfig"
    agentGroupName = "MyAgentGroup"
    domainName = $DomainName
    configuration = @{
        # Add your configuration details here
    }
} | ConvertTo-Json

Invoke-RestMethod `
    -Body $CloudProvisioningBody `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/onPremisesDirectorySynchronization/cloudProvisioning')


# Get the organization ID
$organizationId = (Get-MgOrganization).Id


# Enable tenant flags
$params = @{
	onPremisesSyncEnabled = $true
}
Update-MgBetaOrganization `
    -OrganizationId $organizationId 
    -BodyParameter $params

# Create the service principal
# TO DO: output the object ID for service principal
$ServicePrincipalObjectId = Invoke-RestMethod `
    -Body $(@{displayName = "$DomainName"} | ConvertTo-Json) `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/applicationTemplates/1a4721b3-e57f-4451-ae87-ef078703ec94/instantiate')

# Enable user and group provisioning
Invoke-RestMethod `
    -Body $(@{templateId = "AD2AADProvisioning"} | ConvertTo-Json) `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs')

# Enable password hash synchronization
Invoke-RestMethod `
    -Body $(@{templateId = "AD2AADPasswordHash"} | ConvertTo-Json) `
    -Headers $Headers `
    -Method 'POST' `
    -Uri  $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs')


# Update the targeted domain
# ObjectId: bbbbbbbb-1111-2222-3333-cccccccccccc
# AppId: 00001111-aaaa-2222-bbbb-3333cccc4444
# DisplayName: testApp
$MetadataBody = @{

} | ConvertTo-Json

$MetadataUri = $MicrosoftGraphEndpoint + "/beta/servicePrincipals/[SERVICE_PRINCIPAL_ID]/synchronization/metadata"

Invoke-RestMethod `
    -Body $MetadataBody `
    -Headers $Headers `
    -Method 'PUT' `
    -Uri $MetadataUri
    

# PUT – https://graph.microsoft.com/beta/servicePrincipals/[SERVICE_PRINCIPAL_ID]/synchronization/secrets

# Enable both PHS and sync tenant flags { key: "AppKey", value: "{"appKeyScenario":"AD2AADPasswordHash"}" }

# Enable only sync tenant flag (don't turn on PHS) { key: "AppKey", value: "{"appKeyScenario":"AD2AADProvisioning"}" }

$RequestBody = @{
    "value" = @(
        @{
            key = "Domain"
            value = @{ "domain" = "ad2aadTest.com" }
        }
    )
}

# Enable Sync password hashes on configuration blade

# GET –https://graph.microsoft.com/beta/servicePrincipals/[SERVICE_PRINCIPAL_ID]/synchronization/jobs/ [AD2AADProvisioningJobId]/schema

<# {
"defaultValue": null,
"exportMissingReferences": false,
"flowBehavior": "FlowWhenChanged",
"flowType": "Always",
"matchingPriority": 0,
"targetAttributeName": "CredentialData",
"source": {
"expression": "[PasswordHash]",
"name": "PasswordHash",
"type": "Attribute",
"parameters": []
} #>

