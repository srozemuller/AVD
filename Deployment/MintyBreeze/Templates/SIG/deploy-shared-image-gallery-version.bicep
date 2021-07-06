param galleryName string
param definitionName string
param versionName string
param replicaRegion string
param source string

resource sigVersion 'Microsoft.Compute/galleries/images/versions@2019-12-01' = {
    name: '${galleryName}/${definitionName}/${versionName}'
    location: resourceGroup().location
    tags: {}
    properties: {
      publishingProfile: {
        targetRegions: [
          {
            name: replicaRegion
          }
        ]
        replicaCount: 1
      }
      storageProfile: {
        source: {
          id: source
        }
        osDiskImage: {
          hostCaching: 'ReadWrite'
        }
      }
    }
  }


  