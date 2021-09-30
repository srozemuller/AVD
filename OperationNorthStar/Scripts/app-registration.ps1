$script:token = GetAuthToken -resource 'https://graph.microsoft.com' 
$script:mainUrl = "https://graph.microsoft.com/beta"

function Get-Application {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$appId
    )
    $url = "$($script:mainUrl)/applications?`$filter=appId eq '$($appId)'"
    $appInfo = (Invoke-RestMethod -Uri $url -Method GET -Headers $script:token).value
    return $appInfo
}

function Get-ServicePrincipal {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$appDisplayName
    )
    $url = "$($script:mainUrl)/servicePrincipals?`$filter=displayName eq '$($appDisplayName)'"
    $servicePrincipalInfo = (Invoke-RestMethod -Uri $url -Method GET -Headers $script:token).value
    return $servicePrincipalInfo
}
function Create-Application {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppDisplayName
    )
    $url = "$($script:mainUrl)/applications"
    $body = @{
        displayName = $AppDisplayName
    }
    $postBody = $body | ConvertTo-Json
    $newApp = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $newApp
}

function Create-ApplicationPassword {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppDisplayName
    )
    $appInfo = Get-Application -AppDisplayName $AppDisplayName
    $url = "$($script:mainUrl)/applications/$($appInfo.id)/addPassword"
    $body = @{
        passwordCredential = @{
            displayName = 'AppPassword'
        }
    }
    $postBody = $body | ConvertTo-Json
    $appPass = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $appPass
}

function Add-ApplicationPermissions {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$appId,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object]$permissions

    )
    $appInfo = Get-Application -AppId $appId
    $url = "$($script:mainUrl)/applications/$($appInfo.id)"
    $body = @{
        requiredResourceAccess = @(
            $permissions
        )
    }
    $postBody = $body | ConvertTo-Json -Depth 5 
    $appPermissions = Invoke-RestMethod -Uri $url -Method PATCH -Body $postBody -Headers $script:token -ContentType "application/json"
    return $appPermissions
}

$permissions = @{
    resourceAppId  = "00000003-0000-0000-c000-000000000000"
    resourceAccess = @(
        @{
            id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
            type = "Scope"
        },
        @{
            id   = "4e46008b-f24c-477d-8fff-7bb4ec7aafe0"
            type = "Scope"
        },
        @{
            id   = "c5366453-9fb0-48a5-a156-24f0c49a4b84"
            type = "Scope"
        },
        @{
            id   = "44642bfe-8385-4adc-8fc6-fe3cb2c375c3"
            type = "Scope"
        }
    )
}

$newApp = Create-Application -AppDisplayName "MEM Configurator"

Add-ApplicationPermissions -AppId $newApp.appId -permissions $permissions 
function Create-SPFromApp {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId
    )
    $appInfo = Get-Application -AppId $AppId
    $url = "$($script:mainUrl)/servicePrincipals"
    $body = @{
        appId = $appInfo.appId
    }
    $postBody = $body | ConvertTo-Json
    $servicePrincipal = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $servicePrincipal
}
$newSp = Create-SPFromApp -AppId $newApp.id

function Add-SPDelegatedPermissions {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PrincipalId
    )
    $spInfo = Get-ServicePrincipal -AppDisplayName $AppDisplayName
    $url = $($script:mainUrl)+ "/servicePrincipals/" + $PrincipalId + "/delegatedPermissionClassifications"
    $body = @{
        permissionId   = "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70"
        permissionName = "DeviceManagementConfiguration.ReadWrite.All"
    }
    $postBody = $body | ConvertTo-Json
    $spPermissions = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $spPermissions
}

Add-SPDelegatedPermissions -PrincipalId $newSp.id

function Consent-ApplicationPermissions {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppDisplayName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceId,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Scope
    )
    $date = Get-Date
    $SpInfo = Get-ServicePrincipal -AppDisplayName $AppDisplayName
    $url = "$($script:mainUrl)/oauth2PermissionGrants"
    $body = @{
        clientId    = $SpInfo.Id
        consentType = "AllPrincipals"
        principalId = $null
        resourceId  = $ResourceId
        scope       = $Scope
        startTime   = $date
        expiryTime  = $date
    }
    $postBody = $body | ConvertTo-Json
    $appPermissions = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $appPermissions
}

Consent-ApplicationPermissions -AppDisplayName "MEM Configurator" -ResourceId "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70" -Scope "Directory.ReadWrite.All"
Consent-ApplicationPermissions -AppDisplayName "MEM Configurator" -ResourceId "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70" -Scope "Group.ReadWrite.All"
Consent-ApplicationPermissions -AppDisplayName "MEM Configurator" -ResourceId "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70" -Scope "DeviceManagementManagedDevices.ReadWrite.All"
