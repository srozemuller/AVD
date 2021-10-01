$script:token = GetAuthToken -resource 'https://graph.microsoft.com' 
$script:mainUrl = "https://graph.microsoft.com/beta"

function Get-Application {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$appId
    )
    $url = $script:mainUrl+ "/applications?`$filter=appId eq '$($appId)'"
    $appInfo = (Invoke-RestMethod -Uri $url -Method GET -Headers $script:token).value
    return $appInfo
}

function Get-ServicePrincipal {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$appId
    )
    $url = $script:mainUrl + "/servicePrincipals?`$filter=appId eq '$($appId)'"
    $servicePrincipalInfo = (Invoke-RestMethod -Uri $url -Method GET -Headers $script:token).value
    return $servicePrincipalInfo
}
function New-Application {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppDisplayName
    )
    $url = $script:mainUrl + "/applications"
    $body = @{
        displayName = $AppDisplayName
    }
    $postBody = $body | ConvertTo-Json
    $newApp = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $newApp
}

function New-ApplicationPassword {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId
    )
    $url = $script:mainUrl + "/applications/"+ $AppId + "/addPassword"
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
    $url = $($script:mainUrl) + "/applications/" + $appId
    $body = @{
        requiredResourceAccess = @(
            $permissions
        )
    }
    $postBody = $body | ConvertTo-Json -Depth 5 
    $appPermissions = Invoke-RestMethod -Uri $url -Method PATCH -Body $postBody -Headers $script:token -ContentType "application/json"
    return $appPermissions
}

function New-SPFromApp {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId
    )
    $url = "$($script:mainUrl)/servicePrincipals"
    $body = @{
        appId = $AppId
    }
    $postBody = $body | ConvertTo-Json
    $servicePrincipal = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $servicePrincipal
}

function Add-SPDelegatedPermissions {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalId
    )
    $url = $($script:mainUrl) + "/servicePrincipals/"+ $ServicePrincipalId +"/delegatedPermissionClassifications"
    $body = @{
        permissionId   = "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70"
        permissionName = "DeviceManagementConfiguration.ReadWrite.All"
    }
    $postBody = $body | ConvertTo-Json
    $spPermissions = Invoke-RestMethod -Uri $url -Method POST -Body $postBody -Headers $script:token
    return $spPermissions
}
function Consent-ApplicationPermissions {
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalId,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceId,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Scope
    )
    $date = Get-Date
    $url = $($script:mainUrl) + "/oauth2PermissionGrants"
    $body = @{
        clientId    = $ServicePrincipalId
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

$newApp = New-Application -AppDisplayName "MEM Configurator"
Add-ApplicationPermissions -AppId $newApp.appId -permissions $permissions 
$newSp = New-SPFromApp -AppId $newApp.appId 
Add-SPDelegatedPermissions -ServicePrincipalId $newSp.id

Consent-ApplicationPermissions -ServicePrincipalId $newSp.id -ResourceId "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70" -Scope "Directory.ReadWrite.All"
Consent-ApplicationPermissions -ServicePrincipalId $newSp.id -ResourceId "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70" -Scope "Group.ReadWrite.All"
Consent-ApplicationPermissions -ServicePrincipalId $newSp.id -ResourceId "3f73b7e5-80b4-4ca8-9a77-8811bb27eb70" -Scope "DeviceManagementManagedDevices.ReadWrite.All"
