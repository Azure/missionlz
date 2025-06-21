@description('The domain name for the managed domain.')
param domainName string

@description('The location of the managed domain.')
param location string

@description('The resource ID of the subnet for the managed domain.')
param subnetResourceId string

resource domainServices 'Microsoft.AAD/DomainServices@2022-12-01' = {
  name: domainName
  location: location
  properties: {
    domainConfigurationType: 'FullySynced'
    domainName: domainName
    domainSecuritySettings: {
      kerberosRc4Encryption: 'Disabled'
    }
    filteredSync: 'Disabled'
    notificationSettings: {
      notifyGlobalAdmins: 'Enabled'
      notifyDcAdmins: 'Enabled'
      additionalRecipients: []
    }
    replicaSets: [
      {
        subnetId: subnetResourceId
        location: location
      }
    ]
    sku: 'Standard'
  }
}
