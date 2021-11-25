param
(   
    [Parameter (Mandatory)][string] $subscriptionId,
    [Parameter (Mandatory)][object] $parameterFile,
    [Parameter (Mandatory)][string] $ImageSku,
    [Parameter (Mandatory)][string] $ImageOffer,

    [Parameter (Mandatory)]
    [ValidateSet("Generalized", "Specialized")]
    [string]$osState,

    [Parameter (Mandatory)]
    [ValidateSet("Windows", "Linux")]
    [string]$osType,


    [Parameter (Mandatory)]
    [ValidateSet("V1", "V2")]
    [string]$hyperVGeneration
)
Set-AzContext -Subscription $subscriptionId


$fileParameters = (Get-Content $parameterFile | ConvertFrom-Json).parameters
$imageDefinitionParameters = @{
    GalleryName = $fileParameters.gallerySettings.GalleryName
    ResourceGroupName = $fileParameters.gallerySettings.GalleryResourceGroup
    Location = $fileParameters.location
    Name = $ImageOffer + "-" + $ImageSku 
    OsState = $osState
    OsType = $osType
    Publisher = "UCS"
    Offer = $osType
    Sku = $ImageSku
    HyperVGeneration= $hyperVGeneration
}
$imageDefinition = New-AzGalleryImageDefinition @imageDefinitionParameters
Write-Host "##vso[task.setvariable variable=definitionId;isOutput=true;issecret=false]$($imageDefinition.id)"
Write-Host "##vso[task.setvariable variable=definitionName;isOutput=true;issecret=false]$($imageDefinition.name)"