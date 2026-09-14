[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$siteUrl,
    [string]$clientId
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($clientId)) {
    throw 'Connection cannot proceed without an existing approved PnP client ID.'
}
Connect-PnPOnline -Url $siteUrl -Interactive -ClientId $clientId -ErrorAction Stop
$web = Get-PnPWeb -ErrorAction Stop
if ($web.Url.TrimEnd('/') -ne $siteUrl.TrimEnd('/')) {
    throw 'The authenticated site does not match the configured BRMS register site.'
}
Write-Host "Connected to site: $($web.Title)"
