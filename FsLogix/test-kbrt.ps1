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
    New-EventLog –LogName Application –Source "kbrt-test"
    Write-EventLog –LogName Application –Source "kbrt-test" –EntryType Information –EventID 1 –Message "This is start."
    Start-Process -FilePath 'powershell.exe' -Credential $credentials -ArgumentList ("klist get krbtgt | Out-File c:\test\kr.txt ") -WorkingDirectory 'C:\Windows\System32'
    if ((Get-Content c:\test\kr.txt) -match 'Server: krbtgt/KERBEROS.MICROSOFTONLINE.COM @ KERBEROS.MICROSOFTONLINE.COM'){
        Write-Host "Good" | Out-File C:\Test\output.txt
        Write-EventLog –LogName Application –Source "kbrt-test" –EntryType Information –EventID 1 –Message "This is a test message."
    }
    else {
        "Not good" | Out-File C:\Windows\Temp\output.txt
    }
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

