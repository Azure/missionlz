targetScope = 'subscription'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2025-11-01' = {
  name: 'SetGpuSettings'
  properties: {
    description: 'Sets the GPU acceleration settings for VM sizes that contain a GPU.'
    displayName: 'Set GPU Acceleration Settings'
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
              'Standard_NV6'
              'Standard_NV12'
              'Standard_NV24'
              'Standard_NV12s_v3'
              'Standard_NV24s_v3'
              'Standard_NV48s_v3'
              'Standard_NC4as_T4_v3'
              'Standard_NC8as_T4_v3'
              'Standard_NC16as_T4_v3'
              'Standard_NC64as_T4_v3'
              'Standard_NV4as_v4'
              'Standard_NV8as_v4'
              'Standard_NV16as_v4'
              'Standard_NV32as_v4'
              'Standard_NV6ads_A10_v5'
              'Standard_NV12ads_A10_v5'
              'Standard_NV18ads_A10_v5'
              'Standard_NV36ads_A10_v5'
              'Standard_NV36adms_A10_v5'
              'Standard_NV72ads_A10_v5'
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
          type: 'Microsoft.Compute/virtualMachines/runCommands'
          name: '[concat(field(\'name\'), \'/Set-GpuAccelerationSettings\')]'
          evaluationDelay: 'AfterProvisioning'
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor
          ]
          existenceCondition: {
            field: 'Microsoft.Compute/virtualMachines/runCommands/parameters[*].name'
            equals: 'nvidiaVmSizes'
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
                variables: {
                  nvidiaVmSizes: [
                    'Standard_NV6'
                    'Standard_NV12'
                    'Standard_NV24'
                    'Standard_NV12s_v3'
                    'Standard_NV24s_v3'
                    'Standard_NV48s_v3'
                    'Standard_NC4as_T4_v3'
                    'Standard_NC8as_T4_v3'
                    'Standard_NC16as_T4_v3'
                    'Standard_NC64as_T4_v3'
                    'Standard_NV6ads_A10_v5'
                    'Standard_NV12ads_A10_v5'
                    'Standard_NV18ads_A10_v5'
                    'Standard_NV36ads_A10_v5'
                    'Standard_NV36adms_A10_v5'
                    'Standard_NV72ads_A10_v5'
                  ]
                }
                resources: [
                  {
                    
                    apiVersion: '2023-09-01'
                    location: '[parameters(\'location\')]'
                    name: '[concat(parameters(\'virtualMachineName\'), \'/Set-GpuSettings\')]'
                    properties: {
                      asyncExecution: false
                      parameters: [
                        {
                          name: 'NvidiaGpu'
                          value: '[if(contains(variables(\'nvidiaVmSizes\'), parameters(\'virtualMachineName\')), \'true\', \'false\')]'
                        }
                      ]
                      source: {
                        script: loadTextContent('../../artifacts/Set-SessionHostConfiguration.ps1')
                      }
                      treatFailureAsDeploymentFailure: true
                    }
                    type: 'Microsoft.Compute/virtualMachines/runCommands'
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
