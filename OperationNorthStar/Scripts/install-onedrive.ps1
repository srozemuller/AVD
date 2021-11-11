#Download OneDrive per-machine installer
$downloadLocation = "https://go.microsoft.com/fwlink/?linkid=844652"
$downloadDestination = "$($env:TEMP)\OneDriveSetup.exe"
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($downloadLocation, $downloadDestination)

#Run OneDrive per-machine installer
$installProcess = Start-Process $downloadDestination -ArgumentList "/allusers" -WindowStyle Hidden -PassThru
$installProcess.WaitForExit()