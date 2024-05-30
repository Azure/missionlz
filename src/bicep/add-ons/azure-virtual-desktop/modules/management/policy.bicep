targetScope = 'subscription'

// Disabling the param below until Enhanced Policies in Recovery Services support managed disks with private link
//param diskAccessResourceId string
param location string
param resourceGroupName string

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'DiskNetworkAccess'
  properties: {
    description: 'Disable network access to managed disks in the ${resourceGroupName} resource group'
    displayName: 'Disable Disk Access (${resourceGroupName})'
    mode: 'All'
    parameters: {}
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Compute/disks'
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/60fc6e62-5479-42d4-8bf4-67625fcc2840'
          ]
          operations: [
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/disks/networkAccessPolicy'
              value: 'DenyAll'
            }
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/disks/publicNetworkAccess'
              value: 'Disabled'
            }
            // Disabling the configuration below until Enhanced Policies in Recovery Services support managed disks with private link
            // Once it is supported, these settings would replace the settings / operations above
            /* {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/disks/networkAccessPolicy'
              value: 'AllowPrivate'
            }
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/disks/publicNetworkAccess'
              value: 'Disabled'
            }
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/disks/diskAccessId'
              value: diskAccessResourceId
            } */
          ]
        }
      }
    }
    policyType: 'Custom'
  }
}

module policyAssignment 'policyAssignment.bicep' = {
  name: 'DiskNetworkAccess'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    policyDefinitionId: policyDefinition.id
    policyDisplayName: policyDefinition.properties.displayName
    policyName: policyDefinition.properties.displayName
  }
}
