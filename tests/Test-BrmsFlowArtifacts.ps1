[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$out = Join-Path $env:TEMP ("brms-flow-artifacts-" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Force -Path $out | Out-Null

try {
    & (Join-Path $repoRoot 'scripts\New-BrmsFlowSolution.ps1') `
        -RegisterSiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
        -RegisterListId '249e7c48-b75e-4b14-9ff0-eb00a854111a' `
        -ConfigurationSiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
        -ConfigurationListId '8a5524c7-01bd-4608-899f-62281313a8c6' `
        -NotificationHistorySiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
        -NotificationHistoryListId 'ef96f9df-2e83-4040-9201-da4e8087918f' `
        -AutomationRunHistorySiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
        -AutomationRunHistoryListId 'f0f62faf-86bb-4257-9c0d-f4f8571e71e2' `
        -DefaultSourceSiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
        -DefaultSourceServerRelativeSitePath '/sites/ELSBUProjects/BRMS' `
        -OutputDirectory $out | Out-Host

    $zip = Join-Path $out 'BRMSGovernanceControlTower.zip'
    if (-not (Test-Path -LiteralPath $zip)) {
        throw 'Expected solution ZIP was not created.'
    }

    $files = Get-ChildItem -LiteralPath (Join-Path $out 'Workflows') -Filter '*.json'
    if ($files.Count -ne 3) {
        throw "Expected 3 workflow JSON files, found $($files.Count)."
    }

    $workflows = @{}
    foreach ($file in $files) {
        $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $name = $file.BaseName
        $workflows[$name] = $json.properties.definition
        if (($json.properties.connectionReferences.shared_sharepointonline.api.name) -ne 'shared_sharepointonline') {
            throw "SharePoint connection reference missing from $name."
        }
        if ($json.properties.definition.parameters.brmsRegisterListId.defaultValue -ne '249e7c48-b75e-4b14-9ff0-eb00a854111a') {
            throw "Register mapping missing from $name."
        }
        if ($json.properties.definition.triggers.Recurrence.runtimeConfiguration.concurrency.runs -ne 1) {
            throw "Trigger concurrency is not bounded for $name."
        }
    }

    $refresh = $workflows.Keys | Where-Object { $_ -like 'BRMSGCTReviewScheduleRefresh-*' } | Select-Object -First 1
    $refreshActions = $workflows[$refresh].actions
    $refreshText = $refreshActions | ConvertTo-Json -Depth 100
    foreach ($expected in @('Monthly', 'Quarterly', 'Semi-Annual', 'Annual', 'addToTime', 'NextReviewDue', 'DaysToReview', 'Status')) {
        if ($refreshText -notmatch [regex]::Escape($expected)) {
            throw "Refresh workflow missing $expected."
        }
    }
    if ($refreshText -notmatch 'Active eq 1') {
        throw 'Refresh workflow must skip inactive rows.'
    }
    if ($refreshText -notmatch "not Set|Not Set") {
        throw 'Refresh workflow must handle missing dates as Not Set.'
    }
    if ($refreshText -notmatch 'maximumInterval') {
        throw 'Refresh workflow SharePoint actions need bounded retry metadata.'
    }

    $reminder = $workflows.Keys | Where-Object { $_ -like 'BRMSGCTReviewReminders-*' } | Select-Object -First 1
    $reminderText = $workflows[$reminder].actions | ConvertTo-Json -Depth 100
    foreach ($expected in @('NotificationKey', 'Preview', 'Find_existing_notification', 'Duplicate notification suppressed', 'OutcomeState')) {
        if ($reminderText -notmatch [regex]::Escape($expected)) {
            throw "Reminder workflow missing $expected."
        }
    }
    if ($reminderText -match 'SendEmail|PostMessage|Send_an_email') {
        throw 'Reminder workflow must not contain outbound send actions while in preview.'
    }

    $source = $workflows.Keys | Where-Object { $_ -like 'BRMSGCTSourceDocumentMonitor-*' } | Select-Object -First 1
    $sourceText = $workflows[$source].actions | ConvertTo-Json -Depth 100
    foreach ($expected in @('GetFileMetadataByPath', 'SourceModifiedDate', 'DocumentLink', 'brmsDefaultSourceSiteUrl')) {
        if ($sourceText -notmatch [regex]::Escape($expected)) {
            throw "Source monitor workflow missing $expected."
        }
    }
    if ($sourceText -match 'LastReviewedDate') {
        throw 'Source monitor must not update LastReviewedDate.'
    }

    function Add-CalendarMonths([datetime]$date, [int]$months) {
        return $date.AddMonths($months)
    }
    $cases = @(
        @{ Last = '2026-08-14'; Months = 1; Today = '2026-09-14'; Due = '2026-09-14'; Days = 0; Status = 'Due Soon' },
        @{ Last = '2026-09-14'; Months = 1; Today = '2026-09-14'; Due = '2026-10-14'; Days = 30; Status = 'Due Soon' },
        @{ Last = '2026-04-15'; Months = 6; Today = '2026-09-14'; Due = '2026-10-15'; Days = 31; Status = 'Current' },
        @{ Last = '2025-09-13'; Months = 12; Today = '2026-09-14'; Due = '2026-09-13'; Days = -1; Status = 'Overdue' },
        @{ Last = '2026-01-31'; Months = 1; Today = '2026-09-14'; Due = '2026-02-28'; Days = -198; Status = 'Overdue' },
        @{ Last = '2024-02-29'; Months = 12; Today = '2026-09-14'; Due = '2025-02-28'; Days = -563; Status = 'Overdue' }
    )
    foreach ($case in $cases) {
        $due = Add-CalendarMonths ([datetime]$case.Last) $case.Months
        $days = [int](New-TimeSpan -Start ([datetime]$case.Today) -End $due).TotalDays
        $status = if ($days -lt 0) { 'Overdue' } elseif ($days -le 30) { 'Due Soon' } else { 'Current' }
        if ($due.ToString('yyyy-MM-dd') -ne $case.Due -or $days -ne $case.Days -or $status -ne $case.Status) {
            throw "Date boundary case failed: $($case | ConvertTo-Json -Compress)"
        }
    }

    Write-Host (ConvertTo-Json @{ brmsFlowArtifactTests = 'passed'; zip = $zip } -Compress)
}
finally {
    Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
}
