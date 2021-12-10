try {
    Write-Information "Getting Kerberos Ticket Granting Ticket from Micrsoft Online"
    cmd /c "klist purge"
    $output = cmd.exe /c klist get krbtgt
    $output
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

