# Owner-manager escalation

Approved in the project conversation on 2026-10-16: first escalation at 14 calendar days overdue, then every 7 days while the same review cycle remains overdue. The intended To recipient is the current owner's manager; the owner is copied. The policy is stored under `notification-settings-v1.escalation`.

## Implementation

Version 1.0.0.11 resolves the SharePoint OwnerId to its login UPN and email, then calls Office 365 Users Get manager (V2), selecting only id, displayName, mail and userPrincipalName. The new `cr1e9_BRMSDirectory` connection reference was bound to the existing approved account during maker import.

An explicit configured fallback can be used only for a missing manager (404) or missing manager mail. Both fallback contacts were approved later on 2026-10-16. Their addresses are recorded in restricted decision metadata. Multiple-recipient deployment is pending; the active single-recipient field remains empty. Missing or invalid destinations therefore stop that item and are logged. Authentication and service errors do not silently use a fallback. Routing state is reset for each record and included in failed/skipped audit references.

Actual email delivery remains restricted to the single configured test recipient and an allowlist of at most two synthetic items. The intended To/Cc route is included in the test email and restricted notification history, but no manager is contacted. Production sends remain disabled. This is implemented and tested routing intent, not a live production escalation service.

Existing conditional item/configuration rereads, atomic notification claims and ambiguous-send handling remain. Escalation occurrences are `escalation-14`, `escalation-21`, etc.; keys do not change on package upgrades or reruns.

## Validation

Eleven offline tests pass, including emitted escalation expression cases at 14/21/28 days, connector inputs, per-item route state, dependency/nesting constraints and test-recipient isolation.

The browser import of 1.0.0.11 succeeded. Flow Checker reported zero errors; its only pre-activation warning was that the flow was off. Refresh run `08584094355397551712186885863CU30` succeeded. Synthetic ID 9 had its Last Reviewed Date changed from September 9 to September 2, 2026 solely to exercise this boundary. The live register showed Next Review Due October 2 and Days to Review -14 on October 16.

Reminder run `08584094354329272205991537280CU25` succeeded in 42 seconds. Persisted audit: 9 processed, 1 success, 0 failures, 8 skipped. The notification row for ID 9 / 2026-10-02 / escalation-14 / test showed Sent at 13:24 America/New_York and resolution=manager, with intended manager To and owner Cc. Actual delivery was only to the approved test recipient. Sent records connector acceptance, not inbox receipt. Personal addresses are deliberately omitted from this public repository.

Subject: `[BRMS TEST] Manager escalation: BRMS-TEST-EMAIL-OVERDUE | Due 2026-10-02`.

Package SHA-256: `081a4d802eb8ef51fdb13206cacef81357a3093dea8cbf0a2604f92618209844`.

Repeat run `08584094353270186451013007350CU25` succeeded in 34 seconds: 9 processed, 0 new sends, 0 failures, 9 skipped. ID 9 retained routingStatus=manager. Duplicate suppression passed. After testing, schedules were turned Off and configuration restored to `mode=preview`, `testEmailEnabled=false`, `testItemIds=[]`, `outboundRemindersEnabled=false`.

## Remaining acceptance

Email appearance is confirmed. Implement and validate the two approved fallback contacts, confirm record links and new-owner access. See [handover checkpoint](brms-handover.md). Validate missing-manager, authorization/service failure, concurrency and wider production cases before enabling production delivery. No production schedule or real-manager sending is enabled by this change.
