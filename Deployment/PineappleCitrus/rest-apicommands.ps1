$token = GetAuthToken -resource "https://management.azure.com"
$subscriptionId = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext.Subscription.id
$ResourceGroupName = 'RG-ROZ-PINEAPPLECITRUS'
$location = "West Europe"
$url = "https://management.azure.com/subscriptions/" + $($subscriptionId) + "/resourcegroups/" + $ResourceGroupName + "?api-version=2021-04-01"
$body = @{
        location = $location
}
$parameters = @{
    uri = $url
    method = 'PUT'
    header = $token
    body = $body | ConvertTo-Json
}
$ResourceGroup = Invoke-RestMethod @Parameters

$networkSecurityGroupName = "NSG-PineappleCitrus"
$nsgUrl = "https://management.azure.com/subscriptions/" + $($subscriptionId) + "/resourcegroups/" + $ResourceGroupName + "/providers/Microsoft.Network/networkSecurityGroups/" + $networkSecurityGroupName + "?api-version=2020-11-01"
$nsgBody = @{
    location = $location
    properties = @{
        
    }
}
$nsgParameters = @{
    uri = $nsgUrl
    method = 'PUT'
    header = $token
    body = $nsgBody | ConvertTo-Json
}
$networkSecurityGroup = Invoke-WebRequest @nsgParameters

$vnetName = "vnet-PineappleCitrus"
$vnetUrl = "https://management.azure.com/subscriptions/" + $($subscriptionId) + "/resourcegroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $vnetName + "?api-version=2021-02-01"
$vnetBody = @{
    location   = $location
    properties = @{
        AddressSpace = @{ 
            addressPrefixes = @(
                "10.0.0.0/16"
            )
        }
        dhcpOptions  = @{
            dnsServers = @(
                "10.1.3.4"
            )
        }
        subnets      = @(
            @{
                name       = 'defaultSubnet'
                properties = @{
                    addressPrefix        = "10.0.1.0/24"
                }
            },
            @{
                name       = 'CitrusSubnet'
                properties = @{
                    addressPrefix        = "10.0.2.0/24"
                }
            }
        )
    }
}
$vnetParameters = @{
    uri    = $vnetUrl
    method = 'PUT'
    header = $token
    body   = $vnetBody | ConvertTo-Json -Depth 4
}
$virtualNetwork = Invoke-WebRequest @vnetParameters

$galleryName = "Citrus_Gallery"
$galleryUrl = "https://management.azure.com/subscriptions/" + $($subscriptionId) + "/resourcegroups/" + $ResourceGroupName + "/providers/Microsoft.Compute/galleries/" + $galleryName + "?api-version=2021-03-01"
$galleryBody = @{
    location   = $location
    properties = @{
        description = "A really fresh gallery with pineapple and citrus."
    }
}
$galleryParameters = @{
    uri    = $galleryUrl
    method = 'PUT'
    header = $token
    body   = $galleryBody | ConvertTo-Json -Depth 4
}
$sharedImageGallery = Invoke-WebRequest @galleryParameters

$sharedImageGalleryInfo = ($sharedImageGallery | ConvertFrom-Json).id
$galleryImageName = "Win10-Pineapple-Image"
$galleryImageUrl = "https://management.azure.com/" + $sharedImageGalleryInfo + "/images/" + $galleryImageName + "?api-version=2021-03-01"
$galleryImageBody = @{
    location   = $location
    properties = @{
        identifier = @{
            offer = "Pineapple"
            publisher = "Rozemuller"
            sku = "Citrus"
        }
        osState  = "Generalized"
        osType = "Windows"
        description = "Citrus are lovely"
        hyperVGeneration = "V2"
    }
}
$galleryImageParameters = @{
    uri    = $galleryImageUrl
    method = 'PUT'
    header = $token
    body   = $galleryImageBody | ConvertTo-Json -Depth 4
}
$sharedImageGalleryImage = Invoke-WebRequest @galleryImageParameters

$vmName = "vm-Pineapple"
$vmUrl = "https://management.azure.com/" + $ResourceGroupUrl + "/providers/Microsoft.Compute/virtualMachines/" + $vmName + "?api-version=2021-03-01"
$vmBody = @{
    location   = $location
    properties = @{
        hardwareProfile = @{
            vmSize = "Standard_B2ms"
        }
        networkProfile  = @{
            networkInterfaces = @(
                @{
                    id         = $nicId
                    properties = @{
                        primary = $true
                    }
                }
            )
        }
        storageProfile  = @{
            imageReference = @{
                sku       = "21h1-ent-g2"
                version   = "latest"
                offer     = "Windows-10"
                publisher = "MicrosoftWindowsDesktop"
            }
        
            osDisk         = @{
                caching      = "ReadWrite"
                managedDisk  = @{
                    storageAccountType = "Standard_LRS"
                }
                name         = "os-pineapple"
                createOption = "FromImage"
            }
        }
        osProfile       = @{
            adminUsername = "citrus-user"
            computerName  = $vmName
            adminPassword = "VeryS3cretP@44W0rd!"
        }
    }
}
$vmParameters = @{
    uri    = $vmUrl 
    method = 'PUT'
    header = $token
    body   = $vmBody | ConvertTo-Json -Depth 5
}
$virtualMachine = Invoke-WebRequest @vmParameters

$script = [System.Collections.ArrayList]@()
$script.Add('$sysprep = "C:\Windows\System32\Sysprep\Sysprep.exe"')
$script.Add('$arg = "/generalize /oobe /shutdown /quiet /mode:vm"')
$script.Add('Start-Process -FilePath $sysprep -ArgumentList $arg')
$scriptBody = @{
    commandId = "RunPowerShellScript"
    script    = $script
}
$virtualMachineId = ($virtualMachine | ConvertFrom-Json).id
$url = "https://management.azure.com" + $virtualMachineId  + "/runCommand?api-version=2021-03-01"
$parameters = @{
    URI     = $url 
    Method  = "POST"
    Body    = $scriptBody | ConvertTo-Json
    Headers = $token
}
$executeSysprep = Invoke-WebRequest @parameters

$generalizeUrl = "https://management.azure.com" + $virtualMachineId  + "/generalize?api-version=2021-03-01"
$generalizeParameters = @{
    uri    = $generalizeUrl
    method = 'POST'
    header = $token
}
$generalizeVM = Invoke-WebRequest @generalizeParameters

$sharedImageGalleryImageUrl = ($sharedImageGalleryImage | ConvertFrom-Json).id
$galleryVersionName = Get-Date -Format yyyy.MM.dd
$versionUrl = "https://management.azure.com" + $sharedImageGalleryImageUrl + "/versions/" + $galleryVersionName + "?api-version=2021-03-01"
$versionBody = @{
    location   = $location
    properties = @{
        storageProfile = @{
            source = @{
                id = $virtualMachineId
            }
        }
    }
}
$imageVersionParameters = @{
    uri    = $versionUrl 
    method = 'PUT'
    header = $token
    body   = $versionBody | ConvertTo-Json -Depth 5
}
$imageVersion = Invoke-WebRequest @imageVersionParameters

$hostpoolInfo = ($hostpool | ConvertFrom-Json)
$token = $hostpoolInfo.properties.registrationInfo.token

$applicationGroupName = "Pinapple-applications"
$applicationGroupUrl = "https://management.azure.com" + $ResourceGroupUrl + "/providers/Microsoft.DesktopVirtualization/applicationGroups/" + $applicationGroupName + "?api-version=2021-01-14-preview"
$applicationGroupBody = @{
    location   = $location
    properties = @{
        applicationGroupType = 'Desktop'
        hostPoolArmPath = $hostpoolInfo.id
        description = 'A nice group with citrus fruits'
        friendlyName = 'Pineapple Application Group'
    }
}
$applicationGroupParameters = @{
    uri    = $applicationGroupUrl 
    method = 'PUT'
    header = $token
    body   = $applicationGroupBody | ConvertTo-Json -Depth 5
}
$applicationGroup = Invoke-WebRequest @applicationGroupParameters

$applicationGroupInfo = ($applicationGroup | ConvertFrom-Json)
$workspaceName = "Citrus-Workspace"
$workspaceUrl = "https://management.azure.com" + $ResourceGroupUrl + "/providers/Microsoft.DesktopVirtualization/workspaces/" + $workspaceName + "?api-version=2021-01-14-preview"
$workspaceBody = @{
    location   = $location
    properties = @{
        applicationGroupReferences = @(
                $applicationGroupInfo.id
        )
        description = 'A workspace with nice citrus fruits'
        friendlyName = 'Citrus Workspace'
    }
}
$workspaceParameters = @{
    uri    = $workspaceUrl 
    method = 'PUT'
    header = $token
    body   = $workspaceBody | ConvertTo-Json -Depth 5
}
$workspace = Invoke-WebRequest @workspaceParameters

$LAWorkspace = "log-analytics-avd-" + (Get-Random -Maximum 99999)
$LawsBody = @{
    location   = $location
    properties = @{
        retentionInDays = "30"
        sku             = @{
            name = "PerGB2018"
        }
    }
}
$lawsUrl = "https://management.azure.com" + $ResourceGroupUrl + "/providers/Microsoft.OperationalInsights/workspaces/" + $LAWorkspace + "?api-version=2020-08-01"
$loganalyticsParameters = @{
    URI     = $lawsUrl 
    Method  = "PUT"
    Body    = $LawsBody | ConvertTo-Json
    Headers = $token
}
$laws = Invoke-WebRequest @loganalyticsParameters

$diagnosticsBody = @{
    Properties = @{
        workspaceId = $Laws.id
        logs        = @(
            @{
                Category = 'Error'
                Enabled  = $true
            },
            @{
                Category = 'Connection'
                Enabled  = $true
            }
        )
    }
}  
$diagnosticsUrl = "https://management.azure.com/" + $($hostpoolInfo.Id) + "/providers/microsoft.insights/diagnosticSettings/" + $LAWorkspace + "?api-version=2017-05-01-preview"  
$diagnosticsParameters = @{
    uri     = $diagnosticsUrl
    Method  = "PUT"
    Headers = $token
    Body    = $diagnosticsBody | ConvertTo-Json -Depth 4
}
$diagnostics = Invoke-WebRequest @diagnosticsParameters

$vmName = 'pinci-0'
$nicName = "nic-"+$vmName
$nicUrl = "https://management.azure.com/" + $ResourceGroupUrl + "/providers/Microsoft.Network/networkInterfaces/" + $nicName + "?api-version=2021-02-01"
$nicBody = @{
    location   = $location
    properties = @{
        ipConfigurations = @(
            @{
                name       = "ipconfig1"
                properties = @{
                    subnet = @{
                        id = $subnetId
                    }
                }
            }
        )
    }
}
$nicParameters = @{
    uri    = $nicUrl
    method = 'PUT'
    header = $token
    body   = $nicBody | ConvertTo-Json -Depth 5
}
$networkInterface = Invoke-WebRequest @nicParameters
$nicId = ($networkInterface | ConvertFrom-Json).id

$imageInfo = ($sharedImageGalleryImage | ConvertFrom-Json)
$vmUrl = "https://management.azure.com/" + $ResourceGroupUrl + "/providers/Microsoft.Compute/virtualMachines/" + $vmName + "?api-version=2021-03-01"
$sessionHostBody = @{
    location   = $location
    properties = @{
        hardwareProfile = @{
            vmSize = "Standard_B2ms"
        }
        networkProfile  = @{
            networkInterfaces = @(
                @{
                    id         = $nicId
                    properties = @{
                        primary = $true
                    }
                }
            )
        }
        storageProfile  = @{
            imageReference = @{
               id = $imageInfo.id
            }
            osDisk         = @{
                caching      = "ReadWrite"
                managedDisk  = @{
                    storageAccountType = "Standard_LRS"
                }
                name         = "os-"+$vmName
                createOption = "FromImage"
            }
        }
        osProfile       = @{
            adminUsername = "citrus-user"
            computerName  = $vmName
            adminPassword = "VeryS3cretP@44W0rd!"
        }
    }
}
$sessionHostParameters = @{
    uri    = $vmUrl 
    method = 'PUT'
    header = $token
    body   = $sessionHostBody | ConvertTo-Json -Depth 5
}
$sessionHost = Invoke-WebRequest @sessionHostParameters

$domain = 'domain.local'
$ouPath = "OU=Computers,OU=AVD,DC=domain,DC=local"
$vmjoinerUser = 'vmjoiner@domain.local'
$securePassword = 'verySecretPasswordforDomain@1'

$domainJoinExtensionName = "JsonADDomainExtension"
$domainJoinUrl = "https://management.azure.com/" + $ResourceGroupUrl + "/providers/Microsoft.Compute/virtualMachines/" + $vmName + "/extensions/" + $domainJoinExtensionName + "?api-version=2021-03-01"
$domainJoinBody = @{
    location   = $location
    properties = @{
        publisher = "Microsoft.Compute"
        type = "JsonADDomainExtension"
        typeHandlerVersion = "1.3"
        settings = @{
            name = $domain
            ouPath = $ouPath
            user = $vmjoinerUser
            restart = $true
            options = "3"
        }
        protectedSettings = @{
            password = $securePassword
        }
    }
}
$domainJoinParameters = @{
    uri    = $domainJoinUrl
    method = 'PUT'
    header = $token
    body   = $domainJoinBody | ConvertTo-Json -Depth 5
}
$domainJoin = Invoke-WebRequest @domainJoinParameters

$avdExtensionName = "dscextension"
$artifactLocation = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"
$avdExtensionUrl = "https://management.azure.com/" + $ResourceGroupUrl + "/providers/Microsoft.Compute/virtualMachines/" + $vmName + "/extensions/" + $avdExtensionName + "?api-version=2021-03-01"
$avdExtensionBody = @{
    location   = $location
    properties = @{
        publisher = "Microsoft.Powershell"
        type = "DSC"
        typeHandlerVersion = "2.73"
        settings = @{
            modulesUrl = $artifactLocation
            configurationFunction = "Configuration.ps1\\AddSessionHost"
            properties = @{
                hostPoolName = $hostpoolInfo.name
                registrationInfoToken = $hostpoolInfo.properties.registrationInfo.token
            }
        }
    }
}
$avdExtensionParameters = @{
    uri    = $avdExtensionUrl
    method = 'PUT'
    header = $token
    body   = $avdExtensionBody | ConvertTo-Json -Depth 5
}
$avdExtension = Invoke-WebRequest @avdExtensionParameters 