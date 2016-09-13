param()

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    
    # Set the working directory.
    # $cwd = Get-VstsInput -Name cwd -Require
    # Assert-VstsPath -LiteralPath $cwd -PathType Container
    # Write-Verbose "Setting working directory to '$cwd'."
    # Set-Location $cwd

    # # Output the message to the log.
    # Write-Host (Get-VstsInput -Name msg)

    [string]$JobName = Get-VstsInput -Name JobName -Require
    [string]$AzureWebAppName = Get-VstsInput -Name WebAppName -Require
    [string]$ResourceGroupName = Get-VstsInput -Name ResourceGroupName -Require
    [string]$Slot = Get-VstsInput -Name SlotName
    [string]$JobState = Get-VstsInput -Name JobState
    [string]$JobType = Get-VstsInput -Name JobType -Require


    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

    $outputFile = [System.IO.Path]::Combine($env:Agent_WorkingDirectory,"tempProfile.xml")
    $uriFormat = ""
    if(($slot -eq "production") -or ([string]::IsNullOrEmpty($Slot))){
        $uriFormat = "{0}" -f $AzureWebAppName
    }
    else {
        $uriFormat = "{0}/slots/{1}" -f $AzureWebAppName, $Slot
    }
    
    Write-Host "Getting Azure Web App Deployment Settings"
    [string]$ResourceGroupName = Get-VstsInput -Name ResourceGroupName -Require
    $deploymentSettings = [xml](Get-AzureRmWebAppPublishingProfile -Name $uriFormat -OutputFile $outputFile -ResourceGroupName $ResourceGroupName -Format WebDeploy)
    $webdeploySettings = $deploymentSettings.publishData.publishProfile | Where-Object {$_.publishMethod -eq "MSDeploy"}


    [string]$UserName = $webdeploySettings.userName
    [string]$Password = $webdeploySettings.userPWD
    $token =  [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"));
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", [string]::Format('Basic {0}',$token))
    
    $requestUribase = 'https://{0}/api/{1}webjobs/{2}/{3}'
    Write-Host "[JobName] ->            $JobName"
    Write-Host "[AzureWebAppName] ->    $AzureWebAppName"
    Write-Host "[JobState] ->           $JobState"
    Write-Host "[JobType] ->            $JobType"
    Write-Host "[UserName] ->           $UserName"


    Write-Host "$JobState Job $JobName"
    $postRequest = [string]::Format($requestUribase, $webdeploySettings.publishUrl.Split(":")[0], $JobType, $JobName,$JobState.ToLower())
    $getRequest = [string]::Format($requestUribase, $webdeploySettings.publishUrl.Split(":")[0], $JobType, $JobName,"")

    Write-Host "Checking the current status of the job"
    $response = Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get
    $status = $response.status
    if ($status -eq $JobState) {
        Write-host "The Job is currently $JobState."
        exit 0
    }

    Write-host "Processing current request for URI"
    Write-Host $postRequest
    $response = Invoke-RestMethod $postRequest -Headers $headers -ContentType 'application/json' -Method Post
    start-sleep -Seconds 5
    Write-Host "Getting the status of $Jobname"
    $response =  Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get
    $status = $response.status
    while (($status -ne "Running") -and ($status -ne "Stopped")) {
        $status = $response.status
        write-host "Current Status $status"
        $response =  Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get
    }

    Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}