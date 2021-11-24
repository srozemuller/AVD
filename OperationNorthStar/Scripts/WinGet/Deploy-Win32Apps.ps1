[CmdletBinding()]
param (
    [Parameter()]
    [object]
    $yamlFile,

    [Parameter()]
    [string]
    $IntuneWinFile,

    [Parameter()]
    [string]
    $assignToGroupName
)



#Install MS Graph if not available
if (Get-Module -ListAvailable -Name powershell-yaml) {
    Write-Host "PowerShell YAML Already Installed"
} 
else {
    try {
        Install-Module -Name powershell-yaml -Scope CurrentUser -Repository PSGallery -Force 
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

#Importing Modules
Import-Module powershell-yaml
# For test
#$yamlFile = "https://raw.githubusercontent.com/srozemuller/AVD/main/OperationNorthStar/Scripts/WinGet/manifests/g/Google/Chrome/96.0.4664.45/Google.Chrome.installer.yaml"
$yamlFile | ForEach-Object {
    Try {
        [string[]]$fileContent = (Invoke-WebRequest -Uri $_ -Headers @{"Cache-Control" = "no-cache" }).content
        $content = $null
        foreach ($line in $fileContent) { $content = $content + "`n" + $line }
        Try {
            $yamlContent = ConvertFrom-Yaml $content
        }
        Catch {
            Write-Error "Converting YAML not succesfull, $_"
        }
    }
    Catch {
        Write-Error "He! This location does not exist."
    }

    $detectionRuleParameters = @{
        Path                 = $yamlContent.InstallPath.Substring(0, $yamlContent.InstallPath.LastIndexOf("\"))
        FileOrFolder         = $yamlContent.InstallPath.Substring($yamlContent.InstallPath.LastIndexOf("\") + 1)
        existence            = $true
        check32BitOn64System = $false
        DetectionType        = "exists"
    }
    # Create detection rule
    $DetectionRule = New-IntuneWin32AppDetectionRuleFile @detectionRuleParameters
    $manifestLocation = $_.Substring(0,$_.LastIndexOf('/'))
    
    $appDeployParameters = @{
        filePath             = $IntuneWinFile
        publisher            = $yamlContent.PackageIdentifier.Substring(0, $yamlContent.PackageIdentifier.IndexOf('.'))
        displayName          = $($yamlContent.PackageIdentifier.Substring($yamlContent.PackageIdentifier.IndexOf('.') + 1)).Replace('.', ' ')
        description          = if(-not($yamlContent.PackageDescription)){"No description"}
        appversion           = $yamlContent.PackageVersion
        InstallExperience    = "system"
        RestartBehavior      = "suppress" 
        DetectionRule        = $DetectionRule
        InstallCommandLine   = "Install-WinGetApplication.exe install -manifestFileLocation $manifestLocation"
        UninstallCommandLine = "Install-WinGetApplication.exe uninstall -appname $($yamlContent.PackageIdentifier) -appversion $($yamlContent.PackageVersion)"
    }
    $appDeployment = Add-IntuneWin32App @appDeployParameters -Verbose
    $appDeployment
    Write-Verbose "Group name $groupName provided, looking for group in Azure AD"
    $graphUrl = "https://graph.microsoft.com"
    $requestUrl = $graphUrl + "/beta/groups?`$filter=displayName eq 'All Users'"
    $identityInfo = (Invoke-RestMethod -Method GET -Uri $requestUrl -Headers $token).value.id
    Add-IntuneWin32AppAssignmentGroup -Include -ID $appDeployment.id -GroupID $identityInfo -Intent "available" -Notification "showAll" -Verbose
}
