param (
    [string]$Environment = "dev"
)

Write-Host "Starting Governance Control Tower deployment..."
Write-Host "Environment: $Environment"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$configPath = Join-Path $repoRoot "config\$Environment.json"

if (-not (Test-Path $configPath)) {
    throw "Config file not found: $configPath"
}

$config = Get-Content $configPath | ConvertFrom-Json

Write-Host "Using site: $($config.siteUrl)"
Write-Host "Target list: $($config.listName)"

& "$scriptRoot\00-install-prereqs.ps1"
& "$scriptRoot\01-connect.ps1" -siteUrl $config.siteUrl
& "$scriptRoot\02-create-governance-list.ps1" -listName $config.listName

Write-Host "Deployment complete."