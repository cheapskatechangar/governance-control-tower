# BRMS document governance field schema

Baseline: `Governance_Control_Tower_SharePoint_List_Setup_Guidev2.docx`, column register and settings on pages 4-6; review logic on page 11. The file's body labels itself Version 1.0. This replaces the older Technical Resilience schema, preserved under `legacy/technical-resilience/`.

## Required baseline

There are **14 business fields including the existing Title field**. Create 13 new columns if starting from a blank list. Inspect an existing list first and preserve correct internal names.

| Display name | Internal name | Type | Required | Settings |
|---|---|---|---|---|
| Document Name | Title | Single line of text | Yes | Rename the existing Title display label; never create a second title field |
| Document Link | DocumentLink | Hyperlink | Yes | Link to the original governed document wherever it is held |
| Document Type | DocumentType | Choice | Yes | Policy, Standard, Procedure, Guideline, Architecture Decision Record, Runbook, Playbook, Other; no fill-in choices |
| Department | Department | Single line of text | Yes | Maximum 255 characters |
| Owner | Owner | Person | Yes | People only; one person |
| Reviewer | Reviewer | Person | No | People only; one person |
| Notes | Notes | Multiple lines of text | No | Plain text; six editing lines |
| Last Reviewed Date | LastReviewedDate | Date and time | Yes | Date only; no default |
| Review Frequency | ReviewFrequency | Choice | Yes | Monthly, Quarterly, Semi-Annual, Annual; no fill-in choices |
| Next Review Due | NextReviewDue | Date and time | No | Date only; no default; flow-managed |
| Days to Review | DaysToReview | Number | No | Zero decimal places; no default; flow-managed |
| Status | Status | Choice | No | Current, Due Soon, Overdue, Not Set; default Not Set |
| Source Modified Date | SourceModifiedDate | Date and time | No | Date and time; no default; source-observation flow owns this field |
| Active | Active | Yes/No | Yes | Default Yes |

Create a column using its exact internal-name spelling, save it, then change only its display label. Do not use calculated columns for NextReviewDue, DaysToReview, or Status. Keep automation state and monitoring diagnostics in supporting lists unless a specific additional core field is justified and documented.

## Review rules

| Frequency | Due-date calculation |
|---|---|
| Monthly | LastReviewedDate plus 1 calendar month |
| Quarterly | LastReviewedDate plus 3 calendar months |
| Semi-Annual | LastReviewedDate plus 6 calendar months |
| Annual | LastReviewedDate plus 12 calendar months |

Calculate DaysToReview as the difference between the due date and today's local calendar date in the configured business time zone. Do not substitute fixed 30/90/180/365-day intervals. Verify month-end and leap-year behavior; when the target month lacks the original day, use its last valid day and document the implemented behavior.

| Condition | Status |
|---|---|
| LastReviewedDate missing, or frequency unusable | Not Set; clear stale derived dates/counts and log invalid input |
| DaysToReview < 0 | Overdue |
| DaysToReview from 0 through 30 inclusive | Due Soon |
| DaysToReview > 30 | Current |

The missing-date and day-boundary rules come from the guide. Clearing stale derived values, handling invalid frequencies, business-time-zone evaluation, and month-end verification are build requirements to make the implementation predictable. The field is required in normal entry, but flows must still handle incomplete imported or legacy rows.

Inactive records are excluded from active reminders and dashboards. Preserve their history; any refresh behavior for inactive records must be explicit.

`SourceModifiedDate` is evidence of a source edit. It must never automatically become `LastReviewedDate`. Only a completed governance review can update the latter. The refresher, reminder, and source-monitoring flows have no authority to mark a governance review complete.
