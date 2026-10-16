# BRMS email delivery implementation

Package 1.0.0.10 adds the approved 30/14/7/0-day cadence and weekly overdue occurrences to the native browser-import generator. It includes an Outlook HTML reminder and an overdue/escalation appearance preview. Manager escalation recipients and threshold are not yet defined, so there is no live manager route.

## Test delivery controls

All workflows still require the correct environment, synthetic-records-only scope and outboundRemindersEnabled=false. mode=preview creates no email. mode=test requires testEmailEnabled=true, exactly one testRecipients entry, and a testItemIds allowlist of at most two numeric register IDs. Only BRMS-TEST- records in Department BRMS Test are processed. Wider recipient settings are never used for test delivery.

Notification keys include register, record, review cycle, occurrence, mode and recipient. They deliberately omit package version and execution time. Preview cannot suppress test delivery. The unique SharePoint notification key claims each attempt before sending. Existing Pending or Unknown records require manual reconciliation. No automatic email retry is configured because the Outlook action has no idempotency-key contract and a timeout may occur after acceptance.

The flow rereads notification configuration and the register item immediately before sending. A changed/disabled configuration or changed/inactive item prevents sending. Successful connector acknowledgement is logged as Sent, with SentTime. Failure/timeout is logged as Unknown and the item fails. If logging fails after sending, the Pending claim remains and blocks blind resend. Sent means accepted by the connector, not proof of inbox receipt.

## Validation

Nine offline tests pass, including emitted cadence expression boundary cases, action dependencies, claim/send ordering, failure handling, conditional writes, template escaping, platform nesting depth and basic accessibility. These tests do not emulate all Power Automate expression behavior or verify Outlook rendering.

## Preview artifacts

- [Reminder](email-previews/reminder.html)
- [Overdue / escalation appearance](email-previews/overdue.html)

These static samples use synthetic content and a site-home link. Actual flow emails link to their specific governance record. All examples carry a TEST EMAIL banner.

## Live acceptance checklist

1. Bind BRMS Outlook to the approved account and import the disabled package.
2. Create two synthetic records for a reminder boundary and 7-day overdue boundary.
3. Configure only the approved test address and the two record IDs. Run refresh, then reminders.
4. Confirm two successful Send_test_email actions and two Sent audit records; inspect actual email appearance and links with the recipient.
5. Repeat the run and verify zero new sends.
6. Return mode to preview, testEmailEnabled to false and schedules Off.
7. Record run IDs, test results and any blocker in Loop and the repository.

No recipient addresses or private Loop sharing URL are stored in this public repository.

## Deployment checkpoint, 2026-10-16

Version 1.0.0.9 imported, but activation found a ninth nesting level in the failure path. No reminder run occurred. Version 1.0.0.10 combines selection and cadence conditions to stay within the platform limit and has imported successfully. A regression gate now checks nesting depth.

Synthetic register IDs 8 and 9 were created for the email test. The refresh run `08584094485248042883744853678CU02` succeeded; the UI verified ID 8 due 2026-11-15 (30 days remaining) and ID 9 due 2026-10-09 (7 days overdue). The reminder run `08584094481532770045953587335CU15` succeeded in 34 seconds. Its persisted audit shows 9 processed, 2 successful, 0 failed and 7 skipped. Notification entries for ID 8 / `due-30` and ID 9 / `overdue-7` both show `Sent` and SentTime 2026-10-16 09:52 America/New_York. The only destination was the configured test recipient. These are connector-accepted sends; recipient inbox rendering and receipt still need confirmation.

The repeat reminder run `08584094478049428163787803733CU15` succeeded in 27 seconds. Its persisted audit shows 9 processed, 0 successful/new sends, 0 failed and 9 skipped. Duplicate suppression passed. Existing Sent claims were reused without another send.

Final controls: all schedules Off, `mode=preview`, `testEmailEnabled=false`, `testItemIds=[]`, `outboundRemindersEnabled=false`; synthetic scope remains enforced. The saved configuration was reread. Intended live recipient settings were preserved but never used by this test.

Subjects were `[BRMS TEST] Review reminder: BRMS-TEST-EMAIL-REMINDER | Due 2026-11-15` and `[BRMS TEST] Overdue review: BRMS-TEST-EMAIL-OVERDUE | Due 2026-10-09`. The overdue example is an appearance preview, not implemented manager escalation. Next decisions: confirm inbox appearance and record-link behavior, then specify the escalation recipient and overdue threshold. Wider production routing and remaining failure-path acceptance are not complete.

Package SHA-256: `e1b26ed5ede72974547d6fbeaf95df4064b6fca6b5056428184f45bb5f0c5eaa`.
