/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param imageVirtualMachineName string
param resourceGroupName string
param location string
param mlzTags object
param tags object
param userAssignedIdentityClientId string
param virtualMachineName string

resource imageVirtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: imageVirtualMachineName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource restartVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'restartVirtualMachine'
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'VmResourceId'
        value: imageVirtualMachine.id
      }
    ]
    source: {
      script: '''
        param(
            [Parameter(Mandatory=$true)]
            [string]$ResourceManagerUri,

            [Parameter(Mandatory=$true)]
            [string]$UserAssignedIdentityClientId,

            [Parameter(Mandatory=$true)]
            [string]$VmResourceId
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
            
            # Restart the VM
            $null = Invoke-RestMethod -Headers $AzureManagementHeader -Method 'Post' -Uri $($ResourceManagerUriFixed + $VmResourceId + '/restart?api-version=2024-03-01')
            $lastProvisioningState = ""
            $VmStatus = Invoke-RestMethod -Headers $AzureManagementHeader -Method 'Get' -Uri $($ResourceManagerUriFixed + $VmResourceId + '/instanceView?api-version=2024-03-01')
            $provisioningState = ($VMStatus.statuses | Where-Object {$_.code -like 'PowerState*'}).code
            While ($provisioningState -ne "PowerState/running") {
                $lastProvisioningState = $provisioningState
                Start-Sleep -Seconds 5
                $VmStatus = Invoke-RestMethod -Headers $AzureManagementHeader -Method 'Get' -Uri $($ResourceManagerUriFixed + $VmResourceId + '/instanceView?api-version=2024-03-01')
                $provisioningState = ($VMStatus.statuses | Where-Object {$_.code -like 'PowerState*'}).code
            }   
        }
        catch {
            throw
        }
      '''
    }
  }
}
