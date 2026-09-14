# BRMS: clean up the DEV lists and resume one production build

## Direction that supersedes the earlier package

The user stopped creation after Scout began creating SharePoint lists with DEV labels. **This system has one production deployment. Do not use DEV or PROD environment labels in any new SharePoint site, list, library, page, solution, or Power Automate flow name.** Do not create a parallel development/test deployment. Continue using independently configurable resource locations.

The user has explicitly requested deletion of the new DEV SharePoint lists created by the interrupted BRMS build. This authorizes the scoped, recoverable list cleanup below. It does not authorize deleting SharePoint sites, unrelated lists, existing document libraries, source documents, or the original organization's system. Do not use a tenant-wide wildcard delete.

Read this document before the main build brief or any instructions from the earlier ZIP. The previous dev/prod configuration files, environment suffix pattern, and requirement for separate deployment resources are superseded. A preview setting for notifications controls sending during validation; it must not create another deployment or change resource names.

## 1. Stop affected automation and establish the exact cleanup list

1. Keep the interrupted creation stopped while inspecting its outputs. Identify flows and provisioning jobs created or changed by this BRMS run that reference the unwanted lists. Record their current states and stop only those affected processes before changing their targets. Do not stop unrelated business flows.
2. Inspect the BRMS site and any other explicitly mapped locations used by this interrupted run. Identify every newly created SharePoint list carrying a DEV label. Verify its actual site, name, list ID, URL, creation time/creator where available, item count, and relationship to this build using Scout's creation log, local records, Loop, and live metadata. A name match alone is insufficient evidence.
3. Record a per-list cleanup manifest in the restricted project workspace: exact identity, creation evidence, item count, dependencies, data classification for cleanup purposes (empty, synthetic test data, or real business data), preservation action, deletion result, and recovery information. Expected names from the earlier package include `Governance Control Tower - DEV`, `BRMS Configuration - DEV`, `BRMS Notification History - DEV`, and `BRMS Automation Run History - DEV`; these are candidates to inspect, not a verified live inventory or the limit of the user's scope.
4. Inspect actual dependencies, including flow triggers/actions, configuration/bootstrap entries, connection-bound resource selections, lookups, form/view links, landing-page navigation, reporting sources, local scripts, and the Loop inventory. Record exact unwanted list IDs so ID-based references can be found after cleanup.
5. Execute verified candidates without requesting the same deletion permission again. If a list's origin is ambiguous or its real data cannot yet be preserved, hold only that list, record the exact blocker, and continue with the other verified candidates and independent build work.

## 2. Preserve real information, then recycle the unwanted lists

- Empty lists and confirmed synthetic test-only lists from this build can be removed through the product's recoverable list deletion/recycle action.
- If a candidate contains real data, preserve the list schema/settings and the data in a restricted location outside every deletion target. If moving the data to the correct unsuffixed list is appropriate, verify the migration before deleting the old list. Preserve required fields, person values, original document links, useful metadata/history, and the old-to-new item mapping; do not assume item IDs remain the same.
- Do not treat a CSV alone as a complete backup when attachments, history, permissions, or dependencies matter. Verify the chosen recovery/migration method and the preserved items. If the available method cannot preserve what matters, leave that candidate in place as a specific blocker.
- Recycle the verified unwanted lists using their exact recorded identities. Confirm that each is removed from active site contents and record the result and available restoration details. If only permanent deletion is available, stop that candidate and report the limitation. Do not purge or empty recycle bins.
- Renaming a DEV list, hiding it, or removing its navigation link does not fulfill the user's request to delete that new list. Do not use those actions as substitutes for cleanup.
- Preserve correctly named compatible lists and all pre-existing business content. No SharePoint site deletion is part of this task. If a site or library unexpectedly received a DEV name, record it as a separate finding; do not expand this list-deletion scope automatically.

## 3. Establish the correct resources and flow names

Reuse the correctly named resources already created by the team. Create only those missing after discovery. The default unsuffixed names are:

| Resource | Name |
|---|---|
| Document register | Governance Control Tower |
| Configuration | BRMS Configuration |
| Notification history | BRMS Notification History |
| Automation run history | BRMS Automation Run History |
| Review-date flow | BRMS - GCT - Review Schedule Refresh |
| Reminder flow | BRMS - GCT - Review Reminders |
| Source-monitoring flow | BRMS - GCT - Source Document Monitor |

Follow an existing BRMS convention if it uses different appropriate names, while enforcing the user's no-DEV/no-PROD-label rule. Retain compatible existing unsuffixed names instead of creating duplicates. Do not append PROD when removing DEV.

Keep the BRMS home site at the user-supplied address. The register, supporting resources, and document sources can still be on different configured sites. Record the existing Power Platform environment name/ID for administration; do not rename that environment or create another one just to match this instruction.

Retain useful BRMS flows created during the interrupted build. Rename their display names in place where supported, preserving their IDs and history, and rebind every trigger/action/configuration reference to the verified correct list IDs. Keep them stopped until references are checked. Do not delete a useful flow just because its display name contains DEV or PROD; the user's deletion request is for the new DEV lists.

## 4. Correct local instructions, configuration, and repository changes

Preserve existing local implementation work and creation logs before applying this update. If using a Git clone, inspect its branch/status and integrate this correction without discarding uncommitted work. If using the earlier ZIP, do not simply overlay files and leave obsolete configuration active.

- Remove `config/dev.json` and `config/prod.json` from the active working source. Use the single `config/brms.json` bootstrap configuration.
- Use version 2 of `config/brms-deployment.example.json`, which contains one `deployment` mapping. Implement its independently resolved resource bindings; do not recreate an `environments.dev` branch.
- Remove suffix-generation rules and default DEV routing from any local provisioning/flow-generation code Scout added. Update deployed configuration entries as well as repository templates.
- Read the revised main build brief, setup guide, flow specifications, checklist, and Loop requirements. Legacy historical documents and the earlier snapshot are not active instructions.
- Keep the exact Loop project link and restricted local data out of public commits. Continue recording useful sanitized build artifacts in the repo and live deployment evidence in the restricted project workspace.

This correction package itself does not delete any live list or alter a deployed flow. Scout must perform and verify the live cleanup through its authenticated access.

## 5. Resume building and validate the single production system

Continue the full work in `docs/brms-scout-build-instructions.md`: the 14-field register, exact choices, form, five views, supporting resources, navigation, and the three flows. Preserve source documents in their current locations and maintain separate source-modified and governance-review dates.

Use identifiable synthetic records/files in the existing single deployment for validation. Record their IDs and restrict test mutations to them. Do not create DEV/PROD/test infrastructure, delete real records to make a test easier, or relocate working production resources merely to prove portability. Check configurable alternatives through read-only resolution of existing accessible resources; verify source monitoring using an actual authorized document on another mapped site when available.

Keep outbound reminders in preview while validating. The production-only naming direction does not by itself authorize sending messages to all owners. Continue the previously established requirement to enable real-recipient communications only when the concrete rollout has been authorized.

Before restarting any affected flow, verify that it resolves the correct live list/library IDs and that no active trigger, action, configuration entry, report, or navigation link still depends on a deleted list. Then run the relevant validation and record the actual result. Historical cleanup logs may retain old IDs for traceability.

## 6. Keep Loop current and report the actual outcome

Update the existing implementation Loop page and linked detail pages throughout cleanup and resumed construction:

- Mark the prior two-profile design Superseded and record the single-production, unsuffixed naming decision as Confirmed.
- Record each list inspected and whether it was recycled, preserved because unrelated, or held for a specific blocker. Include exact names/IDs/URLs, item counts, preservation evidence, deletion result, and restoration information where available.
- Update the resource and flow inventories with the correct current names, IDs, URLs, dependency mappings, and operating states. Preserve historical entries with their retired/deleted state and replacement links.
- Record tests, unresolved dependencies, next actions, and repository commits. Verify saves before claiming Loop is current.

The handoff must report what was actually deleted, what remains and why, which unsuffixed resources were reused/created, which flows were renamed/rebound, validation results, and the exact next actions. Do not claim cleanup from a rename or from merely editing these instructions. Continue unblocked work rather than stopping the entire build for a single unresolved candidate.
