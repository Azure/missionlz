param location string
param policyId string
param recoveryServicesVaultName string
param sessionHostCount int
param sessionHostIndex int
param tags object
param virtualMachineNamePrefix string
param virtualMachineResourceGroupName string

var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'

resource protectedItems_Vm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = [for i in range(0, sessionHostCount): {
  name: '${recoveryServicesVaultName}/Azure/${v2VmContainer}${virtualMachineResourceGroupName};${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}/${v2Vm}${virtualMachineResourceGroupName};${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}'
  location: location
  tags: tags
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: policyId
    sourceResourceId: resourceId(virtualMachineResourceGroupName, 'Microsoft.Compute/virtualMachines', '${virtualMachineNamePrefix}${padLeft((i + sessionHostIndex), 4, '0')}')
  }
}]
