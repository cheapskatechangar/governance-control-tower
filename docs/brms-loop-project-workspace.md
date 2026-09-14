# BRMS Loop project workspace

## Purpose and destination

Maintain the existing **Governance Control Tower implementation** Loop page supplied by the user as the team's project overview and status page. The user has authorized updates to this page and creation of additional linked pages when useful.

Use the exact authenticated Loop link provided in the Scout task. This page is distinct from the BRMS SharePoint home site. Do not assume it lives beneath that site, derive a replacement URL, or create a new project workspace because the page is outside the home site's path. Store verified working page links in the existing restricted project workspace and handoff.

The page's current content has not been inspected during preparation of these instructions: it opened at an organizational sign-in screen. No live Loop page edits or additional page creation are claimed by this document. Scout must inspect the page before applying the proposed organization.

Loop holds the team's current implementation status, working resource links, decisions, blockers, and delivery evidence. GitHub holds reusable build artifacts and their version history. Link each status claim to the relevant artifact or observed run where available; a commit proves a repository change, not a tenant deployment or a passing flow run.

## Page organization

Keep a single overview/status page. Start with useful sections in the existing page and split detailed material only when its length or audience warrants it. Reuse an existing matching page before creating another. Do not create duplicate Project and Status pages that need the same information maintained twice.

| Page or section | Content | When to separate it |
|---|---|---|
| Governance Control Tower implementation | Purpose, current phase, concise status, owner, last updated, milestones, next actions, top blockers, and links to details | Always use the existing supplied page as the entry point |
| Build Progress | Milestone status and a dated delivery log with work completed, next steps, commits, and evidence | When the detailed history distracts from the overview |
| Decisions and Blockers | Two tables: decision history and active/resolved blockers | When the overview needs only the current decisions needed and top blockers |
| Resources and Power Automate | Verified site/list/library inventory, source-location mapping, and exact flow inventory | When the register becomes too large for the overview |
| Testing and Handoff | Test results, run evidence, rollout state, remaining actions, and operating/recovery instructions | When evidence and handoff details need their own working area |

Use these as proposed names, adapting to existing page names and organization. Give each new page a purpose and a link back to the overview. Add verified links to the overview immediately. Preserve contributors' existing content, decisions, comments, assignments, and history. Move relevant content carefully when splitting a section and retain clear navigation from its old location.

## Overview contents

Keep the overview readable without opening every detail page:

- **Project:** BRMS document governance, with a short statement of purpose and scope.
- **Current state:** current phase, work status, and a plain-language explanation of what works and what is still unverified.
- **Accountability:** actual project/build owners where known, next-action owners, and latest update timestamp with time zone. Do not assign someone merely because their name appears in a document.
- **Milestones:** discovery/configuration, SharePoint setup, flows, testing, and handoff. Include the current state and next action for each.
- **Recent progress:** a short dated summary of meaningful changes, with evidence links.
- **Next actions and decisions needed:** specific actions, owner or Unassigned, and agreed target date if one exists.
- **Top blockers:** the currently material blockers, linked to their full entries.
- **Navigation:** verified links to the repo/build brief, BRMS home site, register, relevant Loop pages, and resource/flow inventory.

Do not invent percentage completion, dates, commitments, owners, production readiness, or a green project rating. If part of the system works while another part is blocked, state both precisely. Distinguish Not started, In progress, Blocked, and Complete for work items. Track Created, Configured, Tested, and Enabled independently for deployed components.

## Detailed registers

### Build progress and delivery log

For each milestone or meaningful work item, record a stable reference, date/time with time zone, component, actual change/result, work state, owner where known, next action, repository branch/commit or artifact link, and live verification evidence where applicable.

Maintain one current milestone entry and a concise dated history. Update existing work rather than creating duplicate rows for each agent message. Log meaningful outcomes rather than every click, tool attempt, or copied console output.

### Decisions

Record a decision ID, date, question, decision, rationale, person or source confirming it, status, affected components, and supporting link. Use Proposed, Confirmed, or Superseded. Keep superseded decisions and link them to the replacement. A suggestion from Scout is not a confirmed business decision.

The following are confirmed by the user's directions or the supplied baseline and can seed the log after checking existing entries:

| Confirmed direction | Basis |
|---|---|
| Build a BRMS deployment for another part of the organization | User instruction in the project conversation |
| Use the supplied BRMS SharePoint URL as the home/default site, with independently configurable locations | User instructions on the site and distributed resources |
| Follow BRMS Power Automate patterns | User instruction; exact conventions still require live discovery |
| Use the 14-field document-governance baseline | Supplied setup guide; source scope reconciled in the active repository docs |
| Maintain the supplied Loop page throughout delivery and create linked detail pages when useful | User instruction on project reporting |

Record the provisional flow naming pattern, exact reminder cadence, actual environment, and any undiscovered owner as unresolved/proposed until verified. Do not invent a decision date if it cannot be recovered; record the date the direction was entered and identify the source instead.

### Blockers

Each blocker needs an ID, date raised, affected component, exact symptom/dependency, delivery impact, resolution owner or Unassigned, next action, agreed target date if available, Open/In progress/Resolved state, last update, and closure evidence.

Keep resolved entries. Mark them resolved only after the dependency has actually been cleared and, where relevant, verified. Track a Loop access/save failure as its own reporting blocker, without marking independent build work blocked. Missing reminder settings should identify the affected reminder activation step, not imply the whole project cannot proceed.

### Resources and source locations

Record the logical role/source key, resource type, display name, actual site URL, resource URL, list/library ID, environment, relevant folder scope, owner/support contact where known, connection binding label, access/verification result, and last-verified timestamp. Include independently hosted source libraries as well as central resources.

Use real URLs and IDs obtained from the product. Do not infer a GUID from a name, invent a management URL, or turn a folder URL into a claimed site URL. Where access prevents verification, preserve the supplied value with an explicit Unverified status. Do not store tokens, secrets, or connection credentials.

### Power Automate inventory

Record each flow as soon as it exists and update the same entry when it changes:

| Field | Required content |
|---|---|
| Function | Review Schedule Refresh, Review Reminders, Source Document Monitor, or a justified supporting function |
| Exact flow name | Actual display name in Power Automate, including environment suffix where used |
| Flow ID and management URL | Verified ID and direct working link from Power Automate |
| Environment and solution | Actual environment name/ID and solution name when applicable |
| Trigger and schedule | Trigger type, configured source where applicable, recurrence, and time zone |
| Inputs and outputs | Logical resources read/written and their verified inventory links |
| Ownership and connections | Actual owner/support identity where verified and connection/reference labels without credentials |
| Operating state | On/Off or product-reported state, plus Preview/Test/Live processing mode when implemented |
| Verification | Latest relevant run date/result, evidence link, outstanding issue, and last observed timestamp |
| Build traceability | Repository artifact and branch/commit associated with the flow version |

Do not equate a saved flow with a tested or enabled flow. Record a deployment separately from a specification. Keep renamed/replaced flows traceable through their IDs; mark retired entries and reference their replacements rather than deleting them.

### Testing and handoff

Record test ID, scenario, environment, input/test-item reference, expected result, actual result, Passed/Failed/Blocked/Not run, run/evidence link, date, and any related issue. Include the cross-site document and resource-relocation tests, date boundaries, reminder deduplication, source-edit/review-date separation, and environment isolation from the build brief.

Keep final handoff steps, operations/recovery instructions, notification activation state, remaining authorizations, and unresolved dependencies visible. Put sensitive run details in an appropriate restricted location and link them without copying credentials or unnecessary personal/document data into Loop.

## Update cadence and verification

1. At the start of a work session, read the overview and relevant detail pages. Reconcile their last-known state with actual repository and tenant evidence before changing statuses.
2. Establish any missing structure and record the current known baseline. Inspect the existing page before adding rows or creating pages.
3. After each meaningful milestone, test outcome, confirmed decision, blocker change, or resource/flow creation or change, update its detailed entry and refresh the overview. Record URLs and IDs when obtained, not only at final handoff.
4. Before handing control back, refresh the last-updated timestamp, current phase, next actions, and top blockers. State what was built versus tested versus enabled.
5. Verify the save using the available product confirmation and a targeted reread. Report which pages were actually updated and provide their direct links. Creating an offline draft or editing repository instructions does not count as a saved Loop update.

The user has authorized routine progress edits and useful linked pages. Do not request permission for each status row or page. Do not send separate email/Teams notifications, tag people, or change sharing/permissions merely to maintain the workspace.

If access or saving fails, preserve the exact intended update as pending in the current handoff or a suitable restricted artifact. Record the affected page, action, failure, and retry dependency. Continue independent implementation work. Once access is restored, reread the page, merge the pending update with current contributions, verify saving, and mark the reporting blocker resolved. Never claim that Loop is current when a required update remains unsaved.

For each milestone handoff, include a short factual statement identifying the result, evidence, next action, and Loop update state. The project is ready for handoff only when its relevant Loop entries are current or any unsaved entries are explicitly listed as reporting blockers.
