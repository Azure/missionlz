param delegatedSubnetResourceId string
param deploymentNameSuffix string
param dnsServers string
@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param domainName string
param existingSharedActiveDirectoryConnection bool
param fileShares array
param fslogixContainerType string
param location string
param managementVirtualMachineName string
param netAppAccountName string
param netAppCapacityPoolName string
param organizationalUnitPath string
param resourceGroupManagement string
param securityPrincipalNames array
param smbServerLocation string
param storageSku string
param storageService string
param tagsNetAppAccount object
param tagsVirtualMachines object

resource netAppAccount 'Microsoft.NetApp/netAppAccounts@2021-06-01' = {
  name: netAppAccountName
  location: location
  tags: tagsNetAppAccount
  properties: {
    activeDirectories: existingSharedActiveDirectoryConnection ? [
      {
        aesEncryption: true
        domain: domainName
        dns: dnsServers
        organizationalUnit: organizationalUnitPath
        password: domainJoinPassword
        smbServerName: 'anf-${smbServerLocation}'
        username: split(domainJoinUserPrincipalName, '@')[0]
      }
    ] : null
    encryption: {
      keySource: 'Microsoft.NetApp'
    }
  }
}

resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2021-06-01' = {
  parent: netAppAccount
  name: netAppCapacityPoolName
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

resource volumes 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2021-06-01' = [for i in range(0, length(fileShares)): {
  parent: capacityPool
  name: fileShares[i]
  location: location
  tags: tagsNetAppAccount
  properties: {
    avsDataStore: 'Disabled'
    // backupId: 'string'
    coolAccess: false
    // coolnessPeriod: int
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
    // exportPolicy: {
    //   rules: [
    //     {
    //       allowedClients: 'string'
    //       chownMode: 'string'
    //       cifs: bool
    //       hasRootAccess: bool
    //       kerberos5iReadWrite: bool
    //       kerberos5pReadWrite: bool
    //       kerberos5ReadWrite: bool
    //       nfsv3: bool
    //       nfsv41: bool
    //       ruleIndex: int
    //       unixReadWrite: bool
    //     }
    //   ]
    // }
    isDefaultQuotaEnabled: false
    // isRestoring: bool
    kerberosEnabled: false
    ldapEnabled: false
    networkFeatures: 'Standard'
    protocolTypes: [
      'CIFS'
    ]
    securityStyle: 'ntfs'
    serviceLevel: storageSku
    smbContinuouslyAvailable: true
    smbEncryption: true
    snapshotDirectoryVisible: true
    // snapshotId: 'string'
    subnetId: delegatedSubnetResourceId
    // throughputMibps: int
    // unixPermissions: 'string'
    usageThreshold: 107374182400
    // volumeType: 'string'
  }
}]

module ntfsPermissions 'runCommand.bicep' = {
  name: 'deploy-fslogix-ntfs-permissions-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    location: location
    name: 'Set-NtfsPermissions.ps1'
    parameters: [
      {
        name: 'FslogixContainerType'
        value:fslogixContainerType
      }
      {
        name: 'ResourceManagerUri'
        value: environment().resourceManager
      }
      {
        name: 'SecurityPrincipalNames'
        value: securityPrincipalNames
      }
      {
        name: 'SmbServerLocation'
        value: smbServerLocation
      }
      {
        name: 'StorageService'
        value: storageService
      }
    ]
    script: loadTextContent('../../artifacts/Set-NtfsPermissions.ps1')
    tags: tagsVirtualMachines
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    volumes
  ]
}

output fileShares array = contains(fslogixContainerType, 'Office') ? [
  volumes[0].properties.mountTargets[0].smbServerFqdn
  volumes[1].properties.mountTargets[0].smbServerFqdn
] : [
  volumes[0].properties.mountTargets[0].smbServerFqdn
]
