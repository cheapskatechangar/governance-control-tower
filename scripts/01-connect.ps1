param (
    [string]$siteUrl,
    [string]$clientId
)

Write-Host "Connection step placeholder."
Write-Host "Site URL: $siteUrl"

if ([string]::IsNullOrWhiteSpace($clientId)) {
    Write-Host "No clientId found. PnP connection skipped until Entra app registration is approved."
    return
}

Connect-PnPOnline -Url $siteUrl -Interactive -ClientId $clientId

$web = Get-PnPWeb
Write-Host "Connected to site:" $web.Title