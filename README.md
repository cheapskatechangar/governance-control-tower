# Governance Control Tower for BRMS

This repository is the build and handoff kit for the **Business Resilience Management System (BRMS) document governance system**.

BRMS home site: https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS

The home site is the navigation hub and default resource location. Each register, supporting list, source library, and document may be hosted elsewhere. Flows must use explicit resource mappings and must not assume that every document lives beneath the home site.

## Start here

Start with [the cleanup and resume instructions](docs/brms-production-cleanup-and-resume.md) for the interrupted build, then follow [the complete BRMS build instructions](docs/brms-scout-build-instructions.md). This is one production deployment with no DEV or PROD labels in resource names.

| File | Purpose |
|---|---|
| [Field schema](docs/field-schema.md) | The 14 document-governance fields, choices, and review rules |
| [Setup guide](docs/setup-guide.md) | List, form, views, and distributed resource setup |
| [Flow specifications](docs/power-automate-flows.md) | BRMS review refresher, reminders, and source monitoring |
| [Deployment checklist](docs/deployment-checklist.md) | Build and acceptance criteria |
| [Loop project workspace](docs/brms-loop-project-workspace.md) | Progress, decisions, blockers, live resource URLs, flow inventory, and update cadence |
| [Deployment example](config/brms-deployment.example.json) | Planning template for independently located resources |
| [Form layout](config/brms-document-form.json) | Four-section list form from the supplied guide |

## Source and scope

The baseline is `Governance_Control_Tower_SharePoint_List_Setup_Guidev2.docx`, supplied for the team to create the new system. Its document body identifies itself as Version 1.0, prepared August 28, 2026. It defines document ownership, review dates, reminders, source modification tracking, and reporting.

That guide explicitly excludes the RTO, immutable backup, recovery testing, and blue/green fields present in the older repository. The old material is preserved under [legacy Technical Resilience documentation](docs/legacy/technical-resilience/README.md) for history. It is not the BRMS build specification. A Playbook can still be a governed document type.

Retain the guide's baseline schema when inspecting the list the team may already have created. Reuse compatible resources. Do not rename or recreate populated resources simply to match a proposed BRMS naming pattern.

## Configuration and implementation status

`config/brms.json` is the single bootstrap configuration for the BRMS register. The obsolete dev/prod configuration files have been removed. The register and supporting resources have unsuffixed names; independently mapped locations remain supported.

`config/brms-deployment.example.json` is a design template for Scout to implement and resolve against live resources. It is deliberately marked as not runtime-ready; null resource IDs and empty source mappings are unresolved configuration, not deployable bindings. The current scripts do not consume it.

The scripts can bootstrap one register using `config/brms.json` and an existing approved PnP client ID. They do not implement the full schema, views, form, supporting lists, cleanup, or flows. Missing authentication now stops the bootstrap; its output does not claim the complete system was deployed. Scout can use other supported authenticated tooling for the full build.

No live BRMS build, resource inspection, or flow test is established by these repository files. Scout must record actual resource IDs, flow IDs, run evidence, and remaining blockers in the deployment handoff.

The user has designated the existing `Governance Control Tower implementation` Loop page as the team's project overview and status page. Scout must maintain it throughout the build and create linked detail pages only when useful. Use the exact page link supplied in the task; keep the authenticated workspace link in the restricted project handoff rather than this public repository. A milestone handoff must say whether its Loop update was saved or remains pending.

## Deployment conventions

Use the team's existing BRMS flow conventions when available. If discovery finds none, use the provisional pattern `BRMS - GCT - <Function>` for new flows and record that assumption. Keep production communications disabled during construction and verification until an intended-recipient rollout has been authorized.

Do not commit credentials, employee details, document contents, or populated organizational exports to this public repository. Keep build templates and sanitized evidence here; keep operational configuration and detailed run evidence in the access-controlled BRMS deployment location.
