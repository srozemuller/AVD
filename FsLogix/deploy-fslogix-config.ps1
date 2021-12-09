[CmdletBinding()]
param (
    [Parameter()]
    [string]$profileLocation,

    [Parameter()]
    [string]$officeLocation
)
try {
    Write-Information "Enabling Kerberos functions"
    cmd /c "reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters /v CloudKerberosTicketRetrievalEnabled /t REG_DWORD /d 1"
    cmd /c "dsregcmd /RefreshPrt"
}   
catch {
    Throw "Enabling Kerberos functions not succesful, $_"
}
try {
    if ($profileLocation) {
        # Fslogix profile container
        Write-Information "Configuring fslogix profile location"
        cmd /c "reg add HKLM\Software\FSLogix\Profiles /v Enabled /t REG_DWORD /d 1"
        cmd /c "reg add HKLM\Software\FSLogix\Profiles /v VHDLocations /t REG_SZ /d $profileLocation"
        cmd /c "reg add HKLM\Software\FSLogix\Profiles /v DeleteLocalProfileWhenVHDShouldApply /t REG_DWORD /d 1"
    }

    if ($officeLocation) {
        # FSlogix Office container
        Write-Information "Configuring fslogix profile location"
        cmd /c "reg add HKLM\Software\FSLogix\ODFC /v Enabled /t REG_DWORD /d 1"
        cmd /c "reg add HKLM\Software\FSLogix\ODFC /v VHDLocations /t REG_SZ /d $officeLocation"
        cmd /c "reg add HKLM\Software\FSLogix\ODFC /v DeleteLocalProfileWhenVHDShouldApply /t REG_DWORD /d 1"
    }
}
catch {
    Throw "configuring FSLogix not succesful, $_"
}

