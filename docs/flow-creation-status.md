# BRMS Power Automate creation status

## Current blocker evidence

The SharePoint resources exist and should be preserved:

- Governance Control Tower
- BRMS Configuration
- BRMS Notification History
- BRMS Automation Run History

Cloud flow creation is not blocked by missing SharePoint lists or missing maker portal access. The maker portal opened in the selected Power Platform environment and exposed Create from blank, Save draft, Publish, connected SharePoint connections, operation group metadata calls, and flow listing.

Observed blockers:

1. `pac power-automate` is inspection-only in the installed CLI version. Its help exposes `list-cloud-flows`, `list-flow-actions`, and `list-flow-runs`; it does not expose a create/update/publish command.
2. The repository had no valid solution ZIP or `.cdsproj`, so solution import was not initially a valid creation path.
3. Maker-designer Copilot created only a recurrence/control draft and returned a connector-generation issue: it did not recognize the SharePoint connector name even though tenant flow exports and `pac connection list` show `/providers/Microsoft.PowerApps/apis/shared_sharepointonline` as the standard connector.
4. A generated unmanaged solution package could be parsed by `pac solution create-settings` and produced the expected SharePoint connection reference. Import then failed before creating any flow with: "An error occurred while trying to run solution checker enforcement on the importing solution."
5. A separate `pac solution check` call uploaded the package to Power Apps Checker but stayed at "Analyzing; PercentComplete: 30" for more than seven minutes and had to be stopped. This indicates the active blocker is solution-checker/enforcement tooling for package import, not SharePoint list availability.

No active cloud flow currently references the recycled DEV-suffixed list IDs.

## Prepared flow names

- BRMS - GCT - Review Schedule Refresh
- BRMS - GCT - Review Reminders
- BRMS - GCT - Source Document Monitor

Outbound reminders must remain in preview until rollout is explicitly authorized.

## Prepared package generator

Use `scripts/New-BrmsFlowSolution.ps1` to generate an unmanaged solution package from live list IDs. Run `pac solution create-settings` against the ZIP, populate the SharePoint connection ID, then import in the target environment. If the same checker-enforcement failure occurs, import requires a maker/admin action to resolve the environment checker policy or run the import from the maker portal with the generated ZIP and selected SharePoint connection.
