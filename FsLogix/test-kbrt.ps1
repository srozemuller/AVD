[CmdletBinding()]
param (
    [Parameter()]
    [string]$aadUserName,
    [Parameter()]
    [string]$azureADUserPwd,
    [Parameter()]
    [string]$psexecDownloadLocation
)
$downloadLocation = "C:\KerberosTest"
$outputFile = (Join-Path -Path $downloadLocation -ChildPath 'kbrt.txt')
if (-Not (Test-Path $downloadLocation)) {
    Write-Host -ForegroundColor Green "Creating directory $downloadLocation"
    New-Item -ItemType Directory -Force -Path $downloadLocation
}
Invoke-WebRequest -Uri $psexecDownloadLocation -OutFile (Join-Path -Path $downloadLocation -ChildPath 'psTools.zip')
Expand-Archive -Path (Join-Path -Path $downloadLocation -ChildPath 'psTools.zip') -DestinationPath $downloadLocation -Force:$true
Invoke-Expression ("$downloadLocation\PsExec.exe -h -i -u {0} -p {1} -accepteula powershell -noninteractive -command 'klist get krbtgt | Out-File -FilePath $outputFile'" -f $aadUserName, $azureADUserPwd)
try {
    Get-Content $outputFile
}
catch {
    Throw "No content file found!, $_"
}