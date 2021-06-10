@description('In which location is the resource stored')
param location string

@description('What is the Shared Image Gallery name')
param sigName string

@description('Who is the image publisher')
param imagePublisher string

@description('What is the definitions name')
param imageDefinitionName string

@description('What is the definitions offer')
param imageOffer string

@description('What is the definitions SKU')
param imageSKU string


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

//Create Shard Image Gallery
resource wvdsig 'Microsoft.Compute/galleries@2020-09-30' = {
  name: sigName
  location: location
}

//Create Image definitation
resource wvdid 'Microsoft.Compute/galleries/images@2020-09-30' = {
  parent: wvdsig
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
  }
}
