/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param enableBuildAutomation bool
param imageVirtualMachineName string
param location string = resourceGroup().location
param mlzTags object
param tags object
param userAssignedIdentityClientId string
param virtualMachineName string

resource imageVirtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: imageVirtualMachineName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource removeVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  parent: virtualMachine
  name: 'removeVirtualMachine'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  properties: {
    treatFailureAsDeploymentFailure: false
    asyncExecution: enableBuildAutomation ? false : true
    parameters: [
      {
        name: 'EnableBuildAutomation'
        value: string(enableBuildAutomation)
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'ImageVmResourceId'
        value: imageVirtualMachine.id
      }
      {
        name: 'ManagementVmResourceId'
        value: virtualMachine.id
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
    ]
    source: {
      script: '''
        param(
            [Parameter(Mandatory=$false)]
            [string]$EnableBuildAutomation,

            [Parameter(Mandatory=$true)]
            [string]$ResourceManagerUri,

            [Parameter(Mandatory=$true)]
            [string]$UserAssignedIdentityClientId,

            [Parameter(Mandatory=$true)]
            [string]$ImageVmResourceId,

            [Parameter(Mandatory=$true)]
            [string]$ManagementVmResourceId
        )

        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'

        Try {
            # Fix the resource manager URI since only AzureCloud contains a trailing slash
            $ResourceManagerUriFixed = if($ResourceManagerUri[-1] -eq '/'){$ResourceManagerUri.Substring(0,$ResourceManagerUri.Length - 1)} else {$ResourceManagerUri}

            # Get an access token for Azure resources
            $AzureManagementAccessToken = (Invoke-RestMethod `
                -Headers @{Metadata="true"} `
                -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

            # Set header for Azure Management API
            $AzureManagementHeader = @{
                'Content-Type'='application/json'
                'Authorization'='Bearer ' + $AzureManagementAccessToken
            }

            # Delete Image VM
            Invoke-RestMethod -Headers $AzureManagementHeader -Method 'DELETE' -Uri $($ResourceManagerUriFixed + $ImageVmResourceId + '?api-version=2024-03-01')
            if($EnableBuildAutomation -eq 'false') {
              # Wait 20 secs to make sure run command takes at least 20 secs to prevent failure.
              Start-Sleep -Seconds 20
              Invoke-RestMethod -Headers $AzureManagementHeader -Method 'DELETE' -Uri $($ResourceManagerUriFixed + $ManagementVmResourceId + '?api-version=2024-03-01')
            }
        }
        catch {
            throw
        }
      '''
    }
  }
}
