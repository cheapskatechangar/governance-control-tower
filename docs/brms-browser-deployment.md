# BRMS browser deployment evidence

Date: 2026-10-15 (America/New_York).

## Current state

The first browser import reached workflow parsing and failed on missing clientdata schemaVersion. Version 1.0.0.6 corrects that error; successful live flow creation and runtime acceptance remain pending. This is not a completed production rollout.

| Field | Observed value |
|---|---|
| Target | ELS-Operations-Prod |
| Environment ID | `2c2b2f3f-eec6-ea9e-a492-7114c0975e11` |
| Import method | Maker portal UI; no PowerShell or tenant API script |
| Solution | BRMS Governance Control Tower |
| Corrected version | `1.0.0.6` |
| Corrected package SHA-256 | `7c27d897057889abf4d88c9870fbec489f942d1a85cabc4f969cdb64fc56f45a` |
| Connection reference | `cr1e9_BRMSSharePoint`; maker wizard displayed Valid connection |
| Import activity ID | `246643ee-cb5f-486a-8b30-43d955b4c1f2` |
| Version 1.0.0.5 import result | Failed after 5 m 20 sec, code `80060468`: missing root `schemaVersion` in workflow clientdata |
| Live run IDs | None verified |

The SHA identifies the corrected ZIP. The rejected version 1.0.0.5 ZIP had SHA-256 `a2e899c3fb81b6a94f8cf74612f0c09ca39492e1525d8917f6126442c9392d10`. Version 1.0.0.6 adds root `schemaVersion = 1.0.0.0`, explicit connector authentication expressions, and regression assertions, following the [Microsoft clientdata example](https://learn.microsoft.com/en-us/power-automate/manage-flows-with-code). The new-target error is a package validation finding, not the old environment's RunSafeChecker error. Regenerating with ZIP timestamps can change the archive hash without changing flow content. The previous environment's enforcement failure is retained separately in the handoff.

## Package and configuration

Three unsuffixed flows are packaged disabled:

| Flow | Responsibility |
|---|---|
| BRMS - GCT - Review Schedule Refresh | Compute calendar-month due dates, days remaining and review status |
| BRMS - GCT - Review Reminders | Record deduplicated preview candidates after a successful current refresh |
| BRMS - GCT - Source Document Monitor | Resolve configured document locations and update source-modified observations |

The current generator is `scripts/build_brms_browser_package.py`, with solution templates in `scripts/native-brms`. Existing list IDs are preserved. The configuration bootstrap address is explicit; each downstream resource resolves its own site URL and list ID from `resource-map-v2.resources`. Source mappings use `resource-map-v2.sourceLibraries`; documents need not reside on the register site. The current business day uses Eastern Standard Time (Windows timezone identifier, including DST).

The live resource map was updated with the new environment, explicit site URLs and `powerAutomate.validationScope = synthetic-records-only`. Processing requires both the `BRMS-TEST-` title prefix and the `BRMS Test` department. Item rereads and conditional ETag writes prevent overwriting a concurrently edited register record. Conflicts are surfaced for investigation; broader retry/revalidation acceptance remains pending.

Notification settings were saved and reread: enabled for preview processing, `mode = preview`, `outboundRemindersEnabled = false`. Test and intended live recipients are recorded in the restricted BRMS Configuration and implementation Loop page. The existing cadence was preserved and marked pending owner agreement. The package contains no email send action. Preview eligibility is a due/overdue candidate check, not implementation or approval of the final live reminder cadence.

## Verification performed

`python -m unittest discover -s tests -p test_brms_browser_package.py -v`: four tests passed. They check disabled flow declarations and version consistency, action dependencies and expression references, preview scope/no outbound connector, conditional writes, field ownership and actual run-accounting expressions. Separate local checks parsed all workflow JSON and checked expression delimiters.

These are structural checks. They do not execute Power Automate expressions, validate connector payloads against the tenant, or prove runtime behavior. Existing PowerShell tests are not the test harness for this native generator.

## Required acceptance before rollout

1. Confirm successful import, exactly three correct flow names, actual flow URLs, disabled state and valid connection binding.
2. Run refresh on synthetic records. Verify monthly end-of-month/leap-year behavior, missing dates, inactive rows, due/overdue boundaries, field ownership, concurrency protection and persisted counts/errors.
3. Run reminders before and after a current successful refresh; confirm gating, preview-only output, repeat-run deduplication and duplicate-create recovery.
4. Run source monitoring with mapped, unmapped and missing documents. Verify source timestamps, skipped/failure accounting, independent sites and preservation of review-completion fields.
5. Record actual platform run IDs and SharePoint history evidence; resolve runtime failures before declaring acceptance.
6. Deliberately remove synthetic scope only after acceptance and reconcile the implementation with production requirements. Agree and implement live reminder cadence before any outbound enablement.

The implementation Loop page was updated and reread with the new target, recipients, preview scope, package hash and pending import status. Its private sharing URL is intentionally kept out of this repository.
