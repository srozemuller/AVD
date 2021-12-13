[CmdletBinding()]
param (
    [Parameter()]
    [string]$userName,
    [Parameter()]
    [string]$password
)

$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList @($username, (ConvertTo-SecureString -String $password -AsPlainText -Force))
#New-EventLog -LogName Application -Source "kbrt-test"
Write-EventLog -LogName Application -Source "kbrt-test" -EntryType Information -EventID 1 -Message "This is start., $credentials"
C:\Test\PsExec.exe -h -u $userName -p $password /accepteula cmd /c "klist get krbtgt > c:\test\out2.txt"
