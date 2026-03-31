targetScope = 'subscription'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2025-11-01' = {
  name: 'NvidiaGpuDriverExtension'
  properties: {
    description: 'Deploys the NVIDIA GPU driver extension for VM sizes that contain an NVIDIA GPU. NCasT4_v3 sizes are not supported by this policy since the extension only enables the CUDA driver. For NCasT4_v3 sizes, the driver must be manually installed.'
    displayName: 'Deploy NVIDIA GPU Driver'
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
              'Standard_NV6ads_A10_v5'
              'Standard_NV12ads_A10_v5'
              'Standard_NV18ads_A10_v5'
              'Standard_NV36ads_A10_v5'
              'Standard_NV36adms_A10_v5'
              'Standard_NV72ads_A10_v5'
            ]
          }
        ]
      }
      then: {
        effect: 'deployIfNotExists'
        details: {
          type: 'Microsoft.Compute/virtualMachines/extensions'
          name: '[concat(field(\'name\'), \'/NvidiaGpuDriverWindows\')]'
          evaluationDelay: 'AfterProvisioning'
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor
          ]
          existenceCondition: {
            allOf: [
              {
                field: 'Microsoft.Compute/virtualMachines/extensions/type'
                equals: 'NvidiaGpuDriverWindows'
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
                variables: {
                  virtualMachineSize: '[reference(resourceId(\'Microsoft.Compute/virtualMachines\', parameters(\'virtualMachineName\')), \'2021-07-01\').hardwareProfile.vmSize]'
                }
                resources: [
                  {
                    apiVersion: '2021-03-01'
                    location: '[parameters(\'location\')]'
                    name: '[concat(parameters(\'virtualMachineName\'), \'/NvidiaGpuDriverWindows\')]'
                    properties: {
                      autoUpgradeMinorVersion: true
                      publisher: 'Microsoft.HpcCompute'
                      // NVv3 VM sizes require a specific driver version: https://learn.microsoft.com/azure/virtual-machines/extensions/hpccompute-gpu-windows#known-issues
                      settings: '[if(and(startsWith(variables(\'virtualMachineSize\'), \'Standard_NV\'), or(endsWith(variables(\'virtualMachineSize\'), \'s_v3\'), endsWith(variables(\'virtualMachineSize\'),\'s_A10_v5\'))), json(\'{"driverVersion": "538.46"}\'), json(\'{}\'))]'
                      type: 'NvidiaGpuDriverWindows'
                      typeHandlerVersion: '1.9'
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
