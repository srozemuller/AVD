<#PSScriptInfo
.VERSION 1.1
.AUTHOR AndrewTaylor
.DESCRIPTION Creates an Intune application from a Winget Manifest
.GUID ebed646c-ee4a-418c-ac46-0a2af1925016
.COMPANYNAME 
.COPYRIGHT GPL
.TAGS intune aad
.LICENSEURI https://github.com/andrew-s-taylor/public/blob/main/LICENSE
.PROJECTURI https://github.com/andrew-s-taylor/public
.ICONURI 
.EXTERNALMODULEDEPENDENCIES powershell-yaml AzureADPreview IntuneWin32App
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>
<#
.SYNOPSIS
  Creates an Intune application from a Winget Manifest
.DESCRIPTION
Complete end-end creation of application in Intune.
Creates AzureAD group for Install and Uninstall
Extracts information from Winget custom manifest

.INPUTS
Winget YAML URL
.OUTPUTS
None
.NOTES
  Version:        1.0
  Author:         Andrew Taylor
  Twitter:        @AndrewTaylor_2
  WWW:            andrewstaylor.com
  Creation Date:  12/11/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
N/A
#>

####################################################


[CmdletBinding()]
param (
    [Parameter()]
    [String]
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

##Set Download Directory

$directory = $env:TEMP
#Create Temp location
$random = Get-Random -Maximum 1000 
$random = $random.ToString()
$date =get-date -format yyMMddmmss
$date = $date.ToString()
$path2 = $random + "-"  + $date
$path = $directory + "\" + $path2 + "\"
new-item -ItemType Directory -Path $path

$filename = $yamlFile.Substring($yamlFile.LastIndexOf("/") + 1)

##File Name
$templateFilePath = $path + $filename

###############################################################################################################
######                                          Download YAML                                            ######
###############################################################################################################

Invoke-WebRequest `
   -Uri $yamlFile `
   -OutFile $templateFilePath `
   -UseBasicParsing `
   -Headers @{"Cache-Control"="no-cache"}

[string[]]$fileContent = Get-Content $templateFilePath
foreach ($line in $fileContent) { $content = $content + "`n" + $line }
$obj = ConvertFrom-Yaml $content

$detectionRulePath = $obj.InstallPath.Substring(0,$obj.InstallPath.LastIndexOf("\"))
$detectionruleFolder = $obj.InstallPath.Substring($obj.InstallPath.LastIndexOf("\")+1)

$publisher = $obj.publisher
$name = $obj.packagename
$description = $obj.shortdescription
$appversion = $obj.PackageVersion
$infourl = $obj.PackageUrl


    $IntuneWinFile = Get-ChildItem -Path  $path | Where-Object Name -Like "*.intunewin"
    $IntuneWinFile.Name

    # Create custom display name like 'Name' and 'Version'
    $DisplayName = $name

    # Create detection rule
    $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "$detectionRulePath" -FileOrFolder $detectionruleFolder -Check32BitOn64System $false -DetectionType "exists"

    $InstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File .\$($InstallationScriptFile.Name)"
    $UninstallCommandLine = $uninstallcommand
    $ImageFile = $icondownload
    $Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
    Add-IntuneWin32App -FilePath $IntuneWinFile.FullName -DisplayName $DisplayName -Description $description -Publisher $publisher -AppVersion $appversion -InformationURL $infourl -Icon $Icon -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Verbose


    ##Assignments
    $Win32App = Get-IntuneWin32App -DisplayName $DisplayName -Verbose

    #Install
$installid = $installgroup.Id
Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $installid -Intent "available" -Notification "showAll" -Verbose


#Uninstall
$uninstallid = $uninstallgroup.Id
Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $uninstallid -Intent "uninstall" -Notification "showAll" -Verbose
    
