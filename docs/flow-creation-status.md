# BRMS Power Automate implementation and creation status

BRMS implementation defects are corrected in the generator and tests. The live cloud-flow creation blocker is separate and unchanged.

## Implementation corrections (in this commit)

| # | Correction | Evidence |
|---|---|---|
| 1 | Source site addresses and file paths resolve from configured mappings, not naive URL split. | `New-SourceMonitorWorkflow` reads `source-library-map-v1`, filters by `matchPrefix`, and composes `Compose_resolved_site` + `Compose_document_path` from the matched mapping. Unresolved sources append to `SkippedReferences` with reason `source-not-in-configured-map`. |
| 2 | Run success/failure counts and errors are calculated per-item and persisted. | Every workflow initializes `SuccessCount`, `FailureCount`, `FailedReferences`, `SanitizedErrors`, and `SkippedReferences`, uses `IncrementVariable`/`AppendToArrayVariable` on the outcome runAfter branches, and posts `@variables('SuccessCount')`, `@variables('FailureCount')`, and joined error/reference arrays to BRMS Automation Run History. |
| 3 | BRMS Configuration is read and validated at runtime. | Every workflow calls `Get_configuration` with paginated `GetItems`, `Compose_configuration_map`, `Validate_configuration` (terminates run when `review-rules-v1` or `notification-settings-v1` are missing), and parses `Parse_review_rules`/`Parse_notification_settings`. The refresh flow reads `calendarMonthsByFrequency` and `dueSoonMaximumDays` from configuration. |
| 4 | Reminders require a successful, current refresh before processing, recheck eligibility per record, and handle duplicate-create conflicts. | Reminder flow calls `Get_last_successful_refresh` from Automation Run History filtered to today's business boundary and terminates with `Record_refresh_gate_block` + `Terminate_no_refresh` when no successful refresh exists. Inside `For_each_due_document`, `Reread_current_document` + `Recheck_eligibility` protect against stale reads, and `Recover_duplicate_conflict` re-queries the notification key on create failure to reuse the existing preview row. |
| 5 | Retry policy placement corrected and pagination beyond 5,000 records enabled. | `New-OpenApiAction` places `retryPolicy` under `inputs` and pagination under `runtimeConfiguration.paginationPolicy` with `minimumItemCount = 100000`. Regression tests assert `runtimeConfiguration.retryPolicy` is not present anywhere in the generated definitions. |
| 6 | Records are revalidated before updates. | Refresh and source monitor call `Reread_current_document` before every patch. Refresh compares `Active` + `Modified` against the item snapshot from `Get_active_documents` before applying the patch. Source monitor gates the update on `Check_still_active`. |
| 7 | Focused tests now detect these defects. | `tests/Test-BrmsFlowArtifacts.ps1` fails on the reviewed commit `017321bcf01c1d35ffbaed57e33fced4549e03cd` (reproduced) and passes on the corrected generator. |

## Package artifacts

| Field | Value |
|---|---|
| Solution unique name | `BRMSGovernanceControlTower` |
| Solution display name | `BRMS Governance Control Tower` |
| Solution version | `1.0.0.3` |
| Generator | `scripts/New-BrmsFlowSolution.ps1` |
| Test harness | `tests/Test-BrmsFlowArtifacts.ps1` |
| Package validation | Local artifact tests pass on this commit |

The bound settings file and the generated ZIP are produced outside the repository so credentials and connection IDs are not committed.

## Live cloud-flow creation blocker (unchanged)

The implementation corrections above do not lift the live creation blocker recorded previously.

| Field | Value |
|---|---|
| Environment | `RIS-TechCentral-Low-DEV` / `722e9526-2b55-e3b0-8bfb-e4475649af19` |
| Import path attempted | `pac solution import --async` with the completed package |
| Result | Failed at Power Platform solution checker enforcement before creating any flow |
| Async operation ID | `93058e94-8cb0-f111-aaac-70a8a5af0770` |
| Error | `An error occurred while trying to run solution checker enforcement on the importing solution. Try importing the solution again. If this problem persists, contact your system administrator.` |
| Post-check | `pac power-automate list-cloud-flows` still returns zero `BRMS - GCT - ...` flows |

Preserved SharePoint resources continue unchanged:

- Governance Control Tower `249e7c48-b75e-4b14-9ff0-eb00a854111a`
- BRMS Configuration `8a5524c7-01bd-4608-899f-62281313a8c6`
- BRMS Notification History `ef96f9df-2e83-4040-9201-da4e8087918f`
- BRMS Automation Run History `f0f62faf-86bb-4257-9c0d-f4f8571e71e2`

## Prepared flow names

- BRMS - GCT - Review Schedule Refresh
- BRMS - GCT - Review Reminders
- BRMS - GCT - Source Document Monitor

Outbound reminders remain preview-only until rollout is explicitly authorized.

## What remains for BRMS completion

BRMS is not complete until the corrected package is imported and the three flows perform their required behavior with verified execution evidence:

1. Maker/admin resolves the solution-checker enforcement failure or imports the package manually through the maker portal with the `cr1e9_BRMSSharePoint` connection reference bound to the standard SharePoint connection.
2. Populate the BRMS Configuration list with the runtime keys the flows now consume (`review-rules-v1`, `notification-settings-v1`, `source-library-map-v1`).
3. Test Review Schedule Refresh against the synthetic BRMS records, confirm actual writes to `NextReviewDue`, `DaysToReview`, and `Status`, and record the flow ID, management URL, and run IDs.
4. Run reminders against the same records; confirm preview rows in `BRMS Notification History` with `Preview` outcome, refresh-gate skips when refresh has not run, and duplicate suppression across repeated runs.
5. Run Source Document Monitor against a document that matches a configured `source-library-map` entry and one that does not, and confirm `SourceModifiedDate` updates only for matched, resolvable sources.
