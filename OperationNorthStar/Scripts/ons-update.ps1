$updateRingBody = @{
    "@odata.type"                           = "#microsoft.graph.windowsUpdateForBusinessConfiguration"
    description                             = "This update policy is for AVD hosts only."
    displayName                             = "Update Ring - Azure Virtual Desktop"
    version                                 = 2
    deliveryOptimizationMode                = "httpOnly"
    prereleaseFeatures                      = "settingsOnly"
    automaticUpdateMode                     = "autoInstallAtMaintenanceTime"
    microsoftUpdateServiceAllowed           = $true
    driversExcluded                         = $true
    qualityUpdatesDeferralPeriodInDays      = 14
    featureUpdatesDeferralPeriodInDays      = 90
    qualityUpdatesPaused                    = $false
    featureUpdatesPaused                    = $false
    qualityUpdatesPauseExpiryDateTime       = (get-date).AddDays(7)
    featureUpdatesPauseExpiryDateTime       = (get-date).AddDays(14)
    businessReadyUpdatesOnly                = "businessReadyOnly"
    skipChecksBeforeRestart                 = $false
    featureUpdatesRollbackWindowInDays      = 60
    deadlineForFeatureUpdatesInDays         = 14
    deadlineForQualityUpdatesInDays         = 2
    deadlineGracePeriodInDays               = 1
    postponeRebootUntilAfterDeadline        = $false
    scheduleRestartWarningInHours           = 2
    scheduleImminentRestartWarningInMinutes = 15
    userPauseAccess                         = "disabled"
    userWindowsUpdateScanAccess             = "enabled"
    updateNotificationLevel                 = "defaultNotifications"
    installationSchedule                    = @{
        "@odata.type"    = "#microsoft.graph.windowsUpdateActiveHoursInstall"
        activeHoursStart = "08:00:00"
        activeHoursEnd   = "17:00:00"
    }
}
$postBody = $updateRingBody | ConvertTo-Json -Depth 3
$deployUpdateRing = Invoke-RestMethod -Uri $script:deviceConfigurl -Method POST -Headers $script:token -Body $postBody

$deliveryBody = @{
    "@odata.type"                                             = "#microsoft.graph.windowsDeliveryOptimizationConfiguration"
    description                                               = "This update policy is for AVD hosts only."
    displayName                                               = "Delivery Optimization - Azure Virtual Desktop"
    version                                                   = 2
    deliveryOptimizationMode                                  = "httpOnly"
    restrictPeerSelectionBy                                   = "notConfigured"
    backgroundDownloadFromHttpDelayInSeconds                  = 60
    foregroundDownloadFromHttpDelayInSeconds                  = 60
    minimumRamAllowedToPeerInGigabytes                        = 4
    minimumDiskSizeAllowedToPeerInGigabytes                   = 32
    minimumFileSizeToCacheInMegabytes                         = 10
    minimumBatteryPercentageAllowedToUpload                   = 40
    maximumCacheAgeInDays                                     = 7
    vpnPeerCaching                                            = "notConfigured"
    cacheServerForegroundDownloadFallbackToHttpDelayInSeconds = 0
    cacheServerBackgroundDownloadFallbackToHttpDelayInSeconds = 0
    bandwidthMode                                             = @{
        "@odata.type"                      = "#microsoft.graph.deliveryOptimizationBandwidthHoursWithPercentage"
        bandwidthBackgroundPercentageHours = @{
            bandwidthBeginBusinessHours             = 8
            bandwidthEndBusinessHours               = 17
            bandwidthPercentageDuringBusinessHours  = 25
            bandwidthPercentageOutsideBusinessHours = 75
        }
    }
}
$deliveryPostBody = $deliveryBody | ConvertTo-Json -Depth 3
$deployDeliveryOptimization = Invoke-RestMethod -Uri $script:deviceConfigurl -Method POST -Headers $script:token -Body $deliveryPostBody

$windowsHealthBody = @{
    "@odata.type"                     = "#microsoft.graph.windowsHealthMonitoringConfiguration"
    description                       = "Shows the Windows Updates status"
    displayName                       = "Windows Health - Windows Updates"
    version                           = 1
    allowDeviceHealthMonitoring       = "enabled"
    configDeviceHealthMonitoringScope = "windowsUpdates"
}
$windowsHealthPostBody = $windowsHealthBody | ConvertTo-Json -Depth 3
$deployDeliveryOptimization = Invoke-RestMethod -Uri $script:deviceConfigurl -Method POST -Headers $script:token -Body $windowsHealthPostBody
