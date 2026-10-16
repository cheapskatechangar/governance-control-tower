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

Approval resolves the timing decision. It does not establish that the schedule is implemented or that production delivery is enabled. Installed solution 1.0.0.8 still records generic due/overdue preview candidates, contains no email send action, and remains restricted to synthetic records with schedules Off. Its previous successful preview runs are not evidence for the newly approved cadence.

The next reminder implementation must read these configured offsets and repeat interval, use the same business-date convention as refresh, deduplicate each scheduled occurrence within its review cycle and recipient, and preserve the successful-current-refresh and per-item eligibility checks. A single “Overdue” key is insufficient for weekly repeats. Preview records must not suppress subsequent real delivery, and a failed or uncertain delivery must not be recorded as Sent.

Acceptance must include due offsets 31/30/29, 15/14/13, 8/7/6 and 1/0/-1, plus 6/7/8 and 13/14/15 days overdue, repeat runs, review completion, inactive records, stale refreshes and delivery failures. First delivery validation uses the configured test recipient. Production scope and outbound delivery stay disabled until implementation and acceptance are complete.
