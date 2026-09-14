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
4. The original generated unmanaged solution package could be parsed by `pac solution create-settings` and produced the expected SharePoint connection reference. Import then failed before creating any flow with: "An error occurred while trying to run solution checker enforcement on the importing solution."
5. A separate `pac solution check` call uploaded the package to Power Apps Checker but stayed at "Analyzing; PercentComplete: 30" for more than seven minutes and had to be stopped. This indicates the active blocker is solution-checker/enforcement tooling for package import, not SharePoint list availability.
6. After the package generator was completed with the full BRMS flow action structure, retry/pagination metadata, independent resource-map parameters, preview-only reminder behavior, and source-monitoring actions, `pac solution import --async --max-async-wait-time 10` started async operation `93058e94-8cb0-f111-aaac-70a8a5af0770`. The operation failed after about 6 minutes 45 seconds with the same solution-checker enforcement message and created no BRMS flows.
7. The normal maker designer action picker was tested separately from Copilot. It opened and found the standard SharePoint connector with SharePoint triggers/actions, so the connector is available in the designer. Completing all three BRMS flows manually in the designer remains an interactive maker task unless solution import succeeds.

No active cloud flow currently references the recycled DEV-suffixed list IDs.

## Prepared flow names

- BRMS - GCT - Review Schedule Refresh
- BRMS - GCT - Review Reminders
- BRMS - GCT - Source Document Monitor

Outbound reminders must remain in preview until rollout is explicitly authorized.

## Prepared package generator

Use `scripts/New-BrmsFlowSolution.ps1` to generate an unmanaged solution package from live list IDs. Run `pac solution create-settings` against the ZIP, populate the SharePoint connection ID, then import in the target environment. If the same checker-enforcement failure occurs, import requires a maker/admin action to resolve the environment checker policy or run the import from the maker portal with the generated ZIP and selected SharePoint connection.

The generator now emits all three unsuffixed BRMS flows, not only scheduled read scaffolds. It includes:

- independent resource-map parameters for the register, configuration, notification history, automation run history, and default source site;
- daily recurrence triggers with single-run concurrency;
- SharePoint action retry policies and `$top=5000` page-size hints;
- Review Schedule Refresh logic for Monthly, Quarterly, Semi-Annual, and Annual review cycles;
- preview-only Review Reminders with deterministic `NotificationKey` duplicate suppression and no outbound send action;
- Source Document Monitor actions that read registered document links and update only `SourceModifiedDate`; and
- Automation Run History writes for each flow.

Local artifact validation is in `tests/Test-BrmsFlowArtifacts.ps1`.
