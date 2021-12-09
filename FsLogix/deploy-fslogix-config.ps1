[CmdletBinding()]
param (
    [Parameter()]
    [string]$profileLocation,

    [Parameter()]
    [string]$officeLocation
)
try {
    Write-Information "Enabling Kerberos functions"
    $kerberosPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
    if (!(Test-Path $kerberosPath)) {
        New-Item -Path $kerberosPath -Force | Out-Null
    }
    New-ItemProperty -Path $kerberosPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1 -PropertyType DWORD -Force | Out-Null

    $aadAccountPath = "HKLM:\Software\Policies\Microsoft\AzureADAccount"
    if (!(Test-Path $aadAccountPath)) {
        New-Item -Path $aadAccountPath -Force | Out-Null
    }
    New-ItemProperty -Path $aadAccountPath -Name "LoadCredKeyFromProfile" -Value 1 -PropertyType DWORD -Force | Out-Null

    Write-Information "Resetting Primary Refresh Token"
    cmd /c "dsregcmd /RefreshPrt"
}   
catch {
    Throw "Enabling Kerberos functions not succesful, $_"
}
try {
    if ($profileLocation) {
        # Fslogix profile container
        $fslogixPath = "HKLM:\Software\FSLogix\Profiles"
        if (!(Test-Path $fslogixPath)) {
            New-Item -Path $fslogixPath -Force | Out-Null
        }
        New-ItemProperty -Path $fslogixPath -Name Enabled -Value 1 -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $fslogixPath -Name VHDLocations -Value $profileLocation -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $fslogixPath -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Information "Configuring fslogix profile location"
    }
}
catch {
    Throw "Configuring FSLogix profile location not succesfully, $_"
}

try {
    if ($officeLocation) {
        # FSlogix Office container
        Write-Information "Configuring fslogix profile location"
        $fslogixOfficePath = "HKLM:\Software\FSLogix\ODFS"
        if (!(Test-Path $fslogixOfficePath)) {
            New-Item -Path $fslogixOfficePath -Force | Out-Null
        }
        New-ItemProperty -Path $fslogixOfficePath -Name Enabled -Value 1 -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $fslogixOfficePath -Name VHDLocations -Value $officeLocation -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $fslogixOfficePath -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -PropertyType DWORD -Force | Out-Null
    }
    
}
catch {
    Throw "Configuring FSLogix office location not succesfully, $_"
}

