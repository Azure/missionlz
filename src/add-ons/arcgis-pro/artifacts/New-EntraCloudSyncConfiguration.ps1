param(
    [Parameter(Mandatory = $true)]
    [string]$CloudSuffix,

    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$UserAssignedManagedIdentityClientId
)

# Variables
$ErrorActionPreference = "Stop"
$MicrosoftGraphEndpoint = "https://graph.microsoft." + $CloudSuffix

# Get an access token for Microsoft Graph using IMDS
$AccessToken = (Invoke-RestMethod `
    -Headers @{Metadata="true"} `
    -Method 'GET' `
    -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $MicrosoftGraphEndpoint + '&client_id=' + $UserAssignedManagedIdentityClientId)).access_token

# Set headers for Microsoft Graph API calls
$Headers = @{
    Authorization = "Bearer $AccessToken"
    "Content-Type" = "application/json"
}

# Enable tenant flags for synchronization
# Required Permissions: Organization.ReadWrite.All
# https://learn.microsoft.com/graph/api/organization-update?view=graph-rest-beta&tabs=http
Invoke-RestMethod `
    -Body '{"onPremisesSyncEnabled":true}' `
    -Headers $Headers `
    -Method 'PATCH' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/organization/' + $TenantId)

# Create the service principal
# Required Permissions: Application.ReadWrite.All
# https://learn.microsoft.com/graph/api/applicationtemplate-instantiate?view=graph-rest-beta&tabs=http
$ServicePrincipalObjectId = (Invoke-RestMethod `
    -Body $('{"displayName":"' + $DomainName + '"}') `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/applicationTemplates/1a4721b3-e57f-4451-ae87-ef078703ec94/instantiate')).servicePrincipal.objectId

# Update the targeted domain 
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-serviceprincipal-put-synchronization?view=graph-rest-beta&tabs=http
# $AppKeyValue = '{\"appKeyScenario\":\"AD2AADPasswordHash\"}'
# $DomainValue = '{\"domain\":\"' + $DomainName + '\"}'
# Invoke-RestMethod `
#     -Body $(@{value = @(@{key = "AppKey"; value = "$AppKeyValue"} , @{key = "Domain"; value = "$DomainValue"})} | ConvertTo-Json -Depth 3 -Compress) `
#     -Headers $Headers `
#     -Method 'PUT' `
#     -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/secrets')
Invoke-RestMethod `
    -Body $('{"value":[{"key":"AppKey","value":"{\\\"appKeyScenario\\\":\\\"AD2AADPasswordHash\\\"}"},{"key":"Domain","value":"{\\\"domain\\\":\\\"' + $DomainName + '\\\"}"}]}') `
    -Headers $Headers `
    -Method 'PUT' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/secrets')

Start-Sleep -Seconds 30

# Enable user and group provisioning
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-synchronization-post-jobs?view=graph-rest-beta&tabs=http
$ProvisioningJob = Invoke-RestMethod `
    -Body '{"templateId":"AD2AADProvisioning"}' `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs')

# Enable password hash synchronization
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-synchronization-post-jobs?view=graph-rest-beta&tabs=http
$PasswordHashJob = Invoke-RestMethod `
    -Body '{"templateId":"AD2AADPasswordHash"}' `
    -Headers $Headers `
    -Method 'POST' `
    -Uri  $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs')

# Get the provisioning job schema
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-synchronizationschema-get?view=graph-rest-beta&tabs=http
$ProvisioningJobSchema = (Invoke-WebRequest `
    -Headers $Headers `
    -Method 'GET' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs/' + $ProvisioningJob.id + '/schema') `
    -UseBasicParsing).Content

$UpdateProvisioningJobSchema1 = $ProvisioningJobSchema.Replace('"name":"Provision Active Directory users","sourceObjectName":"user","targetObjectName":"User","attributeMappings":[', '"name":"Provision Active Directory users","sourceObjectName":"user","targetObjectName":"User","attributeMappings":[{"defaultValue":null,"exportMissingReferences":false,"flowBehavior":"FlowWhenChanged","flowType":"Always","matchingPriority":0,"targetAttributeName":"CredentialData","source":{"expression":"[PasswordHash]","name":"PasswordHash","type":"Attribute","parameters":[]}},')
$UpdatedProvisioningJobSchema = $UpdateProvisioningJobSchema1.Replace('"name":"Provision Active Directory inetOrgPersons","sourceObjectName":"inetOrgPerson","targetObjectName":"User","attributeMappings":[', '"name":"Provision Active Directory inetOrgPersons","sourceObjectName":"inetOrgPerson","targetObjectName":"User","attributeMappings":[{"defaultValue":null,"exportMissingReferences":false,"flowBehavior":"FlowWhenChanged","flowType":"Always","matchingPriority":0,"targetAttributeName":"CredentialData","source":{"expression":"[PasswordHash]","name":"PasswordHash","type":"Attribute","parameters":[]}},')

# Update the provisioning job schema
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-synchronizationschema-update?view=graph-rest-beta&tabs=http
Invoke-RestMethod `
    -Body $UpdatedProvisioningJobSchema `
    -Headers $Headers `
    -Method 'PUT' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs/' + $ProvisioningJob.id + '/schema')

# Discover the schema directory for the provisioning synchronization job
# This has always thrown a 500 error and not how to incorpate it. The portal uses this API when deploying a new configuration.

# $DirectoryId = ((Invoke-RestMethod `
#     -Headers $Headers `
#     -Method 'GET' `
#     -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs/' + $ProvisioningJob.id + '/schema')).directories | Where-Object {$_.name -eq 'Active Directory'}).id

# Invoke-RestMethod `
#     -Headers $Headers `
#     -Method 'POST' `
#     -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs/' + $ProvisioningJob.id + '/schema/directories/' + $($ProvisioningSchema.directories | Where-Object {$_.name -eq 'Active Directory'}).id + '/discover')

Start-Sleep -Seconds 30

# Start the provisioning synchronization jobs
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-synchronizationjob-start?view=graph-rest-beta&tabs=http
Invoke-RestMethod `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs/' + $ProvisioningJob.id + '/start')

# Start the password hash synchronization jobs
# Required Permissions: Synchronization.ReadWrite.All
# https://learn.microsoft.com/graph/api/synchronization-synchronizationjob-start?view=graph-rest-beta&tabs=http
Invoke-RestMethod `
    -Headers $Headers `
    -Method 'POST' `
    -Uri $($MicrosoftGraphEndpoint + '/beta/servicePrincipals/' + $ServicePrincipalObjectId + '/synchronization/jobs/' + $PasswordHashJob.id + '/start')