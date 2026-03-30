targetScope = 'subscription'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2025-11-01' = {
  name: 'AmdGpuDriverExtension'
  properties: {
    description: 'Deploys the AMD GPU driver extension for VM sizes that contain an AMD GPU.'
    displayName: 'Deploy AMD GPU Driver'
    mode: 'All'
    parameters: null
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            field: 'Microsoft.Compute/virtualMachines/hardwareProfile.vmSize'
            in: [
              'Standard_NV4as_v4'
              'Standard_NV8as_v4'
              'Standard_NV16as_v4'
              'Standard_NV32as_v4'
              'Standard_NV4ads_V710_v5'
              'Standard_NV8ads_V710_v5'
              'Standard_NV12ads_V710_v5'
              'Standard_NV24ads_V710_v5'
              'Standard_NV28adms_V710_v5'
            ]
          }
        ]
      }
      then: {
        effect: 'deployIfNotExists'
        details: {
          type: 'Microsoft.Compute/virtualMachines/extensions'
          name: '[concat(field(\'name\'), \'/AmdGpuDriverWindows\')]'
          evaluationDelay: 'AfterProvisioning'
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor
          ]
          existenceCondition: {
            allOf: [
              {
                field: 'Microsoft.Compute/virtualMachines/extensions/type'
                equals: 'AmdGpuDriverWindows'
              }
              {
                field: 'Microsoft.Compute/virtualMachines/extensions/publisher'
                equals: 'Microsoft.HpcCompute'
              }
            ]
          }
          deployment: {
            properties: {
              mode: 'incremental'
              parameters: {
                location: {
                  value: '[field(\'location\')]'
                }
                virtualMachineName: {
                  value: '[field(\'name\')]'
                }
              }
              template: {
                '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
                contentVersion: '1.0.0.0'
                parameters: {
                  location: {
                    type: 'string'
                  }
                  virtualMachineName: {
                    type: 'string'
                  }
                }
                resources: [
                  {
                    apiVersion: '2021-03-01'
                    location: '[parameters(\'location\')]'
                    name: '[concat(parameters(\'virtualMachineName\'), \'/AmdGpuDriverWindows\')]'
                    properties: {
                      autoUpgradeMinorVersion: true
                      publisher: 'Microsoft.HpcCompute'
                      settings: {}
                      type: 'AmdGpuDriverWindows'
                      typeHandlerVersion: '1.0'
                    }
                    type: 'Microsoft.Compute/virtualMachines/extensions'
                  }
                ]
              }
            }
          }
        }
      }
    }
    policyType: 'Custom'
  }
}
