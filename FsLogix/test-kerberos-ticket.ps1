try {
    Write-Information "Getting Kerberos Ticket Granting Ticket from Micrsoft Online"
    cmd /c "klist purge"
    $output = cmd.exe /c klist get krbtgt
    if ($output | Select-String -Pattern 'Server: krbtgt/KERBEROS.MICROSOFTONLINE.COM @ KERBEROS.MICROSOFTONLINE.COM' -CaseSensitive -SimpleMatch) { 
        "Got ticket from KERBEROS.MICROSOFTONLINE.COM" 
    }
    else {
        Throw "No ticket found from KERBEROS.MICROSOFTONLINE.COM"
    }
}   
catch {
    Throw "Kerberos "
}

