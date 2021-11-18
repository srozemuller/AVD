[CmdletBinding()]
param (
    [Parameter()]
    [object]
    $yamlFile
)


###############################################################################################################
######                                         Install Modules                                           ######
###############################################################################################################
Write-Host "Installing Intune modules if required (current user scope)"

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

$yamlFile | ForEach-Object {
    ###############################################################################################################
    ######                                          Download YAML                                            ######
    ###############################################################################################################

    [string[]]$fileContent = (Invoke-WebRequest -Uri $_ -Headers @{"Cache-Control" = "no-cache" }).content
    foreach ($line in $fileContent) { $content = $content + "`n" + $line }
    $obj = ConvertFrom-Yaml $content
    $detectionRulePath = $obj.InstallPath.Substring(0, $obj.InstallPath.LastIndexOf("\"))
    $detectionruleFolder = $obj.InstallPath.Substring($obj.InstallPath.LastIndexOf("\") + 1)

    $publisher = $obj.publisher
    $name = $obj.packagename
    $description = $obj.shortdescription
    $appversion = $obj.PackageVersion
    $infourl = $obj.PackageUrl


    $IntuneWinFile = Get-ChildItem -Path  $path | Where-Object Name -Like "*.intunewin"
    $IntuneWinFile.Name


    # Create detection rule
    $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "$detectionRulePath" -FileOrFolder $detectionruleFolder -Check32BitOn64System $false -DetectionType "exists"

    $InstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File .\$($InstallationScriptFile.Name)"
    $UninstallCommandLine = $uninstallcommand
    $ImageFile = $icondownload
    $Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
    Add-IntuneWin32App -FilePath $IntuneWinFile.FullName -DisplayName $name -Description $description -Publisher $publisher -AppVersion $appversion -InformationURL $infourl -Icon $Icon -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Verbose


    ##Assignments
    $Win32App = Get-IntuneWin32App -DisplayName $DisplayName -Verbose

    #Install
    $installid = $installgroup.Id
    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $installid -Intent "available" -Notification "showAll" -Verbose


    #Uninstall
    $uninstallid = $uninstallgroup.Id
    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $uninstallid -Intent "uninstall" -Notification "showAll" -Verbose
}
