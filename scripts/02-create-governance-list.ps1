[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$listName
)

$ErrorActionPreference = 'Stop'
if ($listName -match '(?i)\b(?:DEV|PROD)\b') {
    throw 'BRMS resource names must not contain DEV or PROD environment labels.'
}
# Enumerate successfully before deciding a list is absent. Access failures must stop creation.
$matchingLists = @(Get-PnPList -ErrorAction Stop | Where-Object { $_.Title -eq $listName })
if ($matchingLists.Count -gt 1) {
    throw 'More than one matching list was found. Resolve the target by its verified ID before proceeding.'
}
if ($matchingLists.Count -eq 0) {
    New-PnPList -Title $listName -Template GenericList -ErrorAction Stop
    Write-Host "List created: $listName"
}
else {
    Write-Host "Reusing existing list: $listName"
}
