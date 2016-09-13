[CmdletBinding()]
param()



# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try {
    Write-Host "Getting Parameters"
    # Set the working directory.
    [string]$WebAppName = Get-VstsInput -Name WebAppName -Require
    [string]$ResourceGroup = Get-VstsInput -Name ResourceGroupName -Require    
    [string]$Slot = Get-VstsInput -Name SlotName
    [string]$WebJobSettingsFile = Get-VstsInput -Name WebJobSettingsFile -Require
    [string]$jobCollectionName = get-vstsinput -Name jobCollectionName -Require

    Write-Host "WebAppName = $WebAppName"
    Write-Host "ResourceGroup = $ResourceGroup"
    Write-Host "Slot = $Slot"
    Write-Host "WebJobSettingsFile = $WebJobSettingsFile"
    Write-Host "jobCollectionName = $jobCollectionName"

    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

    $outputFile = [System.IO.Path]::Combine($env:Agent_WorkingDirectory,"tempProfile.xml")
    $uriFormat = ""
    if(($slot -eq "production") -or ([string]::IsNullOrEmpty($Slot))){
        $uriFormat = "{0}" -f $WebAppName
    }
    else {
        $uriFormat = "{0}/slots/{1}" -f $WebAppName, $Slot
    }
    
    Write-Host "Getting Azure Web App Deployment Settings"
    $deploymentSettings = [xml](Get-AzureRmWebAppPublishingProfile -Name $uriFormat -OutputFile $outputFile -ResourceGroupName $ResourceGroup -Format WebDeploy)
    $webdeploySettings = $deploymentSettings.publishData.publishProfile | Where-Object {$_.publishMethod -eq "MSDeploy"}

    $jobSettings =  (get-content $WebJobSettingsFile -Raw) | Convertfrom-Json 
    $jobSettings
    $jobUri = "https://{0}/api/triggeredwebjobs/{1}/run" -f $webdeploySettings.publishUrl.Split(":")[0],$jobSettings.webJobName
    Write-Host "Getting Azure RM Scheduler Job Collection"
    $jobCollection = get-AzureRmSchedulerJobCollection -JobCollectionName $jobCollectionName  -ResourceGroupName $ResourceGroup
    $jobCollection

    
    #Set-AzureRmSchedulerHttpJob -JobCollectionName $jobCollection.JobCollectionName -JobName $jobSettings.webJobName -Method POST -ResourceGroupName $resourceGroup -Uri $jobUri -HttpAuthenticationType Basic -Username $webdeploySettings.userName  -Password $webdeploySettings.userPWD
    
    try {
        Write-Host "Removing old Schedule"
        Remove-AzureRmSchedulerJob -JobCollectionName $jobCollection.JobCollectionName -JobName $jobSettings.webJobName -ResourceGroupName $resourceGroup
    }
    finally {
        Write-Host "Create new Schedule"
        new-AzureRmSchedulerHttpJob -JobCollectionName $jobCollection.JobCollectionName -JobName $jobSettings.webJobName -Method POST -ResourceGroupName $ResourceGroup -Uri $jobUri -HttpAuthenticationType Basic -Username $webdeploySettings.userName  -Password $webdeploySettings.userPWD -Frequency $jobSettings.jobRecurrenceFrequency -StartTime $jobSettings.startTime -EndTime $jobSettings.endTime -Interval $jobSettings.interval
    
    }


} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
