# BRMS reminder cadence decision

Approved by the project owner in this project conversation on 2026-10-15 at 22:36:30 America/New_York.

| Timing | Configured value |
|---|---|
| Before review | 30, 14 and 7 calendar days |
| Due date | 0 days remaining |
| Overdue | Every 7 calendar days |
| Business timezone | America/New_York |

Weekly overdue reminders are anchored to the current review due date: days 7, 14, 21 and onward. This is the implementation interpretation of “then weekly while overdue.” The cadence applies while the active document remains overdue for that review cycle. Completing a review creates the next cycle through the existing review-date calculation.

## Recorded configuration

`BRMS Configuration` → `notification-settings-v1`:

```json
{
  "reminderOffsetsDays": [30, 14, 7, 0],
  "overdueRepeatDays": 7,
  "cadenceApproval": "approved",
  "mode": "preview",
  "outboundRemindersEnabled": false
}
```

Existing test and intended live recipients are preserved in the restricted live configuration. No recipient addresses are copied into this public decision record. The planning example records the approved cadence but is not a second live configuration store.

## Implementation boundary

Solution 1.0.0.11 implements the configured cadence with per-occurrence, review-cycle and recipient deduplication. The reminder flow uses the refresh business-date convention, requires a successful current refresh and revalidates the item and notification settings before sending. Preview records cannot suppress test sends. Failed or uncertain delivery is never recorded as Sent.

Eleven offline tests pass, including cadence boundaries 31/30/29, 15/14/13, 8/7/6, 1/0/-1 and weekly-overdue boundaries. Live tests on 2026-10-16 verified one 30-day reminder, one 7-day-overdue test email, and a repeat run with zero new sends. See [email delivery evidence](brms-email-delivery.md) for run IDs, audit counts and remaining acceptance.

This is controlled test delivery, not production enablement. Schedules are Off, mode is preview, testEmailEnabled is false and outboundRemindersEnabled is false. Recipient confirmation of appearance/link behavior, fallback-contact decision, wider production routing, and negative/concurrency acceptance remain.

## Manager escalation decision, 2026-10-16

Escalate at 14 days overdue and every 7 days thereafter. Resolve the current owner's manager from the directory and copy the owner. Controlled test delivery and repeat suppression passed in 1.0.0.11; production sending remains disabled. Missing-manager fallback has not been supplied and fails closed. See [manager escalation](brms-manager-escalation.md).
