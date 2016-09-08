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

    Write-Host "Web App ame ->                  $WebAppName"
    Write-Host "Current Working directory ->    $cwd"
    Write-Host "Resource Group ->               $ResourceGroup"
    Write-Host "Transform Config File ->        $TransformConfigFile"
    Write-Host "Slot Name ->                    $Slot"
    Write-Host "Source Slot Name ->             $SourceSlotName"
    Write-Host "Swap Slots ->                   $SwapSlots"
    
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

    write-host "Starting Appsettings"
    echo $configContent.configuration.appSettings.add
    foreach($setting in $configContent.configuration.appSettings.add)
    {
        $appsettingsHash.Add($setting.key,$setting.value)
        $appsettingsNames =$appsettingsNames + $setting.key
    }

    write-host "Finished Appsettings"
    echo $appsettingsHash

    write-host "Starting Conectionstrings"
    echo $configContent.configuration.connectionStrings.add
    foreach($setting in $configContent.configuration.connectionStrings.add)
    {
        $connectionType = "Custom"
        if($setting.name -eq "QueryTool")
        {
            $connectionType = "SqlServer"
        }

        $connections[$setting.name] = @{Type = $connectionType;Value = $setting.connectionString}
        $connectionNames = $connectionNames + $setting.name
    }
    write-host "Finished Parsing ConnectionString"
    echo $connections


    Set-AzureRmWebAppSlotConfigName  -Name $WebAppName -ResourceGroupName $ResourceGroup -RemoveAllAppSettingNames -RemoveAllConnectionStringNames

    $results = Set-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -Slot $Slot -AppSettings $appsettingsHash -ConnectionStrings $connections -Verbose

    Set-AzureRmWebAppSlotConfigName -Name $WebAppName -ResourceGroupName $ResourceGroup -AppSettingNames $appsettingsNames -ConnectionStringNames $connectionNames

    echo $results

    if ($SwapSlots -eq "true") {
        Write-Host "Beginning the Slot swap"
        Swap-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -SourceSlotName $SourceSlotName -DestinationSlotName $Slot -verbose
    }
    else {
        Write-Host "Skipping Slot swap"
    }


} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
