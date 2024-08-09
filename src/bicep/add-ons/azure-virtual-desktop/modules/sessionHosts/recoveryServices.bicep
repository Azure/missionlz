param deployFslogix bool
param deploymentNameSuffix string
param divisionRemainderValue int
param location string
param maxResourcesPerTemplateDeployment int
param recoveryServicesVaultName string
param resourceGroupHosts string
param resourceGroupManagement string
param sessionHostBatchCount int
param sessionHostIndex int
param tagsRecoveryServicesVault object
param virtualMachineNamePrefix string

resource vault 'Microsoft.RecoveryServices/vaults@2022-03-01' existing = {
  name: recoveryServicesVaultName
  scope: resourceGroup(resourceGroupManagement)
}

resource backupPolicy_Vm 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' existing = {
  parent: vault
  name: 'AvdPolicyVm'
}

module protectedItems_Vm 'protectedItems.bicep' = [for i in range(1, sessionHostBatchCount): if (!deployFslogix) {
  name: 'deploy-backup-protected-items-${i - 1}-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement) // Management Resource Group
  params: {
    location: location
    policyId: backupPolicy_Vm.id
    recoveryServicesVaultName: vault.name
    sessionHostCount: i == sessionHostBatchCount && divisionRemainderValue > 0 ? divisionRemainderValue : maxResourcesPerTemplateDeployment
    sessionHostIndex: i == 1 ? sessionHostIndex : ((i - 1) * maxResourcesPerTemplateDeployment) + sessionHostIndex
    tags: tagsRecoveryServicesVault
    virtualMachineNamePrefix: virtualMachineNamePrefix
    virtualMachineResourceGroupName: resourceGroupHosts
  }
}]
