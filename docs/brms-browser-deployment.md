# BRMS browser deployment evidence

Date: 2026-10-16 (America/New_York).

## Current state

Solution 1.0.0.10 is installed. The reminder flow implements the approved cadence and Outlook HTML test delivery. Two controlled emails were recorded as Sent; a repeat run produced zero new sends and zero failures. Nine offline tests pass. All three schedules are Off and preview-only settings are restored. Processing remains synthetic-only. This is not a completed production rollout. See [email delivery evidence](brms-email-delivery.md) for the current run IDs and controls. Earlier deployment evidence remains below.

| Field | Observed value |
|---|---|
| Target | ELS-Operations-Prod |
| Environment ID | `2c2b2f3f-eec6-ea9e-a492-7114c0975e11` |
| Import method | Maker portal UI; no PowerShell or tenant API script |
| Solution | BRMS Governance Control Tower |
| Current installed version | `1.0.0.10` |
| Current package SHA-256 | `e1b26ed5ede72974547d6fbeaf95df4064b6fca6b5056428184f45bb5f0c5eaa` |
| Connection references | `cr1e9_BRMSSharePoint` and `cr1e9_BRMSOutlook`; maker wizard displayed Valid connection |
| Historical 1.0.0.5 import activity ID | `246643ee-cb5f-486a-8b30-43d955b4c1f2` |
| Version 1.0.0.5 import result | Failed after 5 m 20 sec, code `80060468`: missing root `schemaVersion` in workflow clientdata |
| Current import result | Version 1.0.0.10 imported and activated successfully via the maker portal |
| Solution ID | `197184d6-cf12-4c72-81fd-614952dad0be` |
| Live run IDs | See verified synthetic runs below |

The current SHA identifies the installed version 1.0.0.10 ZIP. Version 1.0.0.8 had SHA-256 `3f304682a5b24ddcdf525751895134956c372e95a04422fd209278cbaa508999`. Version 1.0.0.7 had SHA-256 `89d5cd122e7da6a51e0353f9ab1ebcd1ce1e1d6dd745f55549aa57aa258f88d2`. Version 1.0.0.6 had SHA-256 `7c27d897057889abf4d88c9870fbec489f942d1a85cabc4f969cdb64fc56f45a`. The rejected version 1.0.0.5 ZIP had SHA-256 `a2e899c3fb81b6a94f8cf74612f0c09ca39492e1525d8917f6126442c9392d10`. Version 1.0.0.6 adds root `schemaVersion = 1.0.0.0`, explicit connector authentication expressions, and regression assertions, following the [Microsoft clientdata example](https://learn.microsoft.com/en-us/power-automate/manage-flows-with-code). The new-target error is a package validation finding, not the old environment's RunSafeChecker error. Regenerating with ZIP timestamps can change the archive hash without changing flow content. The previous environment's enforcement failure is retained separately in the handoff.

## Activation corrections in version 1.0.0.7

Activation of version 1.0.0.6 failed before execution with `OpenApiOperationParameterValidationFailed`: `Record_run` was missing the required `item` property. Dynamic list binding does not supply a design-time expanded item schema. The generator now supplies the complete item object to `PostItem`, matching the [SharePoint connector contract](https://learn.microsoft.com/en-us/connectors/sharepointonline/).

The inherited template also set `ModernFlowType = 1`, which displayed the Copilot Studio plan. It is now `0` (PowerAutomateFlow), per the [Dataverse workflow field definition](https://learn.microsoft.com/en-us/power-apps/developer/data-platform/reference/entities/workflow#modernflowtype). The refresh details now show the owner's plan and activation succeeds. Regression checks cover both fixes. Flow IDs are unchanged.

## Business-date correction in version 1.0.0.8

The existing synthetic row `BRMS-TEST-DUE-0` stored LastReviewedDate as `2026-08-13T00:00:00Z`, displayed by SharePoint as August 12 in Eastern time. Version 1.0.0.7 used the UTC date and wrote September 13. Version 1.0.0.8 converts the input to the business date before calendar-month arithmetic, writes due dates as explicit UTC equivalents of Eastern midnight, and compares reminder eligibility in that same business timezone. Refresh context and preview-key versions change to prevent reuse of pre-correction acceptance evidence. No review-completion date is rewritten.

Version 1.0.0.8 package SHA-256: `3f304682a5b24ddcdf525751895134956c372e95a04422fd209278cbaa508999`. Five structural regression tests pass. Import succeeded; regression run results follow.

## Version 1.0.0.8 regression evidence

Refresh run `08584094898217669724875932160CU13` succeeded in 16 seconds. SharePoint reread confirms `BRMS-TEST-DUE-0` now displays Last Reviewed August 12 and Next Review Due September 12, with -33 days on the October 15 business day. Other persisted results were: DUE-30 October 12 (-3); DUE-31 October 13 (-2); OVERDUE-1 September 11 (-34); MONTH-END February 28, 2026 (-229); LEAP-YEAR February 28, 2025 (-594). Review-completion inputs were preserved. The fixture names are historical: all active fixtures are overdue now, so this run does not establish current 0/30/31-day boundary coverage or a February 29 input case.

| Function | Run ID | Processed | Success | Failure | Skipped |
|---|---|---:|---:|---:|---:|
| Refresh | `08584094898217669724875932160CU13` | 7 | 6 | 0 | 1 |
| Source monitor | `08584094897663963210231033550CU12` | 7 | 1 | 0 | 6 |
| Reminder preview | `08584094897222858731911462047CU15` | 7 | 6 | 0 | 1 |
| Repeat reminder | `08584094896284882069410215344CU15` | 7 | 0 | 0 | 7 |

All four platform runs succeeded. Each persisted audit was reread. Versioned context starts `v8|`; reminder keys use `preview-v8`. Six new preview candidates were recorded for the corrected validation version, and the repeat run created no duplicates. Older preview records remain as evidence; none is a sent notification. All three recurrences were turned Off and verified after testing.

## Verified synthetic runs, version 1.0.0.7

Each row below was opened in BRMS Automation Run History. Platform runs also displayed Succeeded. Counts are actual persisted outcomes, not inferred from the flow-level status.

| Function | Run ID | Processed | Success | Failure | Skipped |
|---|---|---:|---:|---:|---:|
| Refresh | `08584094906605989872912408082CU29` | 7 | 6 | 0 | 1 |
| Reminder preview | `08584094905173106730657961893CU06` | 7 | 6 | 0 | 1 |
| Source monitor | `08584094904592668825677011333CU16` | 7 | 1 | 0 | 6 |
| Repeat reminder | `08584094903739637223104558555CU06` | 7 | 0 | 0 | 7 |

Runs started on 2026-10-16 at 02:03, 02:06, 02:07 and 02:08 UTC (October 15 Eastern). ID 7 was inactive. Source monitoring resolved ID 1; IDs 2–7 were skipped. Six preview records were present with the `preview-v5` key segment. The inspected preview had Outcome State `Preview`, empty Sent Time and explicit no-email-sent details. The repeat run created zero new records. Source monitoring left the register's review-completion and schedule fields unchanged; its mapped source timestamp was already current, so this verifies resolution/write execution, not detection of a newly edited document.

The Dataverse flow IDs in management URLs differ from `workflow().name` recorded by runtime. Both are valid identifiers for different platform layers.

## Verified flow URLs

| Flow | Management URL |
|---|---|
| Review Schedule Refresh | https://make.powerautomate.com/environments/2c2b2f3f-eec6-ea9e-a492-7114c0975e11/solutions/~preferred/flows/8780f732-daf8-d474-2446-467ce078b310/details |
| Review Reminders | https://make.powerautomate.com/environments/2c2b2f3f-eec6-ea9e-a492-7114c0975e11/solutions/~preferred/flows/1933d218-4d41-6d00-de53-90ce06846821/details |
| Source Document Monitor | https://make.powerautomate.com/environments/2c2b2f3f-eec6-ea9e-a492-7114c0975e11/solutions/~preferred/flows/1f91ba5b-65a5-9b09-8a3b-7b90b16040dd/details |

## Package and configuration

Three unsuffixed flows are packaged disabled:

| Flow | Responsibility |
|---|---|
| BRMS - GCT - Review Schedule Refresh | Compute calendar-month due dates, days remaining and review status |
| BRMS - GCT - Review Reminders | Apply the configured cadence; preview candidates or explicitly allowlisted test email after a successful current refresh |
| BRMS - GCT - Source Document Monitor | Resolve configured document locations and update source-modified observations |

The current generator is `scripts/build_brms_browser_package.py`, with solution templates in `scripts/native-brms`. Existing list IDs are preserved. The configuration bootstrap address is explicit; each downstream resource resolves its own site URL and list ID from `resource-map-v2.resources`. Source mappings use `resource-map-v2.sourceLibraries`; documents need not reside on the register site. The current business day uses Eastern Standard Time (Windows timezone identifier, including DST).

The live resource map was updated with the new environment, explicit site URLs and `powerAutomate.validationScope = synthetic-records-only`. Processing requires both the `BRMS-TEST-` title prefix and the `BRMS Test` department. Item rereads and conditional ETag writes prevent overwriting a concurrently edited register record. Conflicts are surfaced for investigation; broader retry/revalidation acceptance remains pending.

Notification settings were saved and reread: enabled for preview processing, `mode = preview`, `outboundRemindersEnabled = false`. Test and intended live recipients are recorded in the restricted BRMS Configuration and implementation Loop page. On 2026-10-15 at 22:36 Eastern, the project owner explicitly approved reminders 30, 14 and 7 days before review, on the due date, then every 7 days overdue. Live `notification-settings-v1` now records offsets `[30,14,7,0]`, `overdueRepeatDays = 7` and `cadenceApproval = approved`. Weekly overdue periods are anchored to the due date (7, 14, 21 days overdue and onward). This decision is recorded in [the cadence decision](brms-reminder-cadence.md). Version 1.0.0.10 implements this cadence and controlled test delivery. The two-email and repeat-run evidence is in [email delivery](brms-email-delivery.md). Recipient receipt/rendering and production enablement remain pending.

## Verification performed

`python -m unittest discover -s tests -p test_brms_browser_package.py -v`: nine tests passed. They check disabled flow declarations, version consistency, action dependencies, expression references, test-only send gates, conditional writes, actual accounting, cadence boundary behavior, claim/send ordering, failure handling, nesting depth, HTML escaping and basic accessibility.

These are offline structural and limited cadence-expression checks. They do not fully emulate Power Automate or prove runtime behavior. Separate live evidence is documented above. Existing PowerShell tests are not the test harness for this native generator.

## Required acceptance before rollout

1. Completed: successful import, exactly three correct flow names, verified URLs, disabled final state and valid connection binding.
2. Basic refresh, inactive skip, owned-field writes, business-date regression and persisted accounting passed. Refresh fixtures for current 0/30/31-day boundaries and an actual February 29 input; test missing dates and concurrent edits.
3. Preview after a current refresh and repeat-run deduplication passed. Still test the negative refresh gate and simultaneous-create recovery.
4. Mapped source resolution and unmapped/inactive skips passed. Still test a newly edited source, a missing/inaccessible file, independent sites and error accounting.
5. Run IDs and persisted SharePoint counts are recorded above. Complete the remaining failure-path and boundary cases before declaring production acceptance.
6. Deliberately remove synthetic scope only after acceptance and reconcile the implementation with production requirements. The cadence and controlled test sends are verified; confirm inbox appearance, define manager escalation, and implement/validate wider recipient routing before enablement.

The implementation Loop page records the new target, recipients, preview scope, import milestones and runtime evidence. Its current overview status and environment ID were corrected, preserving the historical log. Its private sharing URL is intentionally kept out of this repository.
