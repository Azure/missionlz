/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'resourceGroup'

param location string
param mlzTags object
param tags object
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: virtualMachineName
}

resource sysprepVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  parent: virtualMachine
  name: 'sysprepVirtualMachine'
  location: location
  tags: union(
    contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {},
    mlzTags
  )
  properties: {
    treatFailureAsDeploymentFailure: false
    asyncExecution: true
    parameters: []
    source: {
      script: '''
        Start-Sleep -Seconds 30
        Remove-Item -LiteralPath 'C:\Windows\Panther' -Force -Recurse -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\cdrom' -Name 'Start' -Value 1
        Start-Process -File 'C:\Windows\System32\Sysprep\Sysprep.exe' -ArgumentList '/generalize /oobe /shutdown /mode:vm'
      '''
    }
  }
}
