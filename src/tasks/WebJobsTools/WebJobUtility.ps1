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
    assert-
    $token =  [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"));
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", [string]::Format('Basic {0}',$token))
    $requestUribase = 'https://{0}.scm.azurewebsites.net/api/{1}webjobs/{2}/{3}'


    Write-Host "$JobState Job $MyJobName"
    $request = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,$JobState.ToLower())
    $response = Invoke-RestMethod $request -Headers $headers -ContentType 'application/json'

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}