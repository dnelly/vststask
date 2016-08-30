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
    [string]$AzureWebAppName = Get-VstsInput -Name AzureWebAppName -Require
    # [bool]$StartJob = Get-VstsInput -Name StartJob
    # [bool]$StopJob = Get-VstsInput -Name StopJob
    [string]$JobState = Get-VstsInput -Name JobState
    [string]$JobType = Get-VstsInput -Name JobType -Require
    [string]$UserName = Get-VstsInput -Name UserName -Require
    [string]$Password = Get-VstsInput -Name Password -Require
    $token =  [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"));
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", [string]::Format('Basic {0}',$token))
    $requestUribase = 'https://{0}.scm.azurewebsites.net/api/{1}webjobs/{2}/{3}'

    Write-Host "[JobName] -> $JobName"
    Write-Host "[AzureWebAppName] -> $AzureWebAppName"
    Write-Host "[JobState] -> $JobState"
    Write-Host "[JobType] -> $JobType"
    Write-Host "[UserName] -> $UserName"




    Write-Host "$JobState Job $JobName"
    $postRequest = [string]::Format($requestUribase, $AzureWebAppName, $JobType, $JobName,$JobState.ToLower())
    $getRequest = [string]::Format($requestUribase, $AzureWebAppName, $JobType, $JobName,"")

    Write-Host "Checking the current status of the job"
    $response = Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get
    if ($response.status -eq $JobState) {
        Write-host "The Job is currently $JobState."
        exit 0
    }

    Write-host "Processing current request for URI"
    Write-Host $postRequest
    $response = Invoke-RestMethod $postRequest -Headers $headers -ContentType 'application/json' -Method Post
    Write-Host "Getting the status of $Jobname"
    Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}