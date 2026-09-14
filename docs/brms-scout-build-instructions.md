# Scout build instructions: BRMS document governance

## Mission and confirmed scope

Build the Business Resilience Management System (BRMS) deployment of Governance Control Tower in Microsoft 365. This duplicates the document-governance system for another part of the organization. Carry the work through discovery, creation, configuration, testing, repository updates, and a usable handoff. Do not stop after producing an architecture or a list of suggested steps.

- Repository: https://github.com/cheapskatechangar/governance-control-tower
- BRMS home site: https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS
- The home site is the navigation hub and default resource location. It is not a mandatory storage location for every list, library, or document.
- Source baseline: `Governance_Control_Tower_SharePoint_List_Setup_Guidev2.docx`, the guide already supplied to the team. The repository now transcribes its 14 document fields, form, views, and review rules.
- The guide's body labels itself Version 1.0, prepared August 28, 2026. Its explicit scope is document governance. The older RTO, immutable backup, recovery testing, and blue/green material is preserved in `docs/legacy/technical-resilience/` for historical reference. Do not build those modules for this deployment. Playbook remains a valid document type.
- Use existing BRMS Power Automate patterns where found. If no pattern is available, proceed with the provisional flow name `BRMS - GCT - <Function> - <DEV|PROD>` and record the assumption.

Read `README.md`, `docs/field-schema.md`, `docs/setup-guide.md`, `docs/power-automate-flows.md`, `docs/deployment-checklist.md`, `config/brms-document-form.json`, and `config/brms-deployment.example.json` before building. These active documents supersede the legacy scope. Apply the user's latest directions if they change this brief.

## 1. Inspect what already exists

Inspect the BRMS site, existing lists/libraries/pages, connected Power Automate environment, and accessible BRMS flows. The team may already have created the register from the guide. Locate it before creating another list.

Record actual URLs, list/library IDs, internal field names, column types, choice values, form layout, views, permissions, flow names/IDs, owner connections, schedules, and the current operating state. Distinguish observations from assumptions. A flow inventory entry saying `Existing` in the legacy docs is not evidence of a live BRMS flow.

Reuse compatible resources. Do not replace populated columns, recreate the whole list, move source documents, overwrite unrelated page content, or alter the original organization's deployment. For a populated schema mismatch, document a data-preserving mapping or migration and continue independent work. Do not treat access-denied as proof that a resource does not exist.

Inspect accessible original document-governance flows or exports when available. The repository currently contains no exported flow definitions. Build from the documented rules where sufficient and identify any behavior that cannot be verified as an exact duplicate. Do not reuse the Enterprise AI Agent Control Tower/Planner workflow or infer that its environment belongs to BRMS.

Identify the available Power Platform environment and normal BRMS deployment practice. DEV and PROD must have distinct resource bindings and test boundaries; this does not mean creating new Power Platform environments. Do not invent environment IDs, connection identities, business owners, or test recipients.

Use supported authenticated tools and the connections available to you. The existing PowerShell scripts only attempt to create one list and may continue after authentication is skipped. Validate the target connection and make scripts fail on an unavailable connection before using them. Do not present the wrapper's success message as a complete deployment.

## 2. Implement independently configurable resource locations

Separate the home-page address, each resource's address, and the authenticated connection used to access it. Most resources can begin at BRMS; each must also be able to point elsewhere through configuration.

| Logical resource | Default placement | Location requirement |
|---|---|---|
| Governance register | Existing compatible BRMS register, otherwise BRMS site | Its own site URL and list ID |
| Configuration | BRMS site | Its own bootstrap site/list binding |
| Notification history | BRMS site | Its own site URL and list ID |
| Automation run history | BRMS site | Its own site URL and list ID |
| Source document libraries | Existing locations discovered for this deployment | One mapping per site/library/folder scope |
| Governed document | Its original location | DocumentLink plus resolved source identity where supported |
| Home page and reporting | BRMS navigation hub | Links/data sources resolved from the resource map |

Create a resource map per environment containing logical role/source key, site URL, list/library ID, display name, optional folder scope, connection binding, and enabled state. Use explicit source mappings. Do not derive every URL by appending a path to the BRMS home site, or use display name alone to identify resources.

Implement the example configuration contract rather than treating its JSON as executable. Its null IDs and empty source list are unresolved settings. A null resource site URL may explicitly inherit the configured default; a missing or inaccessible resolved resource must fail that operation with a useful error, never silently fall back to BRMS or another environment.

Use one authoritative live configuration store for each environment. A practical minimum for a BRMS Configuration list is a unique `ConfigKey`, `Environment`, `Kind`, `Value` (plain multiline JSON or equivalent typed fields), and `Enabled`. Document the final schema and value validation. Store source identities/checkpoints here or in a small companion operational list when needed; do not overload Notes or add unnecessary fields to the 14-column register.

The configuration list cannot discover its own location. Keep its minimal bootstrap binding in deployment settings/environment variables or an explicitly documented flow initialization. Treat changes to bootstrap settings as deployment configuration changes.

Prefer solution cloud flows with environment variables and connection references if the available environment supports them. Environment variables supply values to flow triggers and actions; directly changed values can require saving or restarting affected flows. Connection references supply authenticated connections, while resource mappings select the actual sites and lists. Include validation and binding refresh in the relocation runbook. See [Microsoft's environment-variable guidance](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/environmentvariables-power-automate) and [connection-reference guidance](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/create-connection-reference).

If solution features are unavailable, use standard connectors with the configuration list and a small documented bootstrap. Record any connector/trigger limitation. Do not introduce a premium dependency or app registration merely for convenience.

For source monitoring, prefer scheduled iteration over registered documents and configured sources for the first implementation. If using events, provide a verified trigger binding for each monitored source and reuse processing behavior where the platform supports it. A settings lookup inside a running flow does not automatically subscribe a trigger to new libraries. Record every trigger binding and the steps needed when a source is added or moved.

Centralized visibility does not require copying the documents or granting broader access. Keep DocumentLink pointed at the original. Validate the flow connection's access and the intended user's ability to open the link separately. Documents outside a supported/configured source remain governed by review dates but must be identified as not automatically monitored.

## 3. Build the SharePoint register and supporting resources

Apply the exact baseline in `docs/field-schema.md`: **14 fields including Title**, not 14 additional columns. Preserve the existing list name when the team has already built the correct register. Candidate bootstrap names are `Governance Control Tower - DEV` and `Governance Control Tower`; resolve actual live names before creation.

Required fields are Document Name, Document Link, Document Type, Department, Owner, Last Reviewed Date, Review Frequency, and Active. Optional fields are Reviewer, Notes, Next Review Due, Days to Review, Status, and Source Modified Date. Preserve the guide's exact internal names, choices, person settings, and date formats.

Disable attachments, enable version history, and apply `config/brms-document-form.json` after verifying display names. Create all five baseline views: All Active Documents, My Documents, Overdue, Due in 30 Days, and Inactive - Archived. Make All Active Documents the default. Use the documented filters and sorting.

Create or reuse separately mapped Configuration, Notification History, and Automation Run History lists. Document their schemas and field ownership:

- Notification History needs a unique notification key, environment/register/item identity, review-cycle due date, rule/threshold, intended recipient identity, state, attempt time, sent time, and safe outcome/run details. A deterministic hash can fit a compound key into a unique single-line column. Keep sufficient source fields to explain that key.
- Automation Run History needs a run/correlation key, environment, function/flow identity, start/end, mapping/configuration version, counts, result, failed resource/item references, and sanitized errors.
- Source monitoring needs a stable file-to-register mapping and checkpoint where supported. Use site/library/file identity plus register identity, not a title or an item number by itself. Keep this state in a documented companion resource if it cannot fit cleanly in Configuration.

Preserve the team's existing access model. Avoid creating a second central document library when existing locations suffice. Create a new controlled-document library only where the BRMS deployment actually needs storage, and record its mapping independently.

Create/update the BRMS landing page with links to the register, its views, document locations, and short instructions covering ownership, review completion, and archiving. Use native list views for the initial working dashboard. Add available status counts with last-refresh information where supported. Reconnect an existing Power BI report if one belongs to this system; do not invent its measures or make a new report a blocker for core delivery.

## 4. Build the complete document-governance flows

### Review Schedule Refresh

Build a daily scheduled flow using the configured register and business time zone. For active documents, calculate the next due date from LastReviewedDate plus 1, 3, 6, or 12 calendar months for Monthly, Quarterly, Semi-Annual, or Annual. Calculate DaysToReview using local calendar dates. Use the guide's status boundaries: negative = Overdue; 0 through 30 inclusive = Due Soon; greater than 30 = Current; missing review date = Not Set.

Handle invalid/missing frequencies and imported incomplete rows safely: set Not Set, clear stale derived values, and record the input problem. Verify month ends and leap years; use the last valid day where a target month lacks the original day. Do not substitute fixed day counts for calendar months.

Write only NextReviewDue, DaysToReview, and Status, preferably only when changed. Preserve Owner, Reviewer, LastReviewedDate, DocumentLink, and other human-maintained values. Keep history for inactive records and exclude them from active work. Record the run result and counts.

### Review Reminders

Build a scheduled reminder flow that follows a successful relevant refresh, or re-evaluates current eligibility itself. Two start times alone do not establish successful sequencing. Read configuration for the reminder thresholds, overdue repeat interval, time zone, schedule, and recipient rule.

The source guide establishes a 30-day Due Soon window, but does not specify reminder cadence, escalation recipients, or notification templates. Inspect source behavior and BRMS practice. Where unresolved, construct the flow and templates in preview, record the missing setting, and continue the rest of the build. Do not import 30/14/7 thresholds from the unrelated Technical Resilience flows as established BRMS policy.

Preview must show the intended recipient, document, review due date, status, and direct original-document link without sending. Actual messages should give the owner a clear review action and should not imply that an edit or republish counts as review completion.

Use an atomic unique notification key including environment, register identity, item identity, review cycle, rule, and recipient. Record Preview, Pending, Sent, Failed, Suppressed, or Unknown outcomes. Repeated runs and concurrent attempts must not produce duplicate reminders. Handle a send-success/log-failure ambiguity as Unknown for reconciliation, not a blind resend. Known send failures may be retried according to the documented bounded retry policy. Suppress inactive, ineligible, already-notified, and unresolved-recipient records with a recorded reason.

Do not send to real owners/reviewers while constructing or testing. A send test requires an explicitly authorized test recipient; otherwise validate in preview. Production notifications and cutover remain disabled until the user authorizes the concrete rollout. This does not block building and testing the available components.

### Source Document Monitor

Build scheduled monitoring across configured sources. Start with registered documents only. Resolve the actual file and its modified timestamp, update only SourceModifiedDate, and retain usable source identity/checkpoints. Support centrally held documents and files on other mapped sites.

A source edit, new version, or republish must never update LastReviewedDate, reset the review cycle, or assert review approval. Log inaccessible sources, missing/deleted files, unsupported locations, and unresolved links as distinct outcomes. Preserve the last known source observation when a read fails and show failure/staleness in operational reporting.

Validate rename/move behavior using the identifiers available from the connector. Update a link only after confirming it is the same document and documenting that behavior; otherwise flag it for resolution. Do not match only by file name or title, copy the document into BRMS, or silently create a register entry with invented required fields. A discovery/enrollment workflow can be proposed separately if BRMS requests one.

### Shared operating behavior

Use pagination, filtered/indexed queries where needed, bounded retries, explicit timeout/failure handling, and per-item error reporting. Prevent overlapping processing from duplicating sends or overwriting recent user changes. Re-read records and patch only flow-owned fields where the connector requires concurrency protection.

Maintain a single documented owner for each automated field. Record the actual connector/connection bindings and test that no copied flow still points at the original deployment or crosses into PROD during DEV tests.

A separate review-approval workflow is not part of the established baseline. The existing form allows Last Reviewed Date to be updated after the approved review process. Do not invent approvers or an automatic review-completion action. Record any genuinely missing review-process requirement for the business owner.

## 5. Acceptance tests

Use isolated BRMS test records and actual test documents. A home-page link can verify hyperlink entry, but cannot prove file monitoring. Retain test IDs and run evidence. Test at least:

| Area | Required proof |
|---|---|
| List/form/views | Exact 14 baseline fields; required-value checks; single-person fields; correct choices; four form sections; five views; My Documents and Active filtering |
| Date rules | All four frequencies; Current/Due Soon/Overdue; days -1, 0, 30, 31; missing date; invalid frequency; month end; leap year; configured local date boundary |
| Review integrity | Source modification/republish changes SourceModifiedDate only; LastReviewedDate and its review cycle stay unchanged |
| Reminders | Preview shows correct intended recipients; inactive/unresolved cases suppressed; repeated and concurrent runs deduplicate; new legitimate review cycle can be notified |
| Failure recovery | A record failure does not silently lose later records; inaccessible source is visible; ambiguous send is reconciled; successful records are counted accurately |
| Distributed documents | Register at its mapped location and a real registered document on a second accessible site; correct source observation and link access |
| Resource relocation | Rebind one supporting DEV resource to another test location using configuration, refresh affected bindings, and rerun without rewriting business logic |
| Isolation and permissions | DEV cannot write to the original system or PROD; an intended reader can use the page and permitted source links |

Use a second site only when it is actually available and authorized for the test. If unavailable, finish all other tests and report the distributed-location proof as blocked, not passed. A simulated mapping does not substitute for a live cross-site test.

Relocation means configuration plus controlled rebind/redeployment and validation where the platform requires it. It does not promise that moving a library preserves every identifier or that a SharePoint-bound custom form moves automatically. Prefer the baseline native list form and document any remaining resource-bound behavior.

## 6. Repository updates, handoff, and completion

Create or reuse a BRMS work branch such as `scout/brms-build`, commit meaningful milestones, and preserve unrelated work. Keep the active docs aligned with actual implementation. Add reusable sanitized flow exports, schema/form/view definitions, configuration schema and example, deployment/rebind steps, verification results, and operator instructions.

This repository is public. Keep secrets, credentials, actual employee recipient lists, controlled document contents, and populated operational exports in the access-controlled BRMS location. Commit sanitized examples and a description of where operators maintain the restricted configuration/evidence. Do not upload a source solution export until its contents have been checked for embedded organizational data.

Produce a handoff inventory listing each live resource/flow, its location, environment, function, operating state, and owner; reference run evidence from an appropriately restricted location. Distinguish **specified**, **created**, **configured**, **tested**, **enabled**, and **blocked**. Do not call the deployment complete because the instructions or flow stubs exist.

Include the exact procedure to add a source library, relocate a resource, change a connection, change reminder settings, archive a register record, complete a document review, investigate failures, and roll back BRMS changes. Preserve the original deployment and existing documents throughout.

Proceed autonomously through the available reversible build and test work. If access, a required business setting, or a missing source artifact blocks one component, state the exact dependency and affected component, continue independent work, and group remaining questions into one concise handoff. Do not repeatedly request confirmation for routine implementation choices.

The requested outcome is a working BRMS document register, usable forms/views/home navigation, configurable resource mappings, the three implemented flows, operational history, test evidence including distributed-location verification when access permits, and a documented path to enable authorized production communications.
