dsregcmd /RefreshPrt

try {
    cmd /c "reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters /v CloudKerberosTicketRetrievalEnabled /t REG_DWORD /d 1"
    cmd /c "dsregcmd /RefreshPrt"
}   
catch {
    "Key added"
}
