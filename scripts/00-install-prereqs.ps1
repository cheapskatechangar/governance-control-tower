Write-Host "Checking prerequisites..."

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Install-Module PnP.PowerShell -Scope CurrentUser -Force -AllowClobber
}

Write-Host "Prerequisites ready."