# BRMS document governance flows

The active system follows the supplied document-governance setup guide. The Technical Resilience flow inventory has been retained under `legacy/technical-resilience/` and must not be deployed as the BRMS document-governance baseline.

## Naming and implementation basis

Discover an existing BRMS flow or documented convention first. If none is available, use the proposed pattern `BRMS - GCT - <Function> - <DEV|PROD>` for new flows. Record the naming decision and the actual Power Automate environment. A DEV suffix or separate SharePoint list does not prove that a separate Power Platform environment exists.

No exported baseline flow definitions are currently present in this repository. Inspect authorized live source flows when available. Rebuild from the schema and rules below where sufficient; identify unverified behavior instead of calling it an exact copy.

## Required flows

| Function | Suggested function name | Behavior | Current status |
|---|---|---|---|
| Review due dates | Review Schedule Refresh | Scheduled daily; resolve the register; calculate NextReviewDue, DaysToReview, Status; preserve unrelated fields | Specification only |
| Review reminders | Review Reminders | Scheduled after successful refresh; select active due records; use configurable thresholds and recipients; prevent duplicate notifications | Specification only |
| Source observations | Source Document Monitor | Scheduled monitoring of configured registered documents/source libraries; update SourceModifiedDate; log unresolved or inaccessible sources | Specification only |

Use a configured recurrence time and business time zone. The guide establishes daily refresh and a 30-day Due Soon window. It does not establish reminder frequency, escalation cadence, recipients beyond ownership roles, or a review-approval workflow. Discover those settings; if unavailable, build disabled notification templates and record the minimum unresolved decisions while completing the rest.

## Configuration and portability

Prefer solution cloud flows, environment variables, and connection references when supported by the available environment. Keep one authoritative runtime resource map; the repository JSON is a template/export contract, not a second live settings store.

Environment variables can supply solution-flow trigger and action parameters. A directly changed value may not take effect until the flow is saved or switched off and on. Include binding validation and a controlled refresh step in the relocation runbook. [Microsoft Learn: environment variables in flows](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/environmentvariables-power-automate).

Connection references bind solution components to authenticated connections. Configure resource addresses separately and verify the selected connection can access every mapped site. [Microsoft Learn: connection references](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/create-connection-reference).

If solution features are unavailable, use a documented standard-connector configuration list and a small explicit bootstrap configuration per flow. Record any fixed trigger binding. Do not require a new app registration, premium connector, or custom service without an actual dependency.

A flow action can resolve a source after execution begins; a source event must already have a working trigger binding. For several source libraries, use scheduled iteration over configured sources or verified individual trigger wrappers sharing the same processing behavior. Do not claim that a runtime lookup automatically subscribes an event trigger to every site.

## Reliability and field ownership

- Refresh owns only NextReviewDue, DaysToReview, and Status. Source monitoring owns only SourceModifiedDate. Reminder processing writes notification history and must not mark a document reviewed.
- Resolve stable source identity with site/library/file identifiers where supported. A URL change or permission failure must not reset review dates or create a duplicate record.
- Use source mapping and register identity, not title-only matching or bare item IDs across lists. Where required, keep identifiers/checkpoints in a companion operational list to retain the 14-field core schema.
- Observe source updates without copying documents. Do not auto-register an unknown document or invent its Owner, LastReviewedDate, or review frequency.
- Process pages of records, use bounded retries, log per-record failures, and prevent overlapping runs from overwriting recent user edits. Re-read before patching where needed and patch only owned fields.
- Keep review reminders in preview by default. Notification history must distinguish Preview, Pending, Sent, Failed, Suppressed, and Unknown delivery outcome. Log only necessary message metadata.
- Use an atomic unique notification key built from environment, register identity, item identity, review cycle, reminder rule, and intended recipient. Retry known failures safely; reconcile ambiguous sends instead of assuming a successful send or blindly resending.
- Use persisted run state or an equivalent mechanism to avoid relying only on two scheduled start times for refresh/reminder ordering. Recheck eligibility immediately before any authorized send.
- Record start/end time, environment, flow/run identity, resource mapping version, counts, result, and safe error details in Automation Run History. A source access failure must not appear as successful synchronization.

## Completion boundaries

Source modification is not review completion. A dedicated approval/review-completion flow is an optional extension requiring a defined business process. Do not invent approval authority or add it merely because an approvals connector exists.

Use native views as the first reporting layer. Connect existing Power BI reports if available and required, after verifying their data model. Report unavailable report definitions or licenses as a specific reporting gap without blocking the core list and flows.

For required test cases and delivery evidence, use [the Scout brief](brms-scout-build-instructions.md#5-acceptance-tests).
