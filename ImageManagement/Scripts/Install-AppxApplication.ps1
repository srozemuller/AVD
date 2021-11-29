[CmdletBinding(DefaultParameterSetName = 'Manifest')]
param
(
    [parameter(Mandatory, ParameterSetName = 'Single', Position = 1)]
    [string]$AppName,

    [parameter(ParameterSetName = 'Single', Position = 3)]
    [string]$Source,

    [parameter()]
    [string]$logFilePath = "C:\AppDeployment",

    [parameter(ParameterSetName = 'Manifest', Position = 1)]
    [string]$AppInstallerLocation
)

Begin {
    $date = get-date -format [yyyy-MM-dd_mm:ss]-
    $date = $date.ToString()
    if (-not(Test-Path $logFilePath)) {
        New-Item -ItemType Directory -Path $logFilePath
    }   
    switch ($PsCmdlet.ParameterSetName) {
        Manifest {
            try {
                if ($AppInstallerLocation.Contains('raw.githubusercontent.com')) {
                    Write-Verbose "Raw GitHub content provided"
                    $repoPath = ($AppInstallerLocation -split $($AppInstallerLocation -split "/")[5])[-1] 
                }
                else {
                    Write-Verbose "Human readable GitHub content provided"
                    $repoPath = ($AppInstallerLocation -split $($AppInstallerLocation -split "/")[6])[-1]
                }
                $arguments = 'https://api.github.com/repos/{3}/{4}/contents' -f ($AppInstallerLocation -split "/") + [string]$repoPath
                $request = Invoke-WebRequest -Uri $($arguments) -UseBasicParsing:$true
                $content = $request.Content | ConvertFrom-Json
                $files = $content | Where-Object { $_.type -eq "file" } | Select-Object download_url, name
                Write-Information "Downloading files"
                $appName = ($files | Where-Object {$_.name -match '.appinstaller$'}).Name.Split(".")[0] 
            }
            catch {
                Write-Error "Location not found or location has no appinstaller file!!"
                break
            }

        }
    }
    if (-not(Test-Path (Join-Path -Path $logFilePath -ChildPath $AppName))) {
        $AppWorkingPath = (New-Item -ItemType Directory -Path (Join-Path -Path $logFilePath -ChildPath $AppName)).FullName
    }
    else {
        $AppWorkingPath = Join-Path -Path $logFilePath -ChildPath $AppName
    }
    $logFile = Join-Path -Path $AppWorkingPath -ChildPath 'install.log'
}
Process {
    switch ($PsCmdlet.ParameterSetName) {
        Manifest {
            $templateFilePath = (New-Item -ItemType Directory -Path (Join-Path -Path $AppWorkingPath -ChildPath 'MSIX')).FullName
            $files | ForEach-Object {
                $requestParams = @{
                    Uri             = $_.Download_url
                    OutFile         = Join-Path -Path $templateFilePath -ChildPath $_.Name
                    UseBasicParsing = $true
                    Headers         = @{"Cache-Control" = "no-cache" }
                }
                Invoke-WebRequest @requestParams
                Write-Output "Downloaded file $($_.Name)" | Out-File $logFile -Append
            }
            $appInstallerFile = Get-ChildItem -Path $templateFilePath | Where { $_.Name.Endswith('.appinstaller') } | Sort-Object | Select-Object -Last 1
        }
        default {

        }
    }
    Add-AppPackage -AppInstallerFile $appInstallerFile
}