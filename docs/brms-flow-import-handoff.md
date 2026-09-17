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
| Solution version | `1.0.0.4` |
| Package validation | `tests/Test-BrmsFlowArtifacts.ps1` passes |

## Confirmed root cause of the import block

The blocker is tenant/environment Managed Environments policy (`RunSafeChecker`), not our package content. Verified:

- Import of a minimal single-`Compose`-action package (no connections, no expressions) to environment `722e9526-2b55-e3b0-8bfb-e4475649af19` failed with the identical server-side error.
- Async operation `7987af49-44b2-f111-aaac-7ced8d3bdfca` completed with `statuscode=Failed` and message `An error occurred while trying to run solution checker enforcement on the importing solution.` (Activity ID `f53969c2-8637-41af-8de8-586b0a1576d2`, ErrorCode `-2147188660`).
- Source: `Plugin/Microsoft.Crm.WebServices.ImportXmlService` → `Microsoft.Crm.Tools.ImportExportPublish.RunSafe.RunSafeHandler.RunSafeChecker`.
- `pac solution check` also hangs at 30% analyzing indefinitely — the Power Apps Checker service is failing for this tenant.

Per direction, we did not re-import the same rejected content and did not bypass checker enforcement.

## Package refinements applied in this commit (independent of the enforcement blocker)

Improved the generated flow definitions to match Microsoft's exported reference pattern (PROVEBackendFlows solution):

- `connectionReferences.shared_sharepointonline.runtimeSource` = `invoker` (was `embedded`).
- Removed workflow-definition-level custom parameters (`brmsRegisterSiteUrl`, `brmsRegisterListId`, etc.); the generator inlines the resolved literal values at generation time. Independent configurability is retained by regenerating the package with different generator parameters.
- Default solution version bumped to `1.0.0.4`.

These are structural refinements that align our workflow JSON with the tenant's own successful solution exports. They do not address the environment-level enforcement failure.

## Preserved BRMS resources

| Resource | List ID |
|---|---|
| Governance Control Tower | `249e7c48-b75e-4b14-9ff0-eb00a854111a` |
| BRMS Configuration | `8a5524c7-01bd-4608-899f-62281313a8c6` |
| BRMS Notification History | `ef96f9df-2e83-4040-9201-da4e8087918f` |
| BRMS Automation Run History | `f0f62faf-86bb-4257-9c0d-f4f8571e71e2` |

## Required Power Platform admin action

The only remaining path to create the three flows in environment `722e9526-2b55-e3b0-8bfb-e4475649af19` is a Power Platform admin action:

1. Adjust or resolve the Managed Environments solution-checker enforcement setting for env `722e9526-2b55-e3b0-8bfb-e4475649af19` so `RunSafeChecker` does not fail every solution import. Supporting evidence: async op `7987af49-44b2-f111-aaac-7ced8d3bdfca`, activity `f53969c2-8637-41af-8de8-586b0a1576d2`.
2. Alternatively, provision a target environment for BRMS whose Managed Environments policy does not block solution import.
3. Alternatively, authorize maker-designer manual creation for the three flows and provide business decisions for reminder cadence and authorized test recipient.

## Prepared package regeneration

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

Bind the connection reference `cr1e9_BRMSSharePoint` (connector `/providers/Microsoft.PowerApps/apis/shared_sharepointonline`) to an existing SharePoint connection with access to the BRMS site and any configured source sites.

## Post-import verification

After the admin action succeeds and the package imports:

1. Populate `BRMS Configuration` with `review-rules-v1`, `notification-settings-v1`, `source-library-map-v1`.
2. Confirm flow names: `BRMS - GCT - Review Schedule Refresh`, `BRMS - GCT - Review Reminders`, `BRMS - GCT - Source Document Monitor`.
3. Keep the recurrence triggers disabled during verification; run on-demand.
4. Verify against synthetic register records; confirm run-history rows show actual `SuccessCount`, `FailureCount`, failed references, and `SanitizedErrors`.
5. Confirm reminders remain preview-only (no outbound send action).

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
