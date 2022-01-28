# AVD ADFS Local AD congfigurator
$roles = ("AD-Certificate", "ADFS-Federation")
$restartNeeded = 0
$roles | Foreach-Object {
    try {
        $feature = Get-WindowsFeature -Name $_
        if (!($feature.Installed)) {
            $installResults = Install-WindowsFeature -Name $_ -IncludeManagementTools
            if ($installResults.RestartNeeded -ne "No") {
                $restartNeeded ++
            }
        }
    }
    catch {
        Throw "$_ not found."
    }
}
if ($restartNeeded -gt 0) {
    Restart-Computer
}

