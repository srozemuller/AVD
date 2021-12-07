param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Domain
)

try {
    if ([System.String]::IsNullOrEmpty($Domain)) {
        $domainInformation = Get-ADDomain
        $Domain = $domainInformation.DnsRoot
    }
    else {
        $domainInformation = Get-ADDomain -Server $Domain
    }

    $AdModule = Get-Module ActiveDirectory;
    if ($null -eq $AdModule) {
        Import-Module ActiveDirectory
        Write-Error "Please install and/or import the ActiveDirectory PowerShell module." -ErrorAction Stop;
    }

    $returnObject = [pscustomobject]@{
        domainGuid        = $domainInformation.ObjectGUID.ToString()
        domainName        = $domainInformation.DnsRoot
        domainSid         = $domainInformation.DomainSID.Value
        forestName        = $domainInformation.Forest
        netBiosDomainName = $domainInformation.DnsRoot
        azureStorageSid   = $domainSid + "-123454321";
    }
    $returnObject
}
catch {
    Write-Host $_.Exception.ToString()
}