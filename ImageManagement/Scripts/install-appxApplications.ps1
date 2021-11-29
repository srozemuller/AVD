function Download-AppxPackage {
    [CmdletBinding()]
    param (
        [string]$Uri,
        [string]$downloadLocation = "."
    )
       
    process {
        $downloadLocation = (Resolve-Path $downloadLocation).Path
        #Get Urls to download
        Write-Host -ForegroundColor Yellow "Processing $Uri"
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body "type=url&url=$Uri&ring=Retail" -ContentType 'application/x-www-form-urlencoded'
        $LinksMatch = ($WebResponse.Links | where { $_ -like '*.msixbundle*' } | where { $_ -like '*_neutral_*' -or $_ -like "*_" + $env:PROCESSOR_ARCHITECTURE.Replace("AMD", "X").Replace("IA", "X") + "_*" } | Select-String -Pattern '(?<=a href=").+(?=" r)').matches.value
        $Files = ($WebResponse.Links | where { $_ -like '*.msixbundle*' } | where { $_ -like '*_neutral_*' -or $_ -like "*_" + $env:PROCESSOR_ARCHITECTURE.Replace("AMD", "X").Replace("IA", "X") + "_*" } | where { $_ } | Select-String -Pattern '(?<=noreferrer">).+(?=</a>)').matches.value

        for ($i = 0; $i -lt $LinksMatch.Count; $i++) {
            $Array += , @($LinksMatch, $Files)
        }
        $Array = $Array | sort-object @{Expression = { $_[1] }; Descending = $True }
        for ($i = 0; $i -lt $LinksMatch.Count; $i++) {
            $CurrentFile = $Array[1]
            $CurrentUrl = $Array[0]
            if (-Not (Test-Path "$downloadLocation\$CurrentFile")) {
                "Downloading $downloadLocation\$CurrentFile"
                $FilePath = "$downloadLocation\$CurrentFile"
                $FileRequest = Invoke-WebRequest -Uri $CurrentUrl -UseBasicParsing
                [System.IO.File]::WriteAllBytes($FilePath, $FileRequest.content)
            }
        }
    }
}
    
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    if (-not (Get-Module -Name Appx -ListAvailable )){
        Install-Module -Name AppX -Force
        Import-Module Appx -usewindowspowershell
    }
}
catch {
    Throw "Install AppX module failed"
}
$downloadLocation = "C:\AppXInstall"
if (-Not (Test-Path $downloadLocation)) {
    Write-Host -ForegroundColor Green "Creating directory $downloadLocation"
    New-Item -ItemType Directory -Force -Path $downloadLocation
}
Download-AppxPackage "https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1" -downloadLocation $downloadLocation
$appInstallerFile = Get-ChildItem -Path $downloadLocation | Where { $_.Name -match 'Microsoft.DesktopAppInstaller' } | Sort-Object | Select-Object -Last 1

try {
    Add-AppxPackage -Path $appInstallerFile.Fullname
}
catch {
    "App not installed"
    $_
}