/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param allowDeletionOfReplicatedLocations bool = true
param computeGalleryName string
param computeGalleryImageResourceId string
//param diskEncryptionSetResourceId string
param excludeFromLatest bool
param imageDefinitionName string
param imageVersionNumber string
param imageVirtualMachineResourceId string
param location string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param mlzTags object
param replicaCount int
param tags object

resource computeGallery 'Microsoft.Compute/galleries@2022-01-03' existing = {
  name: computeGalleryName
}

resource sourceComputeGallery 'Microsoft.Compute/galleries@2022-01-03' existing =
  if (!empty(computeGalleryImageResourceId)) {
    scope: resourceGroup(split(computeGalleryImageResourceId, '/')[2], split(computeGalleryImageResourceId, '/')[4])
    name: split(computeGalleryImageResourceId, '/')[8]
  }

resource sourceImageDefinition 'Microsoft.Compute/galleries/images@2022-03-03' existing =
  if (!empty(computeGalleryImageResourceId)) {
    parent: sourceComputeGallery
    name: split(computeGalleryImageResourceId, '/')[10]
  }

resource imageDefinition 'Microsoft.Compute/galleries/images@2022-03-03' = {
  parent: computeGallery
  name: imageDefinitionName
  location: location
  tags: union(tags[?'Microsoft.Compute/galleries'] ?? {}, mlzTags)
  properties: {
    architecture: 'x64'
    features: [
      /* Uncomment features when generally available
      {
        name: 'IsHibernateSupported'
        value: 'True'
      }
      {
        name: 'IsAcceleratedNetworkSupported'
        value: 'True'
      }
      */
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
    ]
    hyperVGeneration: 'V2'
    identifier: {
      offer: empty(computeGalleryImageResourceId)
        ? marketplaceImageOffer
        : sourceImageDefinition.properties.identifier.offer
      publisher: empty(computeGalleryImageResourceId)
        ? marketplaceImagePublisher
        : sourceImageDefinition.properties.identifier.publisher
      sku: imageDefinitionName
    }
    osState: 'Generalized'
    osType: 'Windows'
  }
}

resource imageVersion 'Microsoft.Compute/galleries/images/versions@2022-03-03' = {
  parent: imageDefinition
  name: imageVersionNumber
  location: location
  tags: union(tags[?'Microsoft.Compute/galleries'] ?? {}, mlzTags)
  properties: {
    publishingProfile: {
      excludeFromLatest: excludeFromLatest
      replicaCount: replicaCount
      replicationMode: 'Full'
      storageAccountType: 'Standard_LRS'
      targetRegions: [
        {
          /* Not supported yet: https://learn.microsoft.com/en-us/azure/virtual-machines/image-version-encryption#limitations
          encryption: {
            osDiskImage: {
              diskEncryptionSetId: diskEncryptionSetResourceId
            }
          } 
          */
          name: location
          regionalReplicaCount: replicaCount
          storageAccountType: 'Standard_LRS'
        }
      ]
    }
    safetyProfile: {
      allowDeletionOfReplicatedLocations: allowDeletionOfReplicatedLocations
    }
    storageProfile: {
      source: {
        id: imageVirtualMachineResourceId
      }
    }
  }
}

output imageDefinitionResourceId string = imageDefinition.id
