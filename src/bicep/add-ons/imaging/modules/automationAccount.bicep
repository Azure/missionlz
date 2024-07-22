/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param arcGisProInstaller string
param actionGroupName string
param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryImageResourceId string
param computeGalleryResourceId string
param containerName string
param customizations array
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param distributionGroup string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableBuildAutomation bool
param excludeFromLatest bool
param hybridUseBenefit bool
param imageDefinitionName string
param imageMajorVersion int
param imagePatchVersion int
param imageVirtualMachineName string
param installAccess bool
param installArcGisPro bool
param installExcel bool
param installOneDrive bool
param installOneNote bool
param installOutlook bool
param installPowerPoint bool
param installProject bool
param installPublisher bool
param installSkypeForBusiness bool
param installTeams bool
param installUpdates bool
param installVirtualDesktopOptimizationTool bool
param installVisio bool
param installWord bool
param keyVaultName string
param jobScheduleName string = newGuid()
param location string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param mlzTags object
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param resourceGroupName string
param sourceImageType string
param storageAccountResourceId string
param subnetResourceId string
param tags object
param teamsInstaller string
param templateSpecResourceId string
param time string = utcNow()
param timeZone string
param updateService string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineSize string
param wsusServer string

var parameters = {
  arcGisProInstaller: arcGisProInstaller
  computeGalleryImageResourceId: computeGalleryImageResourceId
  computeGalleryResourceId: computeGalleryResourceId
  containerName: containerName
  customizations: string(customizations)
  diskEncryptionSetResourceId: diskEncryptionSetResourceId
  enableBuildAutomation: string(enableBuildAutomation)
  environmentName: environment().name
  excludeFromLatest: excludeFromLatest
  hybridUseBenefit: hybridUseBenefit
  imageDefinitionName: imageDefinitionName
  imageMajorVersion: string(imageMajorVersion)
  imagePatchVersion: string(imagePatchVersion)
  imageVirtualMachineName: imageVirtualMachineName
  installAccess: string(installAccess)
  installArcGisPro: string(installArcGisPro)
  installExcel: string(installExcel)
  InstallOneDrive: string(installOneDrive)
  installOneNote: string(installOneNote)
  installOutlook: string(installOutlook)
  installPowerPoint: string(installPowerPoint)
  installProject: string(installProject)
  installPublisher: string(installPublisher)
  installSkypeForBusiness: string(installSkypeForBusiness)
  installTeams: string(installTeams)
  installUpdates: string(installUpdates)
  installVirtualDesktopOptimizationTool: string(installVirtualDesktopOptimizationTool)
  installVisio: string(installVisio)
  installWord: string(installWord)
  keyVaultName: keyVaultName
  location: location
  managementVirtualMachineName: managementVirtualMachineName
  marketplaceImageOffer: marketplaceImageOffer
  marketplaceImagePublisher: marketplaceImagePublisher
  marketplaceImageSKU: marketplaceImageSKU
  mlzTags: string(mlzTags)
  msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
  officeInstaller: officeInstaller
  replicaCount: string(replicaCount)
  resourceGroupName: resourceGroupName
  resourceManagerUri: environment().resourceManager
  sourceImageType: sourceImageType
  storageAccountResourceId: storageAccountResourceId
  subnetResourceId: subnetResourceId
  subscriptionId: subscriptionId
  tags: string(tags)
  teamsInstaller: teamsInstaller
  templateSpecResourceId: templateSpecResourceId
  tenantId: tenantId
  updateService: updateService
  userAssignedIdentityClientId: userAssignedIdentityClientId
  userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
  userAssignedIdentityResourceId: userAssignedIdentityResourceId
  vcRedistInstaller: vcRedistInstaller
  vDOTInstaller: vDOTInstaller
  virtualMachineSize: virtualMachineSize
  wsusServer: wsusServer
}
var privateEndpointName = 'pe-${automationAccountName}'
var runbookName = 'New-AzureZeroTrustImageBuild'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: managementVirtualMachineName
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: automationAccountName
  location: location
  tags: union(
    contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {},
    mlzTags
  )
  properties: {
    disableLocalAuth: false
    publicNetworkAccess: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: union(
    contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {},
    mlzTags
  )
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        id: resourceId(
          'Microsoft.Network/privateEndpoints/privateLinkServiceConnections',
          privateEndpointName,
          privateEndpointName
        )
        properties: {
          privateLinkServiceId: automationAccount.id
          groupIds: [
            'DSCAndHybridWorker'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-${automationAccountName}'
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azure-automation-net'
        properties: {
          privateDnsZoneId: automationAccountPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource runBook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: runbookName
  properties: {
    runbookType: 'PowerShell'
    logProgress: true
    logVerbose: true
  }
  tags: union(
    contains(tags, 'Microsoft.Automation/automationAccounts/runbooks') ? tags['Microsoft.Automation/automationAccounts/runbooks'] : {},
    mlzTags
  )
}

resource updateRunBook 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'runbook'
  location: location
  tags: union(
    contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
    mlzTags
  )
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'RunBookResourceId'
        value: runBook.id
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'RunbBookScriptContent'
        value: loadTextContent('../scripts/New-AzureZeroTrustImageBuild.ps1')
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
    ]
    source: {
      script: '''
        param(
            [string]$ResourceManagerUri,
            [string]$RunBookResourceId,
            [string]$RunBookScriptContent,
            [string]$UserAssignedIdentityClientId
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

            # Upload Content to Draft
            Invoke-RestMethod -Headers $AzureManagementHeader -Method 'PUT' -Uri $($ResourceManagerUriFixed + $RunBookResourceId + '/draft/content?api-version=2023-11-01') -Body $RunBookScriptContent

            # Publish the RunBook
            Invoke-RestMethod -Headers $AzureManagementHeader -Method 'POST' -Uri $($ResourceManagerUriFixed + $RunBookResourceId + '/publish?api-version=2023-11-01')
        }
        catch {
            throw
        }
      '''
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: imageDefinitionName
  properties: {
    frequency: 'Day'
    interval: 1
    startTime: dateTimeAdd(time, 'P1D')
    timeZone: timeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: jobScheduleName
  properties: {
    parameters: {
      parameters: replace(string(parameters), '"', '\\"')
    }
    runbook: {
      name: runbookName
    }
    runOn: hybridRunbookWorkerGroup.name
    schedule: {
      name: schedule.name
    }
  }
  dependsOn: [
    updateRunBook
  ]
}

module monitoring 'monitoring.bicep' =
  if (!empty(logAnalyticsWorkspaceResourceId) && !empty(distributionGroup) && !empty(actionGroupName)) {
    name: 'monitoring-${deploymentNameSuffix}'
    params: {
      actionGroupName: actionGroupName
      automationAccountName: automationAccount.name
      distributionGroup: distributionGroup
      location: location
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      mlzTags: mlzTags
      tags: tags
    }
  }

resource hybridRunbookWorkerGroup 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups@2022-08-08' = {
  parent: automationAccount
  name: 'Zero Trust Image Build Automation'
}

resource hybridRunbookWorker 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups/hybridRunbookWorkers@2022-08-08' = {
  parent: hybridRunbookWorkerGroup
  name: guid(hybridRunbookWorkerGroup.id)
  properties: {
    vmResourceId: virtualMachine.id
  }
  dependsOn: [
    updateRunBook
  ]
}

resource extension_HybridWorker 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: virtualMachine
  name: 'HybridWorkerForWindows'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    publisher: 'Microsoft.Azure.Automation.HybridWorker'
    type: 'HybridWorkerForWindows'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AutomationAccountURL: automationAccount.properties.automationHybridServiceUrl
    }
  }
  dependsOn: [
    updateRunBook
  ]
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' =
  if (!empty(domainJoinUserPrincipalName) && !empty(domainName) && !empty(oUPath)) {
    parent: virtualMachine
    name: 'JsonADDomainExtension'
    location: location
    tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
    properties: {
      forceUpdateTag: time
      publisher: 'Microsoft.Compute'
      type: 'JsonADDomainExtension'
      typeHandlerVersion: '1.3'
      autoUpgradeMinorVersion: true
      settings: {
        Name: domainName
        User: domainJoinUserPrincipalName
        Restart: 'true'
        Options: '3'
        OUPath: oUPath
      }
      protectedSettings: {
        Password: domainJoinPassword
      }
    }
    dependsOn: [
      extension_HybridWorker
      updateRunBook
    ]
  }
