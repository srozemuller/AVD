[CmdletBinding()]
param (
    [Parameter()]
    [string]$userName,
    [Parameter()]
    [string]$password
)
#try {
    $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($username,(ConvertTo-SecureString -String $password -AsPlainText -Force))
    #Write-Host "Getting Kerberos Ticket Granting Ticket from Micrsoft Online" | Out-File "C:\Windows\output.txt" -Force
    #$credentials
    cmd /c klist get krbtgt
    #Start-Process -Filepath powershell.exe -verb RunAsUser -ArgumentList "echo hello" #-Credential $credentials
    klist get krbtgt | Out-File c:\windows\temp\krbt.txt
    #$output = Get-Content "C:\Windows\output.txt"
    #if ($output | Select-String -Pattern "Server: krbtgt/KERBEROS.MICROSOFTONLINE.COM @ KERBEROS.MICROSOFTONLINE.COM" -CaseSensitive -SimpleMatch) { 
    #    Write-Host "Got ticket from KERBEROS.MICROSOFTONLINE.COM" 
    #}
    #else {
    #    Throw "No ticket found from KERBEROS.MICROSOFTONLINE.COM"
    #}#>
#}   
#catch {
#    Throw "Kerberos check failed, $_"
#}

