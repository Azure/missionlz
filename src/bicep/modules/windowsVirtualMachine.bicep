param name string
param location string
param tags object = {}

param networkInterfaceName string

param size string
param adminUsername string
@secure()
@minLength(12)
param adminPassword string
param publisher string
param offer string
param sku string
param version string
param createOption string
param storageAccountType string
param logAnalyticsWorkspaceId  string

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' existing = {
  name: networkInterfaceName
}

resource windowsVirtualMachine 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    hardwareProfile: {
      vmSize: size 
    }
    osProfile: {
      computerName: take(name, 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: version 
      }
      osDisk: {
        createOption: createOption
        managedDisk: {
          storageAccountType: storageAccountType          
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        { 
          id: networkInterface.id
        }
      ]
    }
  }
}

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: '${windowsVirtualMachine.name}/DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    windowsVirtualMachine
  ]
}

resource policyExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: '${windowsVirtualMachine.name}/AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource mmaExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  name: '${windowsVirtualMachine.name}/MMAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    settings: {
      workspaceId: reference(logAnalyticsWorkspaceId , '2015-11-01-preview').customerId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceId , '2015-11-01-preview').primarySharedKey
    }
  }
  dependsOn: [
    windowsVirtualMachine
  ]
}

resource networkWatcher 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${windowsVirtualMachine.name}/Microsoft.Azure.NetworkWatcher'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
  }
  dependsOn: [
    windowsVirtualMachine
  ]
}
