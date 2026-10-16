# BRMS flow package handoff

## Target environment

Administrative metadata only. BRMS artifacts must remain unsuffixed.

| Field | Value |
|---|---|
| Environment name | `ELS-Operations-Prod` (verified in maker portal) |
| Environment ID | `2c2b2f3f-eec6-ea9e-a492-7114c0975e11` |
| Power Automate | https://make.powerautomate.com/environments/2c2b2f3f-eec6-ea9e-a492-7114c0975e11/flows |
| Dataverse environment URL | Pending live verification; do not reuse the previous environment URL |
| Solution unique name | `BRMSGovernanceControlTower` |
| Solution display name | `BRMS Governance Control Tower` |
| Current browser-import version | `1.0.0.10` |
| Package validation | Nine offline tests pass; two live test sends and repeat suppression verified; production acceptance pending |

## Current email deployment, 2026-10-16

Version 1.0.0.10 imported through the maker portal and activated successfully with BRMS SharePoint and BRMS Outlook connection references. Two synthetic test emails were logged as Sent; a repeat run created zero new sends. All schedules are Off and test delivery is disabled again. See [email implementation and run evidence](brms-email-delivery.md). Version 1.0.0.9 imported but failed activation at nine nesting levels; 1.0.0.10 corrects that package issue.

## Earlier browser deployment, 2026-10-15

The owner requested browser interaction instead of PowerShell. The maker portal authenticated successfully in the new target, accepted version `1.0.0.6`, and displayed a valid existing SharePoint connection for `cr1e9_BRMSSharePoint`. Versions 1.0.0.6, 1.0.0.7 and 1.0.0.8 imported successfully through the supported UI. All three flows now exist and have successful synthetic execution evidence. Repeat reminder deduplication passed. Schedules are Off after testing; production acceptance and live reminder implementation remain. The current result and remaining acceptance work are tracked in [browser deployment evidence](brms-browser-deployment.md).

The current native generator is `scripts/build_brms_browser_package.py`. It emits native workflow actions, reads the existing `resource-map-v2`, `review-rules-v1`, and `notification-settings-v1` contract, and resolves source mappings from `resource-map-v2.sourceLibraries`. It does **not** require a separate `source-library-map-v1` row. All three flows are packaged disabled and gated to synthetic validation. Email test mode additionally requires an explicit two-item allowlist and a single configured test recipient; preview mode sends no email. The historical PowerShell generator and its tests below describe an older package, not acceptance evidence for the current native package.

```bash
python scripts/build_brms_browser_package.py --output /path/outside/repository
python -m unittest discover -s tests -p test_brms_browser_package.py -v
```

## Historical deployment target update

On 2026-10-15 (America/New_York), the project owner reported access to the environment above and identified it as the BRMS target. This supersedes the previous target `722e9526-2b55-e3b0-8bfb-e4475649af19`.

The latest pushed implementation baseline at that point was `97955772456e19c99fd10ebebfa3edd6ab96a025`, solution version `1.0.0.4`. No deployment to the new target is claimed by this update. Its display name, permissions, connections, existing BRMS flows, checker behavior and acceptance results require live verification. Local uncommitted draft definitions are not part of this baseline.

Before importing, select the new environment by its exact ID, check for existing BRMS flows/solution, and bind `cr1e9_BRMSSharePoint` to a connection in that environment. Preserve the four existing SharePoint resources and independently configured source locations. Keep flow schedules disabled and reminders preview-only until synthetic-record acceptance passes. Record the actual package hash, import outcome, flow IDs/URLs and run evidence in the implementation Loop page.

## Historical import blocker in the previous environment

The prior investigation recorded a `RunSafeChecker` enforcement failure in environment `722e9526-2b55-e3b0-8bfb-e4475649af19`. The evidence below does not establish whether the new environment is affected or whether the BRMS flows execute correctly:


- Import of a minimal single-`Compose`-action package (no connections, no expressions) to environment `722e9526-2b55-e3b0-8bfb-e4475649af19` failed with the identical server-side error.
- Async operation `7987af49-44b2-f111-aaac-7ced8d3bdfca` completed with `statuscode=Failed` and message `An error occurred while trying to run solution checker enforcement on the importing solution.` (Activity ID `f53969c2-8637-41af-8de8-586b0a1576d2`, ErrorCode `-2147188660`).
- Source: `Plugin/Microsoft.Crm.WebServices.ImportXmlService` → `Microsoft.Crm.Tools.ImportExportPublish.RunSafe.RunSafeHandler.RunSafeChecker`.
- `pac solution check` also hangs at 30% analyzing indefinitely — the Power Apps Checker service is failing for this tenant.

Per direction, we did not re-import the same rejected content and did not bypass checker enforcement.

## Historical version 1.0.0.4 package refinements

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

## Current deployment path

Flow creation and import are complete in target `2c2b2f3f-eec6-ea9e-a492-7114c0975e11`. Continue the remaining boundary/failure-path acceptance listed in the current evidence document, confirm the two delivered test templates with the recipient, define manager escalation routing/threshold, and implement wider production routing before removing preview/synthetic gates. The approved cadence is implemented and controlled delivery/repeat suppression passed. See [the cadence decision](brms-reminder-cadence.md). The old environment's enforcement failure is retained as historical evidence, not an active diagnosis for this environment.

If this target rejects an import, capture its own operation ID and exact error, resolve actionable package findings, and escalate environment policy or service failures to the administrator. Do not disable enforcement or repeatedly import an unchanged rejected package.

## Historical PowerShell package regeneration

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

After the package imports into the current target:

1. Verify the enabled `BRMS Configuration` rows `resource-map-v2`, `review-rules-v1`, and `notification-settings-v1`. Source libraries are within the resource map.
2. Confirm flow names: `BRMS - GCT - Review Schedule Refresh`, `BRMS - GCT - Review Reminders`, `BRMS - GCT - Source Document Monitor`.
3. Confirm all flows imported disabled. Use controlled maker-portal testing; if the platform requires activation, restrict processing to the synthetic scope and turn the flow back off after testing.
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
