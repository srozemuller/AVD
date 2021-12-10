[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials
)
try {
    Write-Information "Getting Kerberos Ticket Granting Ticket from Micrsoft Online"
    #Invoke-Command -Credential $Credentials -ComputerName $env:COMPUTERNAME -ScriptBlock {cmd /c "klist purge"}
    Start-Process "powershell" -ArgumentList "klist purge" -Credential $credentials
    Start-Process "powershell" -ArgumentList "klist get krbtgt" -Credential $credentials -NoNewWindow -Wait -WorkingDirectory '.' -RedirectStandardOutput "output.txt"
    $output = Get-Content ".\output.txt"
    if ($output | Select-String -Pattern "Server: krbtgt/KERBEROS.MICROSOFTONLINE.COM @ KERBEROS.MICROSOFTONLINE.COM" -CaseSensitive -SimpleMatch) { 
        Write-Host "Got ticket from KERBEROS.MICROSOFTONLINE.COM" 
    }
    else {
        Throw "No ticket found from KERBEROS.MICROSOFTONLINE.COM"
    }
}   
catch {
    Throw "Kerberos check failed, $_"
}