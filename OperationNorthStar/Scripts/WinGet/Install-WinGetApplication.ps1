[CmdletBinding(DefaultParameterSetName = 'Single')]
param
(
    [parameter(Mandatory, ParameterSetName = 'Single', Position = 0)]
    [validateSet("Install", "Uninstall")]
    [string]$task,

    [parameter(Mandatory, ParameterSetName = 'Single', Position = 1)]
    [string]$AppName,

    [parameter(Mandatory, ParameterSetName = 'Single', Position = 2)]
    [string]$AppVersion,
    
    [parameter(ParameterSetName = 'Single', Position = 3)]
    [string]$Source = "WinGet",

    [parameter(ParameterSetName = 'Single', Position = 4)]
    [string]$logFilePath = "C:\AppDeployment"

)

Begin {
    Write-Verbose "Start searching for hostpool $hostpoolName"
    switch ($PsCmdlet.ParameterSetName) {
        Single {
            $installParameters = @{
                "--name"    = $AppName
                "--version" = $AppVersion
                "--source"  = $Source
                "--log" = $logFile
            }
        }
        Multiple {

        }
    }
    $logFile = $logFilePath + "\" + $AppName + ".log"
    $switchArguments = "--silent --accept-package-agreements --accept-source-agreements"
}
Process {
    if (-not(Test-Path $logFilePath)){
        Write-Warning "Folder $logfilePath does not exist, creating it."
        mkdir $logFilePath
    }
    Write-Output "Winget $task $argString $switchArguments" | OutFile $logFile
    $arguments = ($installParameters.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join " "
    $argString = $arguments.ToString()
    Write-Warning "Winget $task $argString $switchArguments"
    Invoke-Expression -Command "cmd /c winget $task $($arguments.ToString()) $switchArguments"
}

