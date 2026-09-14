# BRMS flow package handoff

## Target environment

The selected Power Platform environment is administrative metadata only. BRMS artifacts must remain unsuffixed.

| Field | Value |
|---|---|
| Environment name | RIS-TechCentral-Low-DEV |
| Environment ID | `722e9526-2b55-e3b0-8bfb-e4475649af19` |
| Environment URL | `https://org734d2f31.crm.dynamics.com` |
| Solution unique name | `BRMSGovernanceControlTower` |
| Solution display name | `BRMS Governance Control Tower` |

## Preserved BRMS resources

| Resource | List ID | Site URL |
|---|---|---|
| Governance Control Tower | `249e7c48-b75e-4b14-9ff0-eb00a854111a` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |
| BRMS Configuration | `8a5524c7-01bd-4608-899f-62281313a8c6` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |
| BRMS Notification History | `ef96f9df-2e83-4040-9201-da4e8087918f` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |
| BRMS Automation Run History | `f0f62faf-86bb-4257-9c0d-f4f8571e71e2` | `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS` |

## Package generation

Generate the package outside the repository so the ZIP and connection-bound settings are not committed:

```powershell
.\scripts\New-BrmsFlowSolution.ps1 `
  -RegisterSiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
  -RegisterListId '249e7c48-b75e-4b14-9ff0-eb00a854111a' `
  -ConfigurationSiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
  -ConfigurationListId '8a5524c7-01bd-4608-899f-62281313a8c6' `
  -NotificationHistorySiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
  -NotificationHistoryListId 'ef96f9df-2e83-4040-9201-da4e8087918f' `
  -AutomationRunHistorySiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
  -AutomationRunHistoryListId 'f0f62faf-86bb-4257-9c0d-f4f8571e71e2' `
  -DefaultSourceSiteUrl 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS' `
  -DefaultSourceServerRelativeSitePath '/sites/ELSBUProjects/BRMS' `
  -OutputDirectory '<restricted-output-folder>'
```

Validated package from the current run:

| Field | Value |
|---|---|
| Package file | `BRMSGovernanceControlTower.zip` |
| Solution version | `1.0.0.2` |
| SHA-256 | `a4958c6f2feca6e87ed78b77cb9f532aa3496a7d2620f0f0af3ff95001fed475` |
| Validation | `tests/Test-BrmsFlowArtifacts.ps1` passed |

## Required connection-reference binding

Run `pac solution create-settings --solution-zip BRMSGovernanceControlTower.zip --settings-file settings.json`, then bind:

| Logical name | Connector ID | Required binding |
|---|---|---|
| `cr1e9_BRMSSharePoint` | `/providers/Microsoft.PowerApps/apis/shared_sharepointonline` | Existing connected SharePoint connection with access to the BRMS site and any configured source sites |

## Import status

The completed package was retried with `pac solution import --async --max-async-wait-time 10` in environment `722e9526-2b55-e3b0-8bfb-e4475649af19`.

| Field | Value |
|---|---|
| Async operation ID | `93058e94-8cb0-f111-aaac-70a8a5af0770` |
| Result | Failed before creating BRMS flows |
| Error | `An error occurred while trying to run solution checker enforcement on the importing solution. Try importing the solution again. If this problem persists, contact your system administrator.` |
| Observed duration | Approximately 6 minutes 45 seconds |
| Post-check | `pac power-automate list-cloud-flows` found zero `BRMS - GCT - ...` flows |

## Maker/admin action required

Resolve the environment's solution-checker enforcement failure or import the package through the Power Automate maker portal in the selected environment with the `BRMS SharePoint` connection reference bound to the SharePoint connector connection.

After import:

1. Confirm the three flows exist with these exact names: `BRMS - GCT - Review Schedule Refresh`, `BRMS - GCT - Review Reminders`, and `BRMS - GCT - Source Document Monitor`.
2. Keep reminders in preview; do not add an outbound email or Teams send action until rollout is approved.
3. Test Review Schedule Refresh first against the synthetic records in `Governance Control Tower`.
4. Verify actual updates to `NextReviewDue`, `DaysToReview`, and `Status`, then run reminder preview and source monitoring.
5. Record flow IDs, management URLs, run IDs, run results, list changes, notification preview rows, source observations, and Automation Run History rows in the Loop workspace.
