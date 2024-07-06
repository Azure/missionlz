param hostPoolName string
param keyVaultName string
param location string
param time string = utcNow('u')

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' existing = {
  name: hostPoolName
}

resource registrationToken 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPool.name
  location: location
  properties: {
    hostPoolType: hostPool.properties.hostPoolType
    preferredAppGroupType: hostPool.properties.preferredAppGroupType
    maxSessionLimit: hostPool.properties.maxSessionLimit
    loadBalancerType: hostPool.properties.loadBalancerType
    registrationInfo: {
      expirationTime: dateTimeAdd(time, 'PT2H')
      registrationTokenOperation: 'Update'
    }
  }
}

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'avdHostPoolRegistrationToken'
  properties: {
    value: registrationToken.properties.registrationInfo.token
  }
}
