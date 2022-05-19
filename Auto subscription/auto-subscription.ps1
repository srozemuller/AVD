try {
    $autoSubscriptionPath = "HKCU:\Software\Policies\Microsoft\Windows NT\Terminal Services"
    $value = "https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery"
    if (!(Test-Path $autoSubscriptionPath)) {
        New-Item -Path $autoSubscriptionPath -Force | Out-Null
    }
    New-ItemProperty -Path $autoSubscriptionPath -Name "AutoSubscription" -Value $value -PropertyType String -Force | Out-Null
}
catch {
    Throw "Unfortunately, the registry key is not added, $_"
}
