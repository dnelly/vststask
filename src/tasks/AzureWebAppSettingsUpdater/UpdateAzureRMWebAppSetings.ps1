[CmdletBinding()]
param()

# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try {
    # Set the working directory.
    $cwd = Get-VstsInput -Name cwd -Require
    Assert-VstsPath -LiteralPath $cwd -PathType Container
    Write-Verbose "Setting working directory to '$cwd'."
    Set-Location $cwd

    [string]$WebAppName = Get-VstsInput -Name WebAppName -Require
    [string]$ResourceGroup = Get-VstsInput -Name ResourceGroupName -Require
    [string]$TransformConfigFile = Get-VstsInput -Name TransformConfigFile -Require
    [string]$Slot = Get-VstsInput -Name SlotName -Require
    
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

	# Import the loc strings.
	Import-VstsLocStrings -LiteralPath $PSScriptRoot/Task.json

    $projectPath = New-Object System.IO.DirectoryInfo $cwd


    $configs = $projectPath.GetFiles($TransformConfigFile)
    $configContent = [XML](Get-Content $configs[1].FullName)

    $appsettingsHash = @{}
    $appsettingsNames = @()
    $connections = @{}
    $connectionNames = @()

    foreach($setting in $configContent.configuration.appSettings.add)
    {
        $appsettingsHash.Add($setting.key,$setting.value)
        $appsettingsNames =$appsettingsNames + $setting.key
    }

    echo $appsettingsHash


    foreach($setting in $configContent.configuration.connectionStrings.add)
    {
        $connectionType = "Custom"
        if($setting.name -eq "FlowEntities")
        {
            $connectionType = "SqlServer"
        }

        $connections[$setting.name] = @{Type = $connectionType;Value = $setting.connectionString}
        $connectionNames = $connectionNames + $setting.name
    }
    echo $connections


    Set-AzureRmWebAppSlotConfigName  -Name $WebAppName -ResourceGroupName $ResourceGroup -RemoveAllAppSettingNames -RemoveAllConnectionStringNames

    $results = Set-AzureRmWebAppSlot -Name $WebAppName -ResourceGroupName $ResourceGroup -Slot $Slot -AppSettings $appsettingsHash -ConnectionStrings $connections -Verbose

    Set-AzureRmWebAppSlotConfigName -Name $WebAppName -ResourceGroupName $ResourceGroup -AppSettingNames $appsettingsNames -ConnectionStringNames $connectionNames

    echo $results



} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
