@description('In which location is the resource stored')
param location string

@description('What is the Compute Gallery name')
param galleryName string

@description('Who is the image publisher')
param imagePublisher string

@description('What is the definitions name')
param imageDefinitionName string

@description('What is the definitions offer')
param imageOffer string

@description('What is the definitions SKU')
param imageSKU string

@description('On which Hypver-V generation are the images')
@allowed([
    'V1'
    'V2'
])
param hyperVGeneration string

@description('What is the definitions offer')
@allowed([
  'Generalized'
  'Specialized'
])
param osState string

@description('What is the definitions type, like Windows or Linux')
@allowed([
  'Windows'
  'Linux'
])
param osType string

@description('What is the version name in SemVer format x.x.x')
param versionName string

@description('What is the source image/disk resource id')
param imageSource string

//Create Azure Compute Gallery
resource azg 'Microsoft.Compute/galleries@2022-03-03' = {
  name: galleryName
  location: location
}

//Create Image definition
resource galleryDefinition 'Microsoft.Compute/galleries/images@2022-03-03' = {
  parent: azg
  name: imageDefinitionName
  location: location
  properties: {
    osState: osState
    osType: osType
    identifier: {
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSKU
    }
    hyperVGeneration: hyperVGeneration
  }
}

resource imageVersion 'Microsoft.Compute/galleries/images/versions@2022-03-03' = {
  name: '${galleryName}/${imageDefinitionName}/${versionName}'
  dependsOn: [
    azg
    galleryDefinition
  ]
  location: location
  tags: {}
  properties: {
    publishingProfile: {
      replicaCount: 1
    }
    storageProfile: {
      source: {
        id: imageSource
      }
      osDiskImage: {
        hostCaching: 'ReadWrite'
      }
    }
  }
}

output galleryId string = azg.id
output galleryDefinitionId string = galleryDefinition.id
output imageVersionId string = imageVersion.id
