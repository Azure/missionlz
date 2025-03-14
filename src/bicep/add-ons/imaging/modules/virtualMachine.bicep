/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param computeGalleryImageResourceId string
// param diskEncryptionSetResourceId string
param location string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param mlzTags object
param sourceImageType string
param subnetResourceId string
param tags object
param userAssignedIdentityResourceId string
@secure()
param virtualMachineAdminPassword string
@secure()
param virtualMachineAdminUsername string
param virtualMachineName string
param virtualMachineSize string

var imageReference = sourceImageType == 'AzureComputeGallery'
  ? {
      id: computeGalleryImageResourceId
    }
  : {
      publisher: marketplaceImagePublisher
      offer: marketplaceImageOffer
      sku: marketplaceImageSKU
      version: 'latest'
    }

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${virtualMachineName}'
  location: location
  tags: union(tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachineName
  location: location
  tags: union(tags[?'Microsoft.Compute/virtualMachines'] ?? {}, mlzTags)
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      adminPassword: virtualMachineAdminPassword
      adminUsername: virtualMachineAdminUsername
      computerName: virtualMachineName
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          /* Not supported yet: https://learn.microsoft.com/en-us/azure/virtual-machines/image-version-encryption#limitations
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          */
          storageAccountType: 'StandardSSD_LRS'
        }
        name: 'disk-${virtualMachineName}'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    securityProfile: {
      // encryptionAtHost: true
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
  }
}

output name string = virtualMachine.name
output resourceId string = virtualMachine.id
