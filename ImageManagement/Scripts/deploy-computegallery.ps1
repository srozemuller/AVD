param
(   
    [Parameter (Mandatory)][string] $subscriptionId,
    [Parameter (Mandatory)][object] $parameterFile
)
Set-AzContext -Subscription $subscriptionId

$fileParameters = (Get-Content $parameterFile | ConvertFrom-Json).parameters
$galleryParameters = @{
    GalleryName       = $galleryName
    ResourceGroupName = $fileParameters.gallerySettings.galleryResourceGroup
    Location          = $fileParameters.location
    Description       = $fileParameters.gallerySettings.Description
}
try {
    $gallery = New-AzGallery @galleryParameters
    
}
catch {
    Throw "Creating Gallery $galleryName failed!"
}
Write-Host "##vso[task.setvariable variable=galleryId;isOutput=true;issecret=false]$($gallery.id)"