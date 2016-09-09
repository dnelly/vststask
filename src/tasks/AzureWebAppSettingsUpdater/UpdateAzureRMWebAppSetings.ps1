[CmdletBinding()]
param()


Write-Host "Starting Updates."
# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation

# function GetAppSettings ([xml]$configFile) {
#     $tempappsettings = @{}
#     write-host "Starting Appsettings"
#     echo $configFile.configuration.appSettings.add
#     foreach($setting in $configFile.configuration.appSettings.add)
#     {
#         $tempappsettings.Add($setting.key,$setting.value)
#     }

#     write-host "Finished Appsettings"

#     return [hashtable]$tempappsettings
# }

# function GetAppSettingNames ([xml]$configFile) {
#     $tempappsettingsNames = @()

#     write-host "Getting Appsettings Names"
#     echo $configFile.configuration.appSettings.add
#     foreach($setting in $configFile.configuration.appSettings.add)
#     {
#         $tempappsettingsNames =$tempappsettingsNames + $setting.key
#     }

#     write-host "Finished Getting Appsettings Names"
    
#     return $tempappsettingsNames
# }

# function GetConnectionStrings ([xml]$configFile) {
#     $tempconnections = @{}
#     write-host "Starting Conectionstrings"
#     echo $configFile.configuration.connectionStrings.add
#     foreach($setting in $configFile.configuration.connectionStrings.add)
#     {        
#         if ($UseSQLServerType -eq "true") {
#             if ($SQLServerConnectionNames.split(";").split(",").contains($setting.name)) {
#                 $connectionType = "SqlServer"
#             }
#         }
#         elseif ($UseAzureSQLType -eq "true") {
#             if ($AzureSQLConnectionNames.split(";").split(",").contains($setting.name)) {
#                 $connectionType = "AzureSQL"
#             }            
            
#         }
#         elseif ($UseMySqlType -eq "true") {
#             if ($MySQLConnectionNames.split(";").split(",").contains($setting.name)) {
#                 $connectionType = "MySql"
#             }
            
#         }
#         elseif ($UseCustomType -eq "true") {
#             if ($CustomTypeConnectionNames.split(";").split(",").contains($setting.name)) {
#                 $connectionType = "Custom"
#             }            
            
#         }

#         $tempconnections[$setting.name] = @{Type = $connectionType;Value = $setting.connectionString}
#     }
#     write-host "Finished Parsing ConnectionString"
#     return [hashtable]$tempconnections
# }

# function GetConnectionStringNames ([xml]$configFile) {
#     $tempconnectionNames = @()
#     write-host "Getting Conectionstrings Names"
#     echo $configFile.configuration.connectionStrings.add
#     foreach($setting in $configFile.configuration.connectionStrings.add)
#     {        
#         $tempconnectionNames = $tempconnectionNames + $setting.name
#     }
#     write-host "Finished Getting ConnectionString Names"
#     return $tempconnectionNames
# }

# function GetConnectionType ([string]$settingName) {
#             if ($UseSQLServerType -eq "true") {
#             if ($SQLServerConnectionNames.split(";").split(",").contains($settingName)) {
#                 $connectionType = "SqlServer"
#             }
#         }
#         elseif ($UseAzureSQLType -eq "true") {
#             if ($AzureSQLConnectionNames.split(";").split(",").contains($settingName)) {
#                 $connectionType = "AzureSQL"
#             }            
            
#         }
#         elseif ($UseMySqlType -eq "true") {
#             if ($MySQLConnectionNames.split(";").split(",").contains($settingName)) {
#                 $connectionType = "MySql"
#             }
            
#         }
#         elseif ($UseCustomType -eq "true") {
#             if ($CustomTypeConnectionNames.split(";").split(",").contains($settingName)) {
#                 $connectionType = "Custom"
#             }            
            
#         }

#         $connectionType
# }


try {
    # Set the working directory.
    $cwd = Get-VstsInput -Name cwd -Require
    Assert-VstsPath -LiteralPath $cwd -PathType Container
    Write-Host "Setting working directory to '$cwd'."
    Set-Location $cwd

    write-host "Getting variables"
    [string]$WebAppName = Get-VstsInput -Name WebAppName -Require
    [string]$ResourceGroup = Get-VstsInput -Name ResourceGroupName -Require
    [string]$TransformConfigFile = Get-VstsInput -Name TransformConfigFile -Require
    [string]$Slot = Get-VstsInput -Name SlotName -Require
    [string]$SourceSlotName = Get-VstsInput -Name SourceSlotName
    [string]$SwapSlots = Get-VstsInput -Name SwapSlots

    [string]$UseAppsettings = Get-VstsInput -Name UseAppsettings
    [string]$UseConnectionStrings = Get-VstsInput -Name UseConnectionStrings
    [string]$UseSQLServerType = Get-VstsInput -Name SQLServerType
    [string]$SQLServerConnectionNames = Get-VstsInput -Name SQLServerConnectionNames
    [string]$UseMySqlType = Get-VstsInput -Name MySqlType
    [string]$MySQLConnectionNames = Get-VstsInput -Name MySQLConnectionNames
    [string]$UseAzureSQLType = Get-VstsInput -Name AzureSQLType
    [string]$AzureSQLConnectionNames = Get-VstsInput -Name AzureSQLConnectionNames
    [string]$UseCustomType = Get-VstsInput -Name CustomType
    [string]$CustomTypeConnectionNames = Get-VstsInput -Name CustomTypeConnectionNames

    function GetConnectionType ([string]$settingName) {
                if ($UseSQLServerType -eq "true") {
                if ($SQLServerConnectionNames.split(";").split(",").contains($settingName)) {
                    $connectionType = "SqlServer"
                }
            }
            elseif ($UseAzureSQLType -eq "true") {
                if ($AzureSQLConnectionNames.split(";").split(",").contains($settingName)) {
                    $connectionType = "AzureSQL"
                }            
                
            }
            elseif ($UseMySqlType -eq "true") {
                if ($MySQLConnectionNames.split(";").split(",").contains($settingName)) {
                    $connectionType = "MySql"
                }
                
            }
            elseif ($UseCustomType -eq "true") {
                if ($CustomTypeConnectionNames.split(";").split(",").contains($settingName)) {
                    $connectionType = "Custom"
                }            
                
            }

            $connectionType
    }

    Write-Host "Web App ame ->                  $WebAppName"
    Write-Host "Current Working directory ->    $cwd"
    Write-Host "Resource Group ->               $ResourceGroup"
    Write-Host "Transform Config File ->        $TransformConfigFile"
    Write-Host "Slot Name ->                    $Slot"
    Write-Host "Source Slot Name ->             $SourceSlotName"
    Write-Host "Swap Slots ->                   $SwapSlots"

    Write-Host "Use Appsettings->                $UseAppsettings"
    Write-Host "Use Connection Strings ->        $UseConnectionStrings"
    Write-Host "SQL Server Type ->               $SQLServerType"
    Write-Host "SQL Server Connection Names ->   $SQLServerConnectionNames"
    Write-Host "My Sql Type ->                   $MySqlType"
    Write-Host "MySQL Connection Names ->        $MySQLConnectionNames"
    Write-Host "Azure SQL Type ->                $AzureSQLType"
    Write-Host "Azure SQL Connection Names ->    $AzureSQLConnectionNames"
    Write-Host "Custom Type ->                   $CustomType"
    Write-Host "Custom Type Connection Names ->  $CustomTypeConnectionNames"
    

    
    write-host "Initializing Azure"
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

    write-host "Importing the Task.Json file"
	# Import the loc strings.
	Import-VstsLocStrings -LiteralPath $PSScriptRoot/Task.json

    write-host "Getting Config content"
    $configs = Get-ChildItem -Path . -Filter $TransformConfigFile -File
    $configContent = [XML](Get-Content $configs)

    $appsettingsHash = @{}
    $appsettingsNames = @()
    $connections = @{}
    $connectionNames = @()

    # if ($UseAppsettings -eq "true") {
    #     $appsettingsHash = [hashtable](GetAppSettings $configContent)
    #     echo $appsettingsHash
    #     $appsettingsNames = [hashtable](GetAppSettingNames $configContent)
    #     echo $appsettingsNames
    # }



    # if ($UseConnectionStrings -eq "true") {
    #     $connections = GetConnectionStrings $configContent
    #     echo $connections
    #     $connectionNames = GetConnectionStringNames $configContent
    #     echo $connectionNames

    # }
    

    
    # if ($UseAppsettings -eq "false" -and $UseConnectionStrings -eq "false") {
    #     throw new-object System.ArgumentException
    # }

    if ($UseAppsettings -eq "True") {

        write-host "Starting Appsettings"
        echo $configContent.configuration.appSettings.add
        foreach($setting in $configContent.configuration.appSettings.add)
        {
            $appsettingsHash.Add($setting.key,$setting.value)
            $appsettingsNames =$appsettingsNames + $setting.key
        }

        write-host "Finished Appsettings"
        echo $appsettingsHash
    }

    if ($UseAppsettings -eq "true" -and $UseConnectionStrings -eq "true") {
        write-host "*****************************"
    }

    


    if ($UseConnectionStrings -eq "true") {
        write-host "Starting Conectionstrings"
        echo $configContent.configuration.connectionStrings.add
        foreach($setting in $configContent.configuration.connectionStrings.add)
        {
            $connectionType = GetConnectionType $setting.name
            $connections[$setting.name] = @{Type = $connectionType;Value = $setting.connectionString}
            $connectionNames = $connectionNames + $setting.name
        }
        write-host "Finished Parsing ConnectionString"
        echo $connections
    }

    if ($UseAppsettings -eq "false" -and $UseConnectionStrings -eq "false") {
        throw new-object System.ArgumentException
    }

    Set-AzureRmWebAppSlotConfigName  -Name $WebAppName -ResourceGroupName $ResourceGroup -RemoveAllAppSettingNames -RemoveAllConnectionStringNames

    $results = Set-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -Slot $Slot -AppSettings $appsettingsHash -ConnectionStrings $connections -Verbose

    Set-AzureRmWebAppSlotConfigName -Name $WebAppName -ResourceGroupName $ResourceGroup -AppSettingNames $appsettingsNames -ConnectionStringNames $connectionNames

    echo $results

    if ($SwapSlots -eq "true") {
        Write-Host "Beginning the Slot swap"
        Swap-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -SourceSlotName $SourceSlotName -DestinationSlotName $Slot -verbose
        $slotsettings = Get-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -Slot $Slot
        echo $slotsettings

        # while ($slotsettings.state -ne "Running") {
        #     $slotsettings = Get-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -Slot $Slot
        #     Write-Host "Slot status"
        # }
        Write-Host "Finished Slot swap"
    }
    else {
        Write-Host "Skipping Slot swap"
    }


} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
