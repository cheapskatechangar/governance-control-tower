\# Governance Control Tower Power Automate Flow Inventory



\## Purpose



This document tracks all Power Automate flows required to support Governance Control Tower.

## BRMS flow requirements

- Target SharePoint site: `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS`.
- Build and adapt flows using BRMS patterns. Obtain an existing BRMS flow export or the team's pattern documentation to establish the exact conventions.
- Record the reference's flow naming, target Power Automate environment, solution organization if used, connection setup, configuration, logging, error handling, and notification conventions. Where the reference does not define a convention, record it as unresolved.
- Map every SharePoint action and trigger to its intended BRMS list or library. Dependencies listed below are source references; their BRMS names, locations, and availability must be verified.
- Record the BRMS flow name and its source flow when adapting each flow. Validate schedules, time zones, reminder recipients, and suppression rules for the BRMS deployment.

The inventory below describes source flows. Its `CT - ...` names are reference names, not confirmed BRMS deployment names. `Existing` and `In Progress` describe the source inventory and do not establish that any flow is deployed in BRMS.



\## Flow Inventory



| Flow Name | Purpose | Trigger | Schedule | Status | Notes |

|---|---|---|---|---|---|

| CT - Flow A (RTO) - Nightly Due-Date Refresher | Recalculate RTO due dates/status | Scheduled | Daily 6:00 AM | Existing | Updates Next RTO Due, Days to RTO, RTO Status |

| CT - Flow A (IMM) - Nightly Due-Date Refresher | Recalculate Immutable Backup due dates/status | Scheduled | Daily 6:10 AM | Existing | Updates Next IMM Due, Days to IMM, IMM Status |

| CT - Flow D (Playbooks) - Nightly Due-Date Refresher | Recalculate playbook freshness/status | Scheduled | Daily 6:30 AM | Existing | Updates Playbook Age Days and Playbook Status |

| CT - Flow B (RTO) - Proactive Reminders | Send RTO reminder notifications | Scheduled | Daily | Existing | 30/14/7/Overdue reminder logic |

| CT - Flow E (Playbooks) - Proactive Reminders | Send playbook reminder notifications | Scheduled | Daily | Existing | Missing/60/30/Overdue logic |

| CT - Flow F (BlueGreen) - Proactive Reminders | Send Blue/Green reminders | Scheduled | Daily | Existing | Should skip N/A records |

| CT - Flow G - Exception Link Sync | Sync approved exceptions to Control Tower | Scheduled | Daily | Existing | Links EDR exceptions to Control Tower records |

| CT - Evidence Upload Processor | Process uploaded evidence | Form/File trigger | On upload | Existing | Creates evidence folders and updates Control Tower |

| CT - RPO Status Refresher | Calculate RPO health | Scheduled | TBD | In Progress | Compares backup age to target RPO |



\## Flow Migration Notes



For each flow, document:



\- Trigger type

\- Source SharePoint site

\- Source list/library

\- Required connections

\- Owner account

\- Target fields updated

\- Reminder thresholds

\- Suppression rules

\- Error handling

\- Notification history logging



\## Known Dependencies



\- TR Annual Testing Register

\- TR Evidence Vault

\- TR Recovery Playbooks

\- TR Exception Decision Record

\- TR Notification History

\- Power BI dashboard connections
