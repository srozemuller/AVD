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
    [string]$ManifestFile

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
                $ManifestFile.EndsWith('.yaml') | Out-Null
                Write-Information "File is yaml file"
            }
            catch {
                Write-Error "File is not a .yaml file"
                break
            }
            $appFile = $ManifestFile.Substring($ManifestFile.LastIndexOf('/') + 1) 
            $appName = $appFile.Replace('.yaml', $null)
        }
    }
    if (-not(Test-Path $($logFilePath + "\" + $AppName))) {
        $AppWorkingPath = (New-Item -ItemType Directory -Path $($logFilePath + "\" + $AppName)).FullName
    }
    else {
        $AppWorkingPath = $($logFilePath + "\" + $AppName)
    }
    $logFile = $AppWorkingPath + "\" + $AppName + "_install.log"
}
Process {
    if ($PsCmdlet.ParameterSetName -eq "Manifest") {
        $templateFilePath = $AppWorkingPath + "\" + $appFile
        $requestParams = @{
            Uri = $manifestFile 
            OutFile = $templateFilePath 
            UseBasicParsing = $true
            Headers = @{"Cache-Control" = "no-cache" }
        }
        Invoke-WebRequest @requestParams
        $installParameters = @{
            "--manifest" = $templateFilePath
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
