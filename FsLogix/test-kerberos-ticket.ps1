[CmdletBinding()]
param (
    [Parameter()]
    [string]$userName,
    [Parameter()]
    [string]$password
)
try {
    $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($username,(ConvertTo-SecureString -String $password -AsPlainText -Force))
    Write-Host "Getting Kerberos Ticket Granting Ticket from Micrsoft Online" | Out-File "C:\Windows\output.txt" -Force
    Start-Process -Filepath powershell.exe -ArgumentList "klist purge" -NoNewWindow -Credential $Credentials 
    Start-Process -Filepath powershell.exe -ArgumentList "klist get krbtgt" -NoNewWindow -WorkingDirectory '.' -RedirectStandardOutput "C:\Windows\output.txt" -Credential $Credentials
    $output = Get-Content "C:\Windows\output.txt"
    if ($output | Select-String -Pattern "Server: krbtgt/KERBEROS.MICROSOFTONLINE.COM @ KERBEROS.MICROSOFTONLINE.COM" -CaseSensitive -SimpleMatch) { 
        Write-Host "Got ticket from KERBEROS.MICROSOFTONLINE.COM" 
    }
    else {
        Throw "No ticket found from KERBEROS.MICROSOFTONLINE.COM"
    }#>
}   
catch {
    Throw "Kerberos check failed, $_"
}