# BRMS build and acceptance checklist

## Discovery and source alignment

- [x] Record BRMS home site: https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS
- [x] Identify the supplied 14-field document-governance guide as the baseline.
- [x] Preserve older Technical Resilience documents separately.
- [ ] Verify BRMS site access and inspect the list the team may already have created.
- [ ] Identify the actual Power Automate environment, existing BRMS flow conventions, and usable connections.
- [ ] Inventory configured source libraries, including sources outside the home site.
- [ ] Record schema differences and unresolved business rules without changing populated fields blindly.
- [ ] Open the user-supplied implementation Loop page; inspect existing content, preserve contributions, and identify the current overview and relevant detail pages.

## Configuration and SharePoint

- [ ] Resolve an independent site/list/library mapping for every logical resource in each environment.
- [ ] Implement and validate configuration loading; the example JSON alone is not a working loader.
- [ ] Reuse or create the register with exactly the 14 baseline fields and correct internal names.
- [ ] Apply exact choices, required settings, date settings, attachment behavior, and versioning.
- [ ] Apply the four-section form and all five views.
- [ ] Create or reuse Configuration, Notification History, and Automation Run History with documented operational schemas.
- [ ] Preserve original document locations and access controls.
- [ ] Create or update BRMS navigation and operating guidance.

## Flows

- [ ] Build Review Schedule Refresh using calendar-month rules and the configured time zone.
- [ ] Build Review Reminders in preview with duplicate-send controls and refresh sequencing.
- [ ] Build Source Document Monitor using independently mapped sources.
- [ ] Verify SourceModifiedDate never changes LastReviewedDate.
- [ ] Record the flow convention, actual names/IDs, connection references, trigger bindings, field ownership, and operational settings.
- [ ] Export reusable definitions and record any disabled or blocked components accurately.

## Acceptance and handoff

- [ ] Verify Current, Due Soon, Overdue, day 0/30/31, monthly/quarterly/semiannual/annual, leap-year/month-end, invalid, and inactive cases.
- [ ] Verify repeated runs, concurrent attempts, partial failures, and reminder preview produce no duplicate intended sends.
- [ ] Verify source edits preserve the governance review date.
- [ ] Test a real governed document on a second accessible site and prove correct mapping and permissions.
- [ ] Rebind one supporting test resource to a different location through configuration, refresh affected bindings, and rerun successfully.
- [ ] Verify links and permissions as an intended reader, not only as the flow connection owner.
- [ ] Document recovery for inaccessible sources and ambiguous notification outcomes.
- [ ] Confirm test runs cannot update the original deployment or PROD through inherited bindings.
- [ ] Record run evidence, resource/flow inventories, deployment steps, and rollback steps.
- [ ] Keep real-recipient communications and production cutover pending explicit rollout authorization.
- [ ] Report exact remaining dependencies; distinguish documented, created, tested, and enabled states.

## Loop project reporting

- [ ] Use the existing implementation page as one project overview/status page with owner, last update, current phase, milestones, next actions, and top blockers.
- [ ] Reuse or create linked detail pages only where useful for build progress, decisions/blockers, resource/flow inventory, and testing/handoff.
- [ ] Record confirmed decisions separately from proposals, with decision maker, rationale, date, and affected work.
- [ ] Track each blocker with impact, next action, resolution owner, state, and closure evidence; do not delete resolved history.
- [ ] Record actual site/list/library URLs and IDs and exact flow names, IDs, management URLs, environments, operating states, and last verification.
- [ ] Update relevant entries after each milestone, test, decision, blocker change, or resource change, then refresh the overview.
- [ ] Verify Loop saves before claiming the page is updated; record a pending update if access or saving fails.
- [ ] Include updated Loop page links and remaining actions in the session handoff.
