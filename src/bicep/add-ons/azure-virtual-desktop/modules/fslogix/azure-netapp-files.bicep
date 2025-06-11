param delegatedSubnetResourceId string
param delimiter string
param dnsServers string
@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param domainName string
param hostPoolResourceId string = ''
param fileShares array
param location string
param mlzTags object
param netAppAccountNamePrefix string
param netAppCapacityPoolNamePrefix string
param organizationalUnitPath string
param smbServerName string
param storageSku string
param suffix string =  ''
param tags object

var nameSuffix = empty(suffix) ? '' : '${delimiter}${suffix}'
var tagsNetAppAccount = union(empty(hostPoolResourceId) ? {} : {'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.NetApp/netAppAccounts'] ?? {}, mlzTags)

resource netAppAccount 'Microsoft.NetApp/netAppAccounts@2025-01-01' = {
  name: '${netAppAccountNamePrefix}${nameSuffix}'
  location: location
  tags: tagsNetAppAccount
  properties: {
    activeDirectories: [
      {
        aesEncryption: true
        domain: domainName
        dns: dnsServers
        organizationalUnit: empty(organizationalUnitPath) ? 'CN=Computers' : organizationalUnitPath
        password: domainJoinPassword
        smbServerName: smbServerName
        username: split(domainJoinUserPrincipalName, '@')[0]
      }
    ]
    encryption: {
      keySource: 'Microsoft.NetApp'
    }
  }
}

resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2025-01-01' = {
  parent: netAppAccount
  name: '${netAppCapacityPoolNamePrefix}${nameSuffix}'
  location: location
  tags: tagsNetAppAccount
  properties: {
    coolAccess: false
    encryptionType: 'Single'
    qosType: 'Auto'
    serviceLevel: storageSku
    size: 4398046511104
  }
}

resource volumes 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2025-01-01' = [for i in range(0, length(fileShares)): {
  parent: capacityPool
  name: fileShares[i]
  location: location
  tags: tagsNetAppAccount
  properties: {
    avsDataStore: 'Disabled'
    // backupId: 'string'
    coolAccess: false
    creationToken: fileShares[i]
    // dataProtection: {
    //   backup: {
    //     backupEnabled: bool
    //     backupPolicyId: 'string'
    //     policyEnforced: bool
    //     vaultId: 'string'
    //   }
    //   replication: {
    //     endpointType: 'string'
    //     remoteVolumeRegion: 'string'
    //     remoteVolumeResourceId: 'string'
    //     replicationId: 'string'
    //     replicationSchedule: 'string'
    //   }
    //   snapshot: {
    //     snapshotPolicyId: 'string'
    //   }
    // }
    defaultGroupQuotaInKiBs: 0
    defaultUserQuotaInKiBs: 0
    encryptionKeySource: 'Microsoft.NetApp'
    isDefaultQuotaEnabled: false
    isLargeVolume: false
    kerberosEnabled: false
    ldapEnabled: false
    networkFeatures: 'Standard'
    protocolTypes: [
      'CIFS'
    ]
    securityStyle: 'ntfs'
    serviceLevel: storageSku
    smbAccessBasedEnumeration: 'Enabled'
    smbContinuouslyAvailable: true
    smbEncryption: true
    smbNonBrowsable: 'Disabled'
    snapshotDirectoryVisible: true
    // snapshotId: 'string'
    subnetId: delegatedSubnetResourceId
    // throughputMibps: int
    // unixPermissions: 'string'
    usageThreshold: 107374182400
    // volumeType: 'string'
  }
}]

output fileShares array = [for (fileshare, i) in fileShares: volumes[i].properties.mountTargets[0].smbServerFqdn]
output smbServerNamePrefix string = smbServerName
