$azureUrl = "https://management.azure.com"
$accessToken = Get-AzAccessToken -resource $azureUrl
$token = @{
    Authorization = "Bearer $($accessToken.Token)"
    "content-type" = "application/json"
}
$subscriptionId = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext.Subscription.id
$resourceGroupName = 'rg-avd-thebeast'
$location = "West Europe"
$url = "https://management.azure.com/subscriptions/{0}/resourcegroups/{1}?api-version=2023-07-01" -f $subscriptionId, $resourceGroupName
$body = @{
        location = $location
}
$parameters = @{
    uri = $url
    method = 'PUT'
    header = $token
    body = $body | ConvertTo-Json
}
$resourceGroup = Invoke-RestMethod @Parameters


$vnetName = "vnet-private-thebeast"
$vnetUrl = "{0}/{1}/providers/Microsoft.Network/virtualNetworks/{2}?api-version=2023-02-01" -f $azureUrl, $resourceGroup.id, $vnetName
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



$networkSecurityGroupName = "nsg-private-thebeast"
$nsgUrl = "{0}/{1}/providers/Microsoft.Network/networkSecurityGroups/{2}?api-version=2023-02-01" -f $azureUrl, $resourceGroup.id, $networkSecurityGroupName
$nsgBody = @{
    location = $location
    properties = @{}
}
$nsgParameters = @{
    uri = $nsgUrl
    method = 'PUT'
    header = $token
    body = $nsgBody | ConvertTo-Json
}
$networkSecurityGroup = Invoke-WebRequest @nsgParameters


$galleryName = "BeastyGallery"
$galleryUrl = "{0}/{1}/providers/Microsoft.Compute/galleries/{2}?api-version=2023-07-03" -f $azureUrl, $resourceGroup.id, $galleryName
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
$galleryImageName = "Win11-Juicy_Image"
$galleryImageUrl = "{0}/{1}/images/{2}?api-version=2023-07-03" -f $azureUrl, $sharedImageGalleryInfo, $galleryImageName
$galleryImageBody = @{
    location   = $location
    properties = @{
        identifier = @{
            offer = "Beasty"
            publisher = "Rozemuller"
            sku = "Juice"
        }
        osState  = "Generalized"
        osType = "Windows"
        description = "Dare to use this one!"
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




$vmName = "theBeastVM"
$nicName = "nic-"+$vmName
$nicUrl = "{0}/{1}/providers/Microsoft.Network/networkInterfaces/{2}?api-version=2021-02-01" -f $azureUrl, $resourceGroup.id, $nicName
$nicBody = @{
    location   = $location
    properties = @{
        ipConfigurations = @(
            @{
                name       = "ipconfig1"
                properties = @{
                    subnet = @{
                        id = ($virtualNetwork | Convertfrom-Json).properties.subnets[0].id
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

$vmUrl = "{0}/{1}/providers/Microsoft.Compute/virtualMachines/{2}?api-version=2023-03-01" -f $azureUrl, $resourceGroup.id, $vmName
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
                        deleteOption = "Delete"
                    }
                }
            )
        }
        storageProfile  = @{
            imageReference = @{
                sku       = "win11-22h2-ent"
                version   = "latest"
                offer     = "Windows-11"
                publisher = "MicrosoftWindowsDesktop"
            }
            osDisk         = @{
                caching      = "ReadWrite"
                managedDisk  = @{
                    storageAccountType = "Standard_LRS"
                }
                name         = "os-pineapple"
                createOption = "FromImage"
                deleteOption = "Delete"
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
$url = "{0}{1}/runCommand?api-version=2023-03-01" -f $azureUrl, $virtualMachineId
$parameters = @{
    URI     = $url 
    Method  = "POST"
    Body    = $scriptBody | ConvertTo-Json
    Headers = $token
}
$executeSysprep = Invoke-WebRequest @parameters

$generalizeParameters = @{
    uri    =  "{0}{1}/generalize?api-version=2023-03-01" -f $azureUrl, $virtualMachineId
    method = 'POST'
    header = $token
}
$generalizeVM = Invoke-WebRequest @generalizeParameters

$sharedImageGalleryImageUrl = ($sharedImageGalleryImage | ConvertFrom-Json).id
$galleryVersionName = Get-Date -Format yyyy.MM.dd
$versionUrl = "{0}{1}/versions/{2}?api-version=2022-03-03" -f $azureUrl, $sharedImageGalleryImageUrl, $galleryVersionName
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

$hostpoolName = "hp-thebeast"
$hostpoolBody = @{
    location   = $location
    properties = @{
        friendlyName = "Beasty Hostpool"
        description  = "A hostpool with security stronger that the strengh of the Beast"
        customRdpProperty = "audiocapturemode:i:1;audiomode:i:0;camerastoredirect:s:*;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectdirectx:i:1;redirectposdevices:i:0;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;session bpp:i:32;span monitors:i:1;use multimon:i:1;"
        hostpoolType = "Personal"
        personalDesktopAssignmentType = "Automatic"
        preferredAppGroupType = "Desktop"
        registrationInfo = @{
            expirationTime = $(Get-Date).AddHours(24)
            registrationTokenOperation = "Update"
        }
        startVMOnConnect = $true
        validationEnvironment = $true
        vmTemplate = $(@{
            imageVersionId = ($imageVersion | ConvertFrom-Json).name
            galleryImageId = $galleryImageName
            galleryId      = $galleryName
        }) | ConvertTo-Json -Depth 5 -Compress
        hostpoolPublicNetworkAccess = "Disabled"
    }
}
$hostpoolParameters = @{
    uri    = "{0}{1}/providers/Microsoft.DesktopVirtualization/hostPools/{2}?api-version=2022-02-10-preview" -f $azureUrl, $resourceGroup.id, $hostpoolName
    method = 'PUT'
    header = $token
    body   = $hostpoolBody | ConvertTo-Json -Depth 5
}
$hostpool = Invoke-WebRequest @hostpoolParameters

$hostpoolInfo = ($hostpool | ConvertFrom-Json)


$applicationGroupName = "Juicy-applications"
$applicationGroupUrl = "{0}{1}/providers/Microsoft.DesktopVirtualization/applicationGroups/{2}?api-version=2022-02-10-preview" -f $azureUrl, $resourceGroup.id, $applicationGroupName
$applicationGroupBody = @{
    location   = $location
    properties = @{
        applicationGroupType = 'Desktop'
        hostPoolArmPath = $hostpoolInfo.id
        description = 'Welcome to the jungle with juicy applications'
        friendlyName = 'Juicy Application Group'
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
$workspaceName = "TheJungleWorkspace"
$workspaceUrl = "{0}{1}/providers/Microsoft.DesktopVirtualization/workspaces/{2}?api-version=2022-02-10-preview" -f $azureUrl, $resourceGroup.id, $workspaceName
$workspaceBody = @{
    location   = $location
    properties = @{
        applicationGroupReferences = @(
                $applicationGroupInfo.id
        )
        description = 'A workspace in the jungle with juicy applications'
        friendlyName = 'The Jungle'
    }
}
$workspaceParameters = @{
    uri    = $workspaceUrl 
    method = 'PUT'
    header = $token
    body   = $workspaceBody | ConvertTo-Json -Depth 5
}
$workspace = Invoke-WebRequest @workspaceParameters

$laWorkspace = "log-analytics-avd-" + (Get-Random -Maximum 99999)
$lawsBody = @{
    location   = $location
    properties = @{
        retentionInDays = "30"
        sku             = @{
            name = "PerGB2018"
        }
    }
}
$lawsUrl = "{0}{1}/providers/Microsoft.OperationalInsights/workspaces/{2}?api-version=2022-10-01" -f $azureUrl, $resourceGroup.id, $laWorkspace
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