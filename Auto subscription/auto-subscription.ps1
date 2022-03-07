try {
    $autoSusbscriptionPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services"
    $value = "https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery"
    if (!(Test-Path $autoSusbscriptionPath)) {
        New-Item -Path $autoSusbscriptionPath -Force | Out-Null
    }
    New-ItemProperty -Path $autoSusbscriptionPath -Name "AutoSusbscription" -Value $value -PropertyType String -Force | Out-Null
}
catch {
    Throw "Unfortunately, the registry key is not added, $_"
}