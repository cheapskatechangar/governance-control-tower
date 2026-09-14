\# Governance Control Tower Setup Guide



\## Purpose



This repo documents and supports the repeatable setup of Governance Control Tower across SharePoint environments.

## BRMS deployment target

The target SharePoint site is [BRMS](https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS).

Both environment configuration files point to this site. The current list targets are:

| Configuration | List name |
|---|---|
| `config/dev.json` | Governance Control Tower - DEV |
| `config/prod.json` | Governance Control Tower |

These are configured targets; site access and the existence of the lists still need to be verified.

Power Automate flows must follow BRMS patterns. The exact conventions are not yet documented in this repository. Use an existing BRMS flow export or the team's pattern documentation to establish them before building or importing flows. See [BRMS flow requirements](power-automate-flows.md#brms-flow-requirements).



\## Current Deployment Mode



Because Entra ID app registration may require corporate admin approval, this kit supports a semi-automated deployment approach.



\## Deployment Approach



1\. Create or identify the target SharePoint site

2\. Create the Governance Control Tower list

3\. Add required columns from the field schema

4\. Configure Power Automate flows

5\. Configure evidence/document libraries

6\. Validate dashboard/reporting connections

7\. Perform test deployment before production rollout



\## Environments



\- DEV: Governance Control Tower - DEV

\- PROD: Governance Control Tower



\## Notes



PnP PowerShell automation may be added later if an approved Client ID is provided.
