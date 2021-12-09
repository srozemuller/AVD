[CmdletBinding()]
param (
    [Parameter()]
    [string]$profileLocation,

    [Parameter()]
    [string]$officeLocation
)
try {
    Write-Information "Enabling Kerberos functions"
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
    $name = "CloudKerberosTicketRetrievalEnabled"
    $value = 1
    if (!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
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
        if (!(Test-Path $registryPath)) {
            New-Item -Path $fslogixPath -Force | Out-Null
        }
        New-ItemProperty -Path $fslogixPath -Name Enabled -Value 1 -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $fslogixPath -Name VHDLocations -Value $profileLocation -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $fslogixPath -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Information "Configuring fslogix profile location"
    }

    if ($officeLocation) {
        # FSlogix Office container
        Write-Information "Configuring fslogix profile location"
        $fslogixOfficePath = "HKLM:\Software\FSLogix\ODFS"
        if (!(Test-Path $registryPath)) {
            New-Item -Path $fslogixPath -Force | Out-Null
        }
        New-ItemProperty -Path $fslogixOfficePath -Name Enabled -Value 1 -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $fslogixOfficePath -Name VHDLocations -Value $profileLocation -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $fslogixOfficePath -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -PropertyType DWORD -Force | Out-Null
    }
}
catch {
    Throw "configuring FSLogix not succesful, $_"
}
