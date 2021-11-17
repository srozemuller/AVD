[CmdletBinding(DefaultParameterSetName = 'Manifest')]
param
(
    [parameter(Mandatory, ParameterSetName = 'Single', Position = 0)]
    [parameter(Mandatory, ParameterSetName = 'Manifest', Position = 0)]
    [validateSet("Install", "Uninstall")]
    [string]$task,

    [parameter(Mandatory, ParameterSetName = 'Single', Position = 1)]
    [string]$AppName,

    [parameter(Mandatory, ParameterSetName = 'Single', Position = 2)]
    [string]$AppVersion,
    
    [parameter(ParameterSetName = 'Single', Position = 3)]
    [string]$Source,

    [parameter(ParameterSetName = 'Single', Position = 4)]
    [string]$logFilePath = "C:\AppDeployment",

    [parameter(ParameterSetName = 'Manifest', Position = 1)]
    [string]$ManifestFile

)

Begin {
    if (-not(Test-Path $logFilePath)) {
        New-Item -ItemType Directory -Path $logFilePath
    }
    if (-not(Test-Path $AppWorkingPath)) {
        $AppWorkingPath = (New-Item -ItemType Directory -Path $($logFilePath + "\" + $AppName)).FullName
    }
    else {
        $AppWorkingPath = $($logFilePath + "\" + $AppName)
    }
    $logFile = $AppWorkingPath + "\" + $AppName + "_install.log"
    $date = get-date -format [yyyy-MM-dd_mm:ss]-
    $date = $date.ToString()
       
    switch ($PsCmdlet.ParameterSetName) {
        Single {
            $installParameters = @{
                "--name"    = $AppName
                "--version" = $AppVersion
            }
            if ($Source) {
                $installParameters.Add("--source", $Source)
            }
            Write-Output "Start installing WinGet application $appName with version $appVersion" | Out-File $logFile -Append
        }
        ManifestFile {
            $templateFilePath = $AppWorkingPath + "\" +$appName + ".yaml"
            Invoke-WebRequest `
                -Uri $manifestFile `
                -OutFile $templateFilePath `
                -UseBasicParsing `
                -Headers @{"Cache-Control" = "no-cache" }
                $installParameters = @{
                    "--manifest" = $templateFilePath
                }
                Write-Output "Start installing WinGet application from file $ManifestFile" | Out-File $logFile -Append
        }
    }
}
Process {

    $switchArguments = "--silent --accept-package-agreements --accept-source-agreements"
    $arguments = ($installParameters.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join " "
    $argString = $arguments.ToString()
    Write-Output "Started $($date): Winget $($task) $argString $switchArguments" | Out-File $logFile -Append

    Write-Warning "Winget $task $argString $switchArguments"
    Write-Output  "$env:ProgramFiles" | Out-File $logFile -Append
    $Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\AppInstallerCLI.exe")

    Write-Output "Installing from $templateFilePath" | Out-File $logFile -Append
    Start-Process -Wait -FilePath $winget -ArgumentList "settings --enable LocalManifestFiles"
    Start-Process -Wait -FilePath $winget -ArgumentList "$task $argString $switchArguments --log $logFile"
    Write-Output "Install completed" | Out-File $logFile -Append
}

