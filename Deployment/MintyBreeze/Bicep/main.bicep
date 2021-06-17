param sigName string
param sigLocation string
param imagePublisher string
param imageDefinitionName string
param imageOffer string
param imageSKU string
param osState string
param osType string

module sig './Templates/SIG/deploy-shared-image-gallery.bicep' = {
  name: 'DeploySig${sigName}'
  params: {
    sigName: sigName
    location: sigLocation
    imagePublisher: imagePublisher
    imageDefinitionName: imageDefinitionName
    imageOffer: imageOffer
    imageSKU: imageSKU
    osState: osState
    osType: osType
  }
}
