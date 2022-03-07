Install-Module Az.Accounts
Import-Module Az.Accounts


# AVD ADFS Local AD congfigurator
$roles = ("AD-Certificate", "ADFS-Federation")
$restartNeeded = 0
$roles | Foreach-Object {
    try {
        $feature = Get-WindowsFeature -Name $_
        if (!($feature.Installed)) {
            $installResults = Install-WindowsFeature -Name $_ -IncludeManagementTools
            if ($installResults.RestartNeeded -ne "No") {
                $restartNeeded ++
            }
        }
    }
    catch {
        Throw "$_ not found."
    }
}
if ($restartNeeded -gt 0) {
    Restart-Computer
}

#https://docs.microsoft.com/en-us/powershell/module/adcsdeployment/install-adcscertificationauthority?view=windowsserver2022-ps#syntax
$authorityParameters = @{
    CAType               = "EnterpriseRootCa" 
    CryptoProviderName   = "ECDSA_P256#Microsoft Software Key Storage Provider" 
    KeyLength            = 256 
    HashAlgorithmName    = "SHA256"
    ValidityPeriod       = "Years" 
    ValidityPeriodUnits  = 5
    DatabaseDirectory    = "C:\Windows\system32\CertLog"
    OverwriteExistingKey = $true
}
Install-AdcsCertificationAuthority @authorityParameters


#https://docs.microsoft.com/en-us/powershell/module/adfs/install-adfsfarm?view=windowsserver2019-ps
$adminUsername = "ROZEMULLER\vmjoiner"
$adminPassword = "CWCpHx2ds32vsabp"
$securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $securePassword);
Install-AdfsFarm -CertificateThumbprint $cert.thumbprint -FederationServiceName $DNSname -ServiceAccountCredential $credential

Import-Module ADFS

Add-KdsRootKey -EffectiveTime ((get-date).addhours(-10))
$gsaAccount = "ROZEMULLER\adfssvc`$"
$adfsParams = @{
    CertificateThumbprint         = "494A62EDF6831590871944E05741082A06F5F59A"
    FederationServiceDisplayName  = "Rozemuller"
    FederationServiceName         = "adfs.rozemuller.com"
    GroupServiceAccountIdentifier = $gsaAccount
    OverwriteConfiguration        = $true
}
Install-AdfsFarm @adfsParams 


#https://docs.microsoft.com/en-us/powershell/module/webapplicationproxy/install-webapplicationproxy?view=windowsserver2022-ps
Install-Module WebApplicationProxy
Import-Module WebApplicationProxy

#https://www.powershellgallery.com/packages/ADCSTemplate/1.0.1.0
Install-Script -Name ADCSTemplate	
Import-Module ADCSTemplate
Import-Module ActiveDirectory -Verbose:$false

 
$Server = (Get-ADDomainController -Discover -ForceDiscover -Writable).HostName[0]
$ConfigNC = $((Get-ADRootDSE -Server $Server).configurationNamingContext)
$enrollmentAgent = 'ADFS Enrollment Agent'
$cloneCert = "Exchange Enrollment Agent (Offline Request)"
$exportClone = Export-ADCSTemplate -DisplayName $cloneCert
$import = $exportClone | ConvertFrom-Json
$enrollOID = New-TemplateOID -Server $Server -ConfigNC $ConfigNC
$oa = @{ 
    'msPKI-Cert-Template-OID'       = $enrollOID.TemplateOID 
    "revision"                      = 100
    "msPKI-Template-Minor-Revision" = 3
    "msPKI-Template-Schema-Version" = 2
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.4.1.311.20.2.1")
}
ForEach ($prop in ($import | Get-Member -MemberType NoteProperty)) {
    Switch ($prop.Name) {
        { $_ -in 
            'flags',
            'msPKI-Enrollment-Flag',
            'msPKI-Certificate-Name-Flag',
            'msPKI-Minimal-Key-Size',
            'msPKI-Private-Key-Flag',
            'msPKI-RA-Signature',
            'pKIMaxIssuingDepth',
            'pKIDefaultKeySpec'
        } { 
            $oa.Add($_, [System.Int32]$import.$_); break
                
        }

        { $_ -in 'msPKI-Certificate-Application-Policy',
            'pKIDefaultCSPs',
            'pKIExtendedKeyUsage',
            'pKICriticalExtensions'
        } { $oa.Add($_, [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]$import.$_); break }

        { $_ -in 'pKIExpirationPeriod',
            'pKIKeyUsage',
            'pKIOverlapPeriod'
        } { $oa.Add($_, [System.Byte[]]$import.$_); break }

    }
}
$TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigNC"
New-ADObject -Path $TemplatePath -OtherAttributes $oa -Name $enrollmentAgent.Replace(' ', '') -DisplayName $enrollmentAgent -Type pKICertificateTemplate -Server $Server

 
$adfsName = "ADFS SSO"
$JSON = Export-ADCSTemplate -DisplayName "Smartcard Logon"
$import = $JSON | ConvertFrom-Json
$ssoOID = New-TemplateOID -Server $Server -ConfigNC $ConfigNC
$oa = @{ 
    'msPKI-Cert-Template-OID'              = $ssoOID.TemplateOID 
    "revision"                             = 100
    "msPKI-Certificate-Name-Flag"          = 1
    "flags"                                = 131584
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.4.1.311.20.2.2", "1.3.6.1.5.5.7.3.2")
    "msPKI-RA-Signature"                   = 1
    "msPKI-RA-Application-Policies"        = "1.3.6.1.4.1.311.20.2.1"
    "pKICriticalExtensions"                = @("2.5.29.7", "2.5.29.15")
    "msPKI-Template-Minor-Revision"        = 2
    "msPKI-Template-Schema-Version"        = 2
    "msPKI-Private-Key-Flag"               = 16842752
}
ForEach ($prop in ($import | Get-Member -MemberType NoteProperty)) {
    Switch ($prop.Name) {
        { $_ -in 
            'msPKI-Enrollment-Flag',
            'msPKI-Minimal-Key-Size',
            'pKIMaxIssuingDepth',
            'pKIDefaultKeySpec'
        } { 
            $oa.Add($_, [System.Int32]$import.$_); break
                
        }

        { $_ -in 'msPKI-Certificate-Application-Policy',
            'pKIDefaultCSPs',
            'pKIExtendedKeyUsage'
        } { $oa.Add($_, [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]$import.$_); break }

        { $_ -in 'pKIExpirationPeriod',
            'pKIKeyUsage',
            'pKIOverlapPeriod'
        } { $oa.Add($_, [System.Byte[]]$import.$_); break }

    }
}
$TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigNC"
New-ADObject -Path $TemplatePath -OtherAttributes $oa -Name $adfsName.Replace(' ', '') -DisplayName $adfsName -Type pKICertificateTemplate -Server $Server

$gsaAccount = "ROZEMULLER\adfssvc`$"
Set-ADCSTemplateACL -DisplayName $adfsName -Identity $gsaAccount -Type Allow -Enroll:$true -AutoEnroll:$true
Set-ADCSTemplateACL -DisplayName $enrollmentagent -Identity $gsaAccount -Type Allow -Enroll:$true -AutoEnroll:$true 


# https://docs.microsoft.com/en-us/powershell/module/adcsadministration/add-catemplate?view=windowsserver2022-ps
Import-Module ADCSAdministration 
Add-CATemplate -Name $adfsName.Replace(' ',$null) -Confirm:$false
Add-CATemplate -Name $enrollmentagent.Replace(' ',$null) -Confirm:$false 
Set-AdfsCertificateAuthority -EnrollmentAgentCertificateTemplate "ADFSEnrollmentAgent" -LogonCertificateTemplate "ADFSSSO" -EnrollmentAgent
 

Install-Script ConfigureWVDSSO
$config = ConfigureWVDSSO.ps1 -ADFSAuthority $DNSname

Install-Module Az.KeyVault
Import-Module Az.KeyVault


$keyvaultParams = @{
    keyVaultName      = "kv-rozemuller"
    ResourceGroupName = "RG-ROZ-STOR-01"
    Location          = 'WestEurope'
}
New-AzKeyVault @keyvaultParams
$kvPolicyParams = @{
    VaultName            = $keyvaultParams.keyVaultName 
    ServicePrincipalName = "9cdead84-a844-4324-93f2-b2e6bb768d07"
    PermissionsToSecrets = "GET" 
    PermissionsToKeys    = "SIGN"
}
Set-AzKeyVaultAccessPolicy @kvPolicyParams

Install-Module Az.Avd
Import-Module Az.Avd
$avdParams = @{
    HostpoolName      = "Rozemuller-Hostpool"
    ResourceGroupName = "rg-roz-avd-01" 
}
$avdHostpool = Get-AvdHostPool @avdParams 

$config = @{
    SSOClientSecret = "N3ahjl_jn4HztvHcWX8HvHFeuqYb-vYo4gb7VBO0"
}
$secretParams = @{
    VaultName   = $keyvaultParams.keyVaultName
    Name        = "adfsssosecret" 
    SecretValue = (ConvertTo-SecureString -String $config.SSOClientSecret  -AsPlainText -Force) 
    Tag         = @{ 'AllowedWVDSubscriptions' = $avdHostpool.Id.Split('/')[2] }
}
$secret = Set-AzKeyVaultSecret @secretParams 

$secret = @{
    Id = "https://kv-rozemuller.vault.azure.net/secrets/adfsssosecret/f9ba595f1b2a4708b6bca155ed5d7974"
}
$avdSsoParams = @{
    SsoadfsAuthority            = 'https://adfs.rozemuller.com/adfs'
    SsoClientId                 = "https://www.wvd.microsoft.com" 
    SsoSecretType               = "SharedKeyInKeyVault" 
    SsoClientSecretKeyVaultPath = $secret.Id
}
Update-AvdHostPool @avdParams @avdSsoParams
Get-AvdHostPool @avdParams

Update-AzWvdHostPool @avdParams -SsoadfsAuthority ''
 


Install-Script UnConfigureWVDSSO
UnConfigureWVDSSO.ps1 -WvdWebAppAppIDUri "<WVD Web App URI>" -WvdClientAppApplicationID "a85cf173-4192-42f8-81fa-777a763e6e2c"


ConfigureWVDSSO -WvdWebAppAppIDUri "https://www.wvd.microsoft.com" -WvdClientAppApplicationID "a85cf173-4192-42f8-81fa-777a763e6e2c" -RelyingPartyClientName "Azure Virtual Desktop ADFS Logon SSO" -ADFSAuthority "https://adfs.rozemuller.com/adfs" -RdWebURL "https://rdweb.wvd.microsoft.com/"




https://adfs.rozemuller.com/adfs/oauth2/authorize?response_type=token&client_id=a85cf173-4192-42f8-81fa-777a763e6e2c&resource=https%3A%2F%2Fwww.wvd.microsoft.com&redirect_uri=https%3A%2F%2Fwww.wvd.microsoft.com%2Farm%2Fwebclient%2Fsso.html&login_hint=s_op%40rozemuller.com&client-request-id=e49476e9-d65a-4e03-8d6b-54add63e822d&prompt=select_account&scope=logon_cert


function GetAuthToken($resource) {
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $authHeader = @{
        'Content-Type' = 'application/json'
        Authorization  = 'Bearer ' + $Token
    }
    return $authHeader
}
$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/" 

$clientid = "9af591f7-b23c-47a5-83c8-c03f973695b3"
$secret = "pCS7Q~KKWd7Fnw0dTDomqzZPHxODKfIAWEnI4"
$tenantid = "06b3f1e3-e011-44d4-8a81-80f8514ff2d0"


$Env:AppRegID = "0878fe72-daab-4f23-8c70-d8b4a79f4217";
$Env:AppRegSecret = "1oytxWB1UQ5prJv1gpqD[[Vz_YLcUpe-";
$Env:TenantID = "d521356a-abb1-4636-a534-bc1d63af4072";

$passwd = ConvertTo-SecureString $Env:AppRegSecret -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($Env:AppRegID , $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $Env:TenantID 
$Body = @{    
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientid
    Client_Secret = $secret
} 

$ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token" -Method POST -Body $Body

$token = $ConnectGraph.access_token
$params = @{
    uri     = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"
    method  = "GET"
    headers = @{
        Authorization = 'Bearer ' + $token
    }
}
Invoke-RestMethod @params


C:\Program Files (x86)\Certbot>certbot certonly --standalone --register-unsafely-without-email
Saving debug log to C:\Certbot\log\letsencrypt.log
Please enter the domain name(s) you would like on your certificate (comma and/or
    space separated) (Enter 'c' to cancel): adfs.rozemuller.com
Requesting a certificate for adfs.rozemuller.com
Problem binding to port 80: [WinError 10013] An attempt was made to access a socket in a way forbidden by its access permissions
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile C:\Certbot\log\letsencrypt.log or re-run Certbot with -v for more details.

C:\Program Files (x86)\Certbot>


