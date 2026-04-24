param (
    [string]$listName
)

Write-Host "Creating/checking list: $listName"

$list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if ($null -eq $list) {
    New-PnPList -Title $listName -Template GenericList
    Write-Host "List created: $listName"
}
else {
    Write-Host "List already exists: $listName"
}