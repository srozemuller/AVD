[CmdletBinding()]
param (
    [Parameter()]
    [string]$userName,
    [Parameter()]
    [string]$password
)
#try {
    #$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($username,(ConvertTo-SecureString -String $password -AsPlainText -Force))
    #Write-Host "Getting Kerberos Ticket Granting Ticket from Micrsoft Online" | Out-File "C:\Windows\output.txt" -Force
    #$credentials
    New-EventLog –LogName Application –Source “kbrt-test”
    Write-EventLog –LogName Application –Source “kbrt-test” –EntryType Information –EventID 1 –Message “This is start.”
    if ((cmd.exe /c klist get krbtgt) -match 'Server: krbtgt/KERBEROS.MICROSOFTONLINE.COM @ KERBEROS.MICROSOFTONLINE.COM'){
        Write-Host "Good" | Out-File C:\Windows\Temp\output.txt
        Write-EventLog –LogName Application –Source “kbrt-test” –EntryType Information –EventID 1 –Message “This is a test message.”
    }
    else {
        "Not good" | Out-File C:\Windows\Temp\output.txt
    }
    cmd.exe /c klist get krbtgt | Out-File c:\windows\temp\krbt.txt
    #Start-Process -Filepath powershell.exe -verb RunAsUser -ArgumentList "echo hello" #-Credential $credentials
    $output = klist get krbtgt
    $output | Out-File c:\windows\temp\krbt.txt -append
    Write-Host $output
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

