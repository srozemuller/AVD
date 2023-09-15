Connect-AzAccount

$token = Get-AzAccessToken

$header = @{
    'Authorization' = 'Bearer ' + $token.Token
    'Content-Type' = 'application/json'
}

$body =  @"
{
    "location": "eastus",
    "properties": {
      "templateLink": {
        "uri": "https://raw.githubusercontent.com/srozemuller/AVD/main/Deployment/JuicyJungleBeast/main.json"
      },
      "ParametersLink": {
        "uri": "https://raw.githubusercontent.com/srozemuller/AVD/main/Deployment/JuicyJungleBeast/Parameters/avd-environment.parameters.json"
      },
      "mode": "Incremental"
    }
  }
"@
$url = "https://management.azure.com/subscriptions/6d3c408e-b617-44ed-bc24-280249636525/providers/Microsoft.Resources/deployments/avd-deploy?api-version=2021-04-01"
Invoke-RestMethod -Method put -Headers $header -body $body -Uri $url
