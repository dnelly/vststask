param(
    # Web Job Name
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
    $Password



)


$token =  [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"));
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", [string]::Format('Basic {0}',$token))
$requestUribase = 'https://{0}.scm.azurewebsites.net/api/{1}webjobs/{2}/{3}'


if ($StartJob) {
    Write-Host "Starting Job $MyJobName"
    $request = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,"start")
}
elseif ($StopJob) {
    Write-Host "Stopping Job $MyJobName"
    $request = [string]::Format($requestUribase, $AzureWebAppName, $MyJobType, $MyJobName,"stop")
}

$response = Invoke-RestMethod $request -Headers $headers -ContentType 'application/json'