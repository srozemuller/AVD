[CmdletBinding(DefaultParameterSetName = 'Manifest')]
param
(
    [parameter(Mandatory, Position = 0)]
    [validateSet("Install", "Uninstall")]
    [string]$task,

    [parameter(Mandatory, ParameterSetName = 'Single', Position = 1)]
    [string]$AppName,

    [parameter(Mandatory, ParameterSetName = 'Single', Position = 2)]
    [string]$AppVersion,
    
    [parameter(ParameterSetName = 'Single', Position = 3)]
    [string]$Source,

    [parameter()]
    [string]$logFilePath = "C:\AppDeployment",

    [parameter(ParameterSetName = 'Manifest', Position = 1)]
    [string]$ManifestFileLocation,

    [parameter(ParameterSetName = 'LocalManifest', Position = 1)]
    [string]$LocalManifestFileLocation

)

Begin {
    $date = get-date -format [yyyy-MM-dd_mm:ss]-
    $date = $date.ToString()
    if (-not(Test-Path $logFilePath)) {
        New-Item -ItemType Directory -Path $logFilePath
    }   
    switch ($PsCmdlet.ParameterSetName) {
        Single {
            $installParameters = @{
                "--name"    = $AppName
                "--version" = $AppVersion
            }
            if ($Source) {
                $installParameters.Add("--source", $Source)
            }
        }
        Manifest {
            try {
                if ($ManifestFileLocation.Contains('raw.githubusercontent.com')) {
                    Write-Verbose "Raw GitHub content provided"
                    $repoPath = ($ManifestFileLocation -split $($ManifestFileLocation -split "/")[5])[-1] 
                }
                else {
                    Write-Verbose "Human readable GitHub content provided"
                    $repoPath = ($ManifestFileLocation -split $($ManifestFileLocation -split "/")[6])[-1]
                }
                $arguments = 'https://api.github.com/repos/{3}/{4}/contents' -f ($ManifestFileLocation -split "/") + [string]$repoPath
                $request = Invoke-WebRequest -Uri $($arguments) -UseBasicParsing:$true
                $content = $request.Content | ConvertFrom-Json
                $files = $content | Where-Object { $_.type -eq "file" } | Select-Object download_url, name
                Write-Information "Downloading files"
            }
            catch {
                Write-Error "Location not found!"
                break
            }
            $appFile = $files[-1].download_url.Substring($files[-1].download_url.LastIndexOf('/') + 1) 
            $appName = $appFile.Replace('.yaml', $null)
        }
        LocalManifest {
            $installParameters = @{
                "--manifest" = $LocalManifestFileLocation
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
            $templateFilePath = (New-Item -ItemType Directory -Path (Join-Path -Path $AppWorkingPath -ChildPath 'YAML')).FullName
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
            $installParameters = @{
                "--manifest" = $templateFilePath
            }
        }
        default {

        }
    }
    Write-Output "Start installing WinGet application $appName" | Out-File $logFile -Append
    $switchArguments = "--silent --accept-package-agreements --accept-source-agreements"
    $arguments = ($installParameters.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join " "
    $argString = $arguments.ToString()
    Write-Output "Started $($date): Winget $($task) $argString $switchArguments" | Out-File $logFile -Append

    Write-Information "executing with: $task $argString $switchArguments" -InformationAction Continue
    Write-Output  "$env:ProgramFiles" | Out-File $logFile -Append
    $Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\AppInstallerCLI.exe")

    Write-Output "Installing from $templateFilePath" | Out-File $logFile -Append
    Start-Process -Wait -FilePath $winget -ArgumentList "settings --enable LocalManifestFiles"
    Start-Process -Wait -FilePath $winget -ArgumentList "$task $argString $switchArguments --log $logFile"
    Write-Output "Install completed" | Out-File $logFile -Append
}