targetScope = 'subscription'

module amdGpuDriver 'amd-driver.bicep' = {
  name: 'amdGpuDriverPolicy'
  params: {}
}

module nvidiaGpuDriver 'nvidia-driver.bicep' = {
  name: 'nvidiaGpuDriverPolicy'
  params: {}
}

module gpuSettings 'gpu-acceleration-settings.bicep' = {
  name: 'gpuSettingsPolicy'
  params: {}
}
