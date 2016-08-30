param(
<#    # Web Job Name
    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'StartJob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'StopJob')]
    [string]
    $MyJobName,
    # The name of the Azure RM application that is used for deployments.
    [Parameter(Mandatory = $true, ParameterSetName = 'StartJob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'StopJob')]
    [string]
    $AzureWebAppName
    ,
    # Start the Job
    [Parameter(ParameterSetName = 'StartJob')]
    [switch]
    $StartJob,
    
    # Stop the Job
    [Parameter(ParameterSetName = 'StopJob')]
    [switch]
    $StopJob,

    # Job Type  
    [Parameter(Mandatory = $true, ParameterSetName = 'StartJob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'StopJob')]
    [validateSet('Triggered', 'Continuous')]
    [string]
    $MyJobType,

    # Username from the deployment credentials of your site.
    [Parameter(Mandatory = $true, ParameterSetName = 'StartJob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'StopJob')]
    [string]
    $UserName,

    # Password used for the deployment.
    [Parameter(Mandatory = $true, ParameterSetName = 'StartJob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'StopJob')]
    [string]
    $Password#>



)




Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    
    # Set the working directory.
<#    $cwd = Get-VstsInput -Name cwd -Require
    Assert-VstsPath -LiteralPath $cwd -PathType Container
    Write-Verbose "Setting working directory to '$cwd'."
    Set-Location $cwd

    # Output the message to the log.
    Write-Host (Get-VstsInput -Name msg)#>

    [string]$MyJobName = Get-VstsInput -Name JobName -Require
    [string]$AzureWebAppName = Get-VstsInput -Name AzureWebAppName -Require
    [bool]$StartJob = Get-VstsInput -Name StartJob
    [bool]$StopJob = Get-VstsInput -Name StopJob
    [string]$JobState = Get-VstsInput -Name JobState
    [string]$MyJobType = Get-VstsInput -Name JobType -Require
    [string]$UserName = Get-VstsInput -Name UserName -Require
    [string]$Password = Get-VstsInput -Name Password -Require
    assert-
    $token =  [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"));
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", [string]::Format('Basic {0}',$token))
    $requestUribase = 'https://{0}.scm.azurewebsites.net/api/{1}webjobs/{2}/{3}'


<#    if ($JobState -eq "Start") {
        Write-Host "Starting Job $MyJobName"        
    }
    elseif ($JobState -eq "Stop") {
        Write-Host "Stopping Job $MyJobName"
        # $request = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,"stop")
    }#>
    Write-Host "$JobState Job $MyJobName"
    $request = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,$JobState.ToLower())
    $response = Invoke-RestMethod $request -Headers $headers -ContentType 'application/json'

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}