function Install-WinGetApplication {
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param
    (
        [parameter(Mandatory, ParameterSetName = 'Single')]
        [ValidateNotNullOrEmpty()]
        [string]$AppName,

        [parameter(Mandatory, ParameterSetName = 'Single')]
        [ValidateNotNullOrEmpty()]
        [string]$AppVersion,

        [parameter(Mandatory, ParameterSetName = 'Single')]
        [ValidateNotNullOrEmpty()]
        [string]$AppScope,

        [parameter(Mandatory, ParameterSetName = 'Single')]
        [ValidateNotNullOrEmpty()]
        [switch]$Force,

        [parameter(Mandatory, ParameterSetName = 'Multiple')]
        [ValidateNotNullOrEmpty()]
        [string]$InstallFile
    )

    Begin {
        Write-Verbose "Start searching for hostpool $hostpoolName"
        AuthenticationCheck
        $token = GetAuthToken -resource $script:AzureApiUrl
        $apiVersion = "?api-version=2019-12-10-preview"
        switch ($PsCmdlet.ParameterSetName) {
            Single {
                $installParameters = @{
                    "--name" = $AppName
                    "--version" = $AppVersion
                    "--scope" = $AppScope
                }
            }
            Multiple {

            }
        }
    }
    Process {
           winget install @installParameters
    }
}

