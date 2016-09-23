[CmdletBinding()]
param()


Write-Host "Starting Updates."
# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation


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
    $WebAppNameWithSlot = ""

    if(($slot -eq "production") -or ([string]::IsNullOrEmpty($Slot))){
        $WebAppNameWithSlot = "{0}" -f $WebAppName
    }
    else {
        $WebAppNameWithSlot = "{0}/slots/{1}" -f $WebAppName, $Slot
    }

    $webapp = Get-AzureRmWebApp -ResourceGroupName $ResourceGroup -Name $WebAppNameWithSlot
    Write-Host "Current Web App"
    $webapp
    Write-Host "****************************************************"
    Write-Host ""
    Write-Host "Current Settings"
    $webapp.SiteConfig.AppSettings
    foreach($setting in $webapp.SiteConfig.AppSettings)
    {
        $appsettingsHash[$setting.Name] = $setting.value
        $appsettingsNames = $appsettingsNames + $setting.Name
    }

    Write-Host "****************************************************"
    Write-Host ""

    if ($UseAppsettings -eq "True") {

        write-host "Starting Appsettings"
        echo $configContent.configuration.appSettings.add
        foreach($setting in $configContent.configuration.appSettings.add)
        {
            $currentKey = $setting.key
            Write-Host "Adding Key $currentKey"
            if ($appsettingsHash.ContainsKey($currentKey) -eq $false ) {
                $appsettingsHash[$currentKey] = $setting.value
                $appsettingsNames = $appsettingsNames + $currentKey
            }
            else {
                
                Write-Host "Key $currentKey exist already. "
            }
        }

        write-host "Finished Appsettings"
        echo $appsettingsHash
    }

    if ($UseAppsettings -eq "true" -and $UseConnectionStrings -eq "true") {
        write-host "*****************************"
    }
    Write-Host "****************************************************"
    Write-Host ""
    
    Write-Host "Current Conenctions strings"
    $webapp.SiteConfig.ConnectionStrings
    foreach($setting in $webapp.SiteConfig.ConnectionStrings)
    {
        #$connections.Add($setting.Name,$setting.ConnectionString)
        
        $connections[$setting.name] = @{Type = $setting.Type;Value = $setting.connectionString} 
        $connectionNames = $connectionNames + $setting.Name
    }


    if ($UseConnectionStrings -eq "true") {
        write-host "Starting Conectionstrings"
        echo $configContent.configuration.connectionStrings.add
        foreach($setting in $configContent.configuration.connectionStrings.add)
        {
            $currenConnection = $setting.name
           
            if ($connections.ContainsKey($currenConnection) -eq $false) {
                 Write-Host "Adding connection string: $currenConnection"

                $connectionType = "Custom"

                if ($UseSQLServerType -eq "true") {
                    if ($SQLServerConnectionNames.split(";").split(",").contains($setting.Name)) {
                        $connectionType = "SqlServer"
                    }
                }
                elseif ($UseAzureSQLType -eq "true") {
                    if ($AzureSQLConnectionNames.split(";").split(",").contains($setting.Name)) {
                        $connectionType = "AzureSQL"
                    }            
                    
                }
                elseif ($UseMySqlType -eq "true") {
                    if ($MySQLConnectionNames.split(";").split(",").contains($setting.Name)) {
                        $connectionType = "MySql"
                    }
                    
                }
                elseif ($UseCustomType -eq "true") {
                    if ($CustomTypeConnectionNames.split(";").split(",").contains($setting.Name)) {
                        $connectionType = "Custom"
                    }
                }
            
                $connections[$setting.name] = @{Type = $connectionType;Value = $setting.connectionString}
                $connectionNames = $connectionNames + $setting.name

            } else {
                Write-Host "Skipping $currenConnection"
            }           

        }
        write-host "Finished Parsing ConnectionString"
        echo $connections
    }

    if ($UseAppsettings -eq "false" -and $UseConnectionStrings -eq "false") {
        throw new-object System.ArgumentException
    }

    Write-Host "****************************************************"
    Write-Host ""   

    #Add the currect settings.
    Write-Host "Update the settings"
    Write-Host "AppsettingsHash Type $appsettingsHash.GetType()"
    Write-Host "connections Type $connections.GetType()"
    $results = Set-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -Slot $Slot -AppSettings $appsettingsHash -ConnectionStrings $connections

    #Set the settings that were just uploaded to slot specific settings.
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
