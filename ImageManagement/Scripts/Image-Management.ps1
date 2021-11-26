$manifestFile = "https://github.com/microsoft/winget-pkgs/tree/master/manifests/g/Google/Chrome/96.0.4664.45"
$appName = "Chrome"
$parameters = @{
    ResourceGroupName = "rg-roz-avd-01"
    vmName            = "imgmgt"
    Location          = 'westeurope'
    FileUri           = "https://raw.githubusercontent.com/srozemuller/AVD/main/OperationNorthStar/Scripts/WinGet/Install-WinGetApplication.ps1"
    Argument          = "-task install -ManifestFileLocation $manifestFile"
    Name              = $appName
    ForceReRun        = $true
}
Set-AzVMCustomScriptExtension  -Run 'Install-WinGetApplication.ps1' @parameters

$removeParameters = @{
    ResourceGroupName = "rg-roz-avd-01"
    vmName            = "imgmgt"
    Name              = $appName
}
Get-AzVMExtension @removeParameters | Remove-AzVMExtension -Force