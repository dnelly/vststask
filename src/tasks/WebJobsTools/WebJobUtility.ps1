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

    [string]$MyJobName = Get-VstsInput -Name JobName -Require
    [string]$AzureWebAppName = Get-VstsInput -Name AzureWebAppName -Require
    # [bool]$StartJob = Get-VstsInput -Name StartJob
    # [bool]$StopJob = Get-VstsInput -Name StopJob
    [string]$JobState = Get-VstsInput -Name JobState
    [string]$MyJobType = Get-VstsInput -Name JobType -Require
    [string]$UserName = Get-VstsInput -Name UserName -Require
    [string]$Password = Get-VstsInput -Name Password -Require
    $token =  [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"));
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", [string]::Format('Basic {0}',$token))
    $requestUribase = 'https://{0}.scm.azurewebsites.net/api/{1}webjobs/{2}/{3}'

    Write-Host "[JobName] -> $Jobname"
    Write-Host "[AzureWebAppName] -> $AzureWebAppName"
    Write-Host "[JobState] -> $JobState"
    Write-Host "[JobType] -> $JobType"
    Write-Host "[UserName] -> $UserName"

    Write-Host "$JobState Job $MyJobName"
    $postRequest = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,$JobState.ToLower())
    $getRequest = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,"")

    Write-host "Processing current request for URI"
    Write-Host $postRequest
    $response = Invoke-RestMethod $postRequest -Headers $headers -ContentType 'application/json' -Method Post
    Write-Host "Getting the status of $Jobname"
    Invoke-RestMethod $getrequest.Trim() -Headers $headers -ContentType 'application/json' -Method Get

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}