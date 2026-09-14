[CmdletBinding()]
param (
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\brms.json'),
    [string]$ClientId
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Config file not found: $ConfigPath"
}
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
if (($config.PSObject.Properties.Name -contains 'environment') -or
    ($config.PSObject.Properties.Name -contains 'environments')) {
    throw 'Obsolete environment configuration. Use the single config/brms.json configuration.'
}
if ([string]::IsNullOrWhiteSpace($config.siteUrl) -or
    [string]::IsNullOrWhiteSpace($config.listName)) {
    throw 'The BRMS bootstrap configuration requires siteUrl and listName.'
}
if ($config.listName -match '(?i)\b(?:DEV|PROD)\b') {
    throw 'BRMS resource names must not contain DEV or PROD environment labels.'
}
if ([string]::IsNullOrWhiteSpace($ClientId)) {
    throw 'An existing approved PnP client ID is required for this bootstrap. Use other supported authenticated tooling if none is available.'
}

Write-Host "Bootstrapping the BRMS register at $($config.siteUrl)"
Write-Host "Register: $($config.listName)"
& "$PSScriptRoot\00-install-prereqs.ps1"
& "$PSScriptRoot\01-connect.ps1" -siteUrl $config.siteUrl -clientId $ClientId
& "$PSScriptRoot\02-create-governance-list.ps1" -listName $config.listName
Write-Host 'Register bootstrap finished. The document schema, forms, views, supporting resources, and flows still require the Scout build instructions.'
