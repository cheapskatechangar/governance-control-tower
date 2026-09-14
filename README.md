# Governance Control Tower for BRMS

This repository is the build and handoff kit for the **Business Resilience Management System (BRMS) document governance system**.

BRMS home site: https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS

The home site is the navigation hub and default resource location. Each register, supporting list, source library, and document may be hosted elsewhere. Flows must use explicit resource mappings and must not assume that every document lives beneath the home site.

## Start here

Give Scout [the complete BRMS build instructions](docs/brms-scout-build-instructions.md). They cover discovery, SharePoint creation, configuration, flow construction, verification, repository updates, and handoff.

| File | Purpose |
|---|---|
| [Field schema](docs/field-schema.md) | The 14 document-governance fields, choices, and review rules |
| [Setup guide](docs/setup-guide.md) | List, form, views, and distributed resource setup |
| [Flow specifications](docs/power-automate-flows.md) | BRMS review refresher, reminders, and source monitoring |
| [Deployment checklist](docs/deployment-checklist.md) | Build and acceptance criteria |
| [Deployment example](config/brms-deployment.example.json) | Planning template for independently located resources |
| [Form layout](config/brms-document-form.json) | Four-section list form from the supplied guide |

## Source and scope

The baseline is `Governance_Control_Tower_SharePoint_List_Setup_Guidev2.docx`, supplied for the team to create the new system. Its document body identifies itself as Version 1.0, prepared August 28, 2026. It defines document ownership, review dates, reminders, source modification tracking, and reporting.

That guide explicitly excludes the RTO, immutable backup, recovery testing, and blue/green fields present in the older repository. The old material is preserved under [legacy Technical Resilience documentation](docs/legacy/technical-resilience/README.md) for history. It is not the BRMS build specification. A Playbook can still be a governed document type.

Retain the guide's baseline schema when inspecting the list the team may already have created. Reuse compatible resources. Do not rename or recreate populated resources simply to match a proposed BRMS naming pattern.

## Configuration and implementation status

`config/dev.json` and `config/prod.json` currently identify the BRMS site and the original candidate register names. These are bootstrap inputs for the existing minimal list-creation script, not a complete deployment model. They do not declare that all resources must share one site.

`config/brms-deployment.example.json` is a design template for Scout to implement and resolve against live resources. It is deliberately marked as not runtime-ready; null resource IDs and empty source mappings are unresolved configuration, not deployable bindings. The current scripts do not consume it.

The current scripts install prerequisites and attempt to create a single list. They do not implement the document schema, views, form, supporting lists, or flows. The connection helper can skip authentication while the deployment wrapper continues. Scout must validate connectivity and correct that behavior before using those scripts for deployment.

No live BRMS build, resource inspection, or flow test is established by these repository files. Scout must record actual resource IDs, flow IDs, run evidence, and remaining blockers in the deployment handoff.

## Deployment conventions

Use the team's existing BRMS flow conventions when available. If discovery finds none, use the provisional pattern `BRMS - GCT - <Function> - <DEV|PROD>` for new flows and record that assumption. Keep production communications disabled during construction and verification until an intended-recipient rollout has been authorized.

Do not commit credentials, employee details, document contents, or populated organizational exports to this public repository. Keep build templates and sanitized evidence here; keep operational configuration and detailed run evidence in the access-controlled BRMS deployment location.
