param(
    [string]
    $location,
    [string]
    $configuration
)

Write-Host "Removing files from $location"
write-host "Current Build Configuration $configuration"
if ($configuration.ToLower() -eq "production") {
    Get-ChildItem -Directory $location  | ForEach-Object ($_){
        if (($_.Name -ne "Flow.Admin") -and ($_.Name -ne "API") ) {
            Write-Host "Deleting $_"
            Remove-Item $_.FullName -Recurse -Force
        }
        else{
            Write-Host "Not Deleting $_"
        }
    }
}
else {
    Write-Host "Current Configuration is not applicable: $configuration"
}

