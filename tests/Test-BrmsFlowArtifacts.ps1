[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$out = Join-Path $env:TEMP ("brms-flow-artifacts-" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}

function Get-ActionText($actions) {
    return ($actions | ConvertTo-Json -Depth 100)
}

function Find-Actions {
    param($actions, [string]$Predicate)
    $script:hits = @()
    function Walk($node, $path) {
        if ($null -eq $node) { return }
        if ($node -is [System.Management.Automation.PSCustomObject] -or $node -is [hashtable] -or $node -is [System.Collections.IDictionary]) {
            foreach ($p in $node.PSObject.Properties) {
                $child = $p.Value
                Walk $child ($path + '.' + $p.Name)
                if ($p.Name -eq 'type' -and $child -is [string] -and $child -match $Predicate) {
                    $script:hits += $path
                }
            }
        } elseif ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string])) {
            $i = 0
            foreach ($v in $node) { Walk $v ($path + '[' + $i + ']'); $i++ }
        }
    }
    Walk $actions ''
    return $script:hits
}

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
    Assert (Test-Path -LiteralPath $zip) 'Expected solution ZIP was not created.'

    # Solution version corrections
    $solutionXml = [xml](Get-Content -LiteralPath (Join-Path $out 'solution.xml') -Raw)
    Assert ($solutionXml.ImportExportXml.SolutionManifest.Version -eq '1.0.0.3') "Solution version must be bumped to 1.0.0.3; found $($solutionXml.ImportExportXml.SolutionManifest.Version)."

    $files = Get-ChildItem -LiteralPath (Join-Path $out 'Workflows') -Filter '*.json'
    Assert ($files.Count -eq 3) "Expected 3 workflow JSON files, found $($files.Count)."

    $workflows = @{}
    foreach ($file in $files) {
        $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $workflows[$file.BaseName] = $json.properties.definition
        Assert (($json.properties.connectionReferences.shared_sharepointonline.api.name) -eq 'shared_sharepointonline') "SharePoint connection reference missing from $($file.BaseName)."
        Assert ($json.properties.definition.parameters.brmsRegisterListId.defaultValue -eq '249e7c48-b75e-4b14-9ff0-eb00a854111a') "Register mapping missing from $($file.BaseName)."
    }

    $refreshKey = $workflows.Keys | Where-Object { $_ -like 'BRMSGCTReviewScheduleRefresh-*' } | Select-Object -First 1
    $reminderKey = $workflows.Keys | Where-Object { $_ -like 'BRMSGCTReviewReminders-*' } | Select-Object -First 1
    $sourceKey = $workflows.Keys | Where-Object { $_ -like 'BRMSGCTSourceDocumentMonitor-*' } | Select-Object -First 1

    foreach ($key in @($refreshKey, $reminderKey, $sourceKey)) {
        $definition = $workflows[$key]
        $text = Get-ActionText $definition.actions

        # Correction 3: BRMS Configuration is read and validated at runtime.
        Assert ($text -match 'Get_configuration') "$key must read BRMS Configuration at runtime."
        Assert ($text -match 'Parse_review_rules') "$key must parse review rules from configuration."
        Assert ($text -match 'Parse_notification_settings') "$key must parse notification settings from configuration."
        Assert ($text -match 'Validate_configuration') "$key must validate BRMS Configuration."
        Assert ($text -match 'Terminate_missing_configuration') "$key must terminate when configuration is missing."

        # Correction 5: retryPolicy must live under inputs.retryPolicy on SharePoint actions
        # and pagination must be expressed via runtimeConfiguration.paginationPolicy.
        Assert ($text -match '"retryPolicy"[\s\S]*?"maximumInterval"') "$key must include retryPolicy under inputs."
        Assert ($text -notmatch '"runtimeConfiguration":\s*\{\s*"retryPolicy"') "$key must not place retryPolicy under runtimeConfiguration."
        Assert ($text -match '"paginationPolicy":\s*\{\s*"minimumItemCount":\s*100000') "$key must enable pagination beyond the first page."

        # Correction 2: actual success/failure counting via variables and per-item append.
        Assert ($text -match '"name":\s*"SuccessCount"') "$key must initialize a SuccessCount variable."
        Assert ($text -match '"name":\s*"FailureCount"') "$key must initialize a FailureCount variable."
        Assert ($text -match "@variables\('SuccessCount'\)") "$key run history must report actual SuccessCount."
        Assert ($text -match "@variables\('FailureCount'\)") "$key run history must report actual FailureCount."
        Assert ($text -match "@join\(variables\('SanitizedErrors'\),'; '\)") "$key run history must persist sanitized errors."
    }

    $refreshText = Get-ActionText $workflows[$refreshKey].actions
    $reminderText = Get-ActionText $workflows[$reminderKey].actions
    $sourceText = Get-ActionText $workflows[$sourceKey].actions

    # Correction 6: revalidate records before updates for refresh and source monitor.
    foreach ($pair in @(@($refreshText, 'Refresh'), @($sourceText, 'Source monitor'))) {
        Assert ($pair[0] -match 'Reread_current_document') "$($pair[1]) must reread the current record before patching."
    }
    Assert ($refreshText -match 'Check_eligibility') 'Refresh must recheck eligibility before update.'
    Assert ($sourceText -match 'Check_still_active') 'Source monitor must recheck record activity before update.'

    # Correction 4: reminder must gate on a current successful refresh and handle duplicate-create conflicts.
    Assert ($reminderText -match 'Get_last_successful_refresh') 'Reminders must query last successful refresh from run history.'
    Assert ($reminderText -match 'Require_current_refresh') 'Reminders must terminate when today has no successful refresh.'
    Assert ($reminderText -match 'Terminate_no_refresh') 'Reminders must terminate the run when the refresh gate blocks.'
    Assert ($reminderText -match 'Reread_current_document') 'Reminders must reread record eligibility before creating notifications.'
    Assert ($reminderText -match 'Recover_duplicate_conflict') 'Reminders must recover duplicate-create conflicts.'
    Assert ($reminderText -match 'Requery_notification_key') 'Reminders must requery the notification key after a create conflict.'
    Assert ($reminderText -notmatch 'SendEmail|PostMessage|Send_an_email') 'Reminders must remain preview-only with no outbound send.'

    # Correction 1: source addresses/paths resolve from configured mappings.
    Assert ($sourceText -match 'Parse_source_library_map') 'Source monitor must parse configured source library map.'
    Assert ($sourceText -match 'Filter_matching_source_mapping') 'Source monitor must match sources by configured mapping, not naive URL split.'
    Assert ($sourceText -match 'Compose_resolved_site') 'Source monitor must resolve the site URL from the matched mapping.'
    Assert ($sourceText -match 'Compose_resolved_folder') 'Source monitor must resolve the folder from the matched mapping.'
    Assert ($sourceText -match 'Append_unresolved_source') 'Source monitor must record unresolved sources when no mapping matches.'
    Assert ($sourceText -notmatch "split\(outputs\('Compose_document_url'\),'/sites/'\)") 'Source monitor must not derive the site URL by splitting on /sites/.'
    Assert ($sourceText -notmatch "'item/LastReviewedDate'") 'Source monitor must not update LastReviewedDate.'

    # Local calendar arithmetic parity check for the recorded due-date rules.
    function Add-CalendarMonths([datetime]$date, [int]$months) { return $date.AddMonths($months) }
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
        Assert (($due.ToString('yyyy-MM-dd') -eq $case.Due) -and ($days -eq $case.Days) -and ($status -eq $case.Status)) ("Date boundary case failed: " + ($case | ConvertTo-Json -Compress))
    }

    Write-Host (ConvertTo-Json @{ brmsFlowArtifactTests = 'passed'; zip = $zip; solutionVersion = $solutionXml.ImportExportXml.SolutionManifest.Version } -Compress)
}
finally {
    Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
}
