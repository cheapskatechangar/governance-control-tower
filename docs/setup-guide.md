# BRMS document governance setup

Use [the Scout build brief](brms-scout-build-instructions.md) for the full implementation. The supplied SharePoint guide remains the baseline for the register; [field-schema.md](field-schema.md) transcribes its schema and review rules.

## Locations and discovery

The home site is https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS. Treat it as the navigation hub and initial default, not a required parent of all resources.

Inspect the home site and existing BRMS lists, libraries, pages, and accessible flows before creating anything. Identify the actual register the team created from the guide. Reuse it if compatible, report populated schema mismatches, and preserve existing content and permissions.

Configure the register, configuration list, notification history, automation run history, and each monitored source library independently. Each resolved mapping must include environment, logical role, site URL, actual list/library ID, display name, relevant folder scope, and connection binding. Source libraries may be on different sites. A connection provides access; it does not specify a resource's address.

The example under `config/` is a planning template, not an implemented configuration loader. Scout must implement and test the mappings, including separate settings for DEV and PROD. Unknown or inaccessible configured locations must be reported explicitly; do not silently substitute the home site.

## Register

Candidate names from the original configuration are `Governance Control Tower - DEV` and `Governance Control Tower`. Resolve existing live names before creating resources. Apply the 14-field document schema. Disable attachments and enable version history using the site's normal retention setting. Original documents remain linked through DocumentLink.

Apply [the supplied four-section form layout](../config/brms-document-form.json), verifying its display labels against the live list. Source Modified Date and Active are omitted from this baseline form. Provide an appropriate list view or authorized editing path for operators to manage Active.

| View | Filter | Sort |
|---|---|---|
| All Active Documents | Active = Yes | Next Review Due ascending; default view |
| My Documents | Owner = [Me] AND Active = Yes | Days to Review ascending |
| Overdue | Status = Overdue AND Active = Yes | Days to Review ascending |
| Due in 30 Days | Status = Due Soon AND Active = Yes | Next Review Due ascending |
| Inactive - Archived | Active = No | Document Name ascending |

Main-view columns: Document Name, Document Type, Department, Owner, Last Reviewed Date, Next Review Due, Days to Review, Status.

## Supporting resources and home page

Create or reuse separately configured BRMS Configuration, Notification History, and Automation Run History lists. Define their operational schemas before wiring flows; the build brief specifies the minimum data needed.

Reuse existing controlled-document libraries where appropriate. Do not create a duplicate central repository or move documents merely to make monitoring simpler. An additional document library is optional, only where the BRMS team needs a new storage location.

Create or update a BRMS home page with links to the register, the five views, configured document locations, and simple operating guidance. Preserve existing page content. Use active-document counts by status with visible last-refresh information when the available tooling supports them. Validate standard SharePoint views first; Power BI is an optional continuation of existing reporting, not a prerequisite for a working register.

## Verification

Create isolated BRMS test records for Current, Due Soon, and Overdue; leave derived values for the refresher to calculate. Verify required fields, person selection, original-document links, form sections, My Documents, and Active filtering.

Run the broader acceptance cases in the Scout brief, including a real document in a second accessible site. A home-page URL can test hyperlink entry, but it cannot prove source-document monitoring. Keep notifications in preview unless test recipients have been explicitly authorized.
