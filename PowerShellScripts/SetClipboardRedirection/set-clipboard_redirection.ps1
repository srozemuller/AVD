# Define the registry key path and value name
$keyPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services"
$serverClientName = "SCClipLevel"
$clientServerName = "CSClipLevel"
# Define the value data
$scValueData = 0 # 0 = Disable clipboard redirection, no dat transfer between session host and client
$csValueData = 2 # 2 = 	Allow plain text and images to be transferred between the client and the session host

# Set the registry value
New-ItemProperty -Path $keyPath -Name $serverClientName -Value $scValueData -PropertyType DWORD -Force
# Check if the value was successfully set
if (Test-Path "$keyPath\$serverClientName") {
    Write-Host "Registry value '$serverClientName' was successfully created with data '$scValueData'."
} else {
    Write-Host "Failed to create registry value '$serverClientName'."
}

New-ItemProperty -Path $keyPath -Name $clientServerName -Value $csValueData -PropertyType DWORD -Force
# Check if the value was successfully set
if (Test-Path "$keyPath\$clientServerName") {
    Write-Host "Registry value '$clientServerName' was successfully created with data '$csValueData'."
} else {
    Write-Host "Failed to create registry value '$clientServerName'."
}
