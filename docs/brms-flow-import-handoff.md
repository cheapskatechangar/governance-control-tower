# BRMS flow package handoff

## Target environment

Administrative metadata only. BRMS artifacts must remain unsuffixed.

| Field | Value |
|---|---|
| Environment name | RIS-TechCentral-Low-DEV |
| Environment ID | `722e9526-2b55-e3b0-8bfb-e4475649af19` |
| Environment URL | `https://org734d2f31.crm.dynamics.com` |
| Solution unique name | `BRMSGovernanceControlTower` |
| Solution display name | `BRMS Governance Control Tower` |
| Solution version | `1.0.0.3` |

## Preserved BRMS resources

| Resource | List ID | Site URL |
|---|---|---|
| Governance Control Tower | `249e7c48-b75e-4b14-9ff0-eb00a854111a` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |
| BRMS Configuration | `8a5524c7-01bd-4608-899f-62281313a8c6` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |
| BRMS Notification History | `ef96f9df-2e83-4040-9201-da4e8087918f` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |
| BRMS Automation Run History | `f0f62faf-86bb-4257-9c0d-f4f8571e71e2` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |

## Required BRMS Configuration keys

The corrected flows read and validate these Configuration rows at runtime. Missing rows cause `Terminate_missing_configuration` to fail the run.

| ConfigKey | Kind | Value contract |
|---|---|---|
| `review-rules-v1` | ReviewRules | `{ "calendarMonthsByFrequency": { "Monthly": 1, "Quarterly": 3, "Semi-Annual": 6, "Annual": 12 }, "dueSoonMaximumDays": 30 }` |
| `notification-settings-v1` | NotificationSettings | `{ "mode": "preview", "outboundRemindersEnabled": false }` (reminders remain preview-only regardless) |
| `source-library-map-v1` | SourceLibraryMap | JSON array of `{ "sourceKey": string, "siteUrl": string, "siteServerRelativePath": string, "folderServerRelativeUrl": string, "matchPrefix": string }` entries. `matchPrefix` is matched case-insensitively against the register's `DocumentLink` URL. |

## Package generation

Run the generator outside the repository so the ZIP and connection-bound settings are not committed:

```powershell
.\scripts\New-BrmsFlowSolution.ps1 `
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
  -OutputDirectory '<restricted-output-folder>'
```

The generator prints the ZIP path, SHA-256, and solution version. Report the resulting hash in the deployment record; the ZIP itself is not committed.

## Required connection-reference binding

`pac solution create-settings --solution-zip BRMSGovernanceControlTower.zip --settings-file settings.json`, then bind:

| Logical name | Connector ID | Required binding |
|---|---|---|
| `cr1e9_BRMSSharePoint` | `/providers/Microsoft.PowerApps/apis/shared_sharepointonline` | Existing connected SharePoint connection with access to the BRMS site and all configured source sites |

## Import status

Import remains blocked at Power Platform solution-checker enforcement. See `docs/flow-creation-status.md` for the recorded async operation ID, error text, and post-check results. The implementation corrections in this commit do not change the import result.

## Maker/admin action required

1. Resolve the environment's solution-checker enforcement failure or import the package through the Power Automate maker portal with the `cr1e9_BRMSSharePoint` connection reference bound to the SharePoint connector connection.
2. Populate `review-rules-v1`, `notification-settings-v1`, and `source-library-map-v1` rows in BRMS Configuration.
3. Confirm the three flows exist with these exact names: `BRMS - GCT - Review Schedule Refresh`, `BRMS - GCT - Review Reminders`, `BRMS - GCT - Source Document Monitor`.
4. Keep reminders in preview; do not add outbound send actions until rollout is approved.
5. Test Review Schedule Refresh against the synthetic records in `Governance Control Tower`, verify writes to `NextReviewDue`, `DaysToReview`, and `Status`, then run reminders and source monitoring in that order.
6. Record flow IDs, management URLs, run IDs, run results, list changes, notification preview rows, source observations, and Automation Run History rows in the Loop workspace.
