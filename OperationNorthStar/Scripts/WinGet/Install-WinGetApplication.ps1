[CmdletBinding(DefaultParameterSetName = 'Single')]
param
(
    [parameter(Mandatory, ParameterSetName = 'Single',Position=0)]
    [string]$AppName,

    [parameter(Mandatory, ParameterSetName = 'Single',Position=1)]
    [string]$AppVersion,

    
    [parameter(Mandatory, ParameterSetName = 'Single',Position=2)]
    [string]$Source
)

Begin {
    Write-Verbose "Start searching for hostpool $hostpoolName"
    switch ($PsCmdlet.ParameterSetName) {
        Single {
            $installParameters = @{
                "--name"    = $AppName
                "--version" = $AppVersion
                "--source" = $Source
            }
        }
        Multiple {

        }
    }
}
Process {
    $arguments = ($installParameters.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Value)" }) -join " "
    $argString = $arguments.ToString()
    Write-Warning "Winget install $argString"
    Invoke-Expression -Command "winget install $($arguments.ToString())"
}

