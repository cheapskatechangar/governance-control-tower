\# Governance Control Tower Deployment Checklist



\## Phase 1 — Repository Readiness



\- \[ ] README created

\- \[ ] Environment config files created

\- \[ ] Setup guide created

\- \[ ] Field schema documented

\- \[ ] Power Automate flow inventory documented

\- \[ ] Deployment checklist created



\## Phase 2 — SharePoint Setup



- [x] Record target SharePoint site: `https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS`

- [ ] Verify access to the BRMS site and inspect existing lists/libraries before creating resources

\- \[ ] Create DEV list

\- \[ ] Create PROD list

\- \[ ] Add core fields

\- \[ ] Add ownership fields

\- \[ ] Add RTO fields

\- \[ ] Add Immutable Backup fields

\- \[ ] Add Recovery Playbook fields

\- \[ ] Add Blue/Green fields

\- \[ ] Add Evidence fields

\- \[ ] Add Exception fields



\## Phase 3 — Libraries



\- \[ ] Create Evidence Vault library

\- \[ ] Create Recovery Playbooks library

\- \[ ] Confirm folder naming standards

\- \[ ] Confirm permissions



\## Phase 4 — Power Automate



\- \[ ] Export existing flows

- [ ] Obtain an existing BRMS flow export or documented BRMS patterns

- [ ] Document the BRMS flow naming, environment, solution, connections, configuration, logging, error handling, and notification conventions

- [ ] Map source flows and supporting lists/libraries to their BRMS targets

\- \[ ] Document triggers

\- \[ ] Document schedules

\- \[ ] Document required SharePoint connections

\- \[ ] Update site/list references

\- \[ ] Test DEV flows

\- \[ ] Disable test flows before PROD rollout



\## Phase 5 — Reporting



\- \[ ] Confirm Power BI data source

\- \[ ] Confirm credentials

\- \[ ] Validate refresh

\- \[ ] Validate dashboard filters

\- \[ ] Validate KPI calculations



\## Phase 6 — Go-Live



\- \[ ] Validate sample records

\- \[ ] Run DEV smoke test

\- \[ ] Confirm owner/manager notifications

\- \[ ] Confirm evidence links

\- \[ ] Confirm exception links

\- \[ ] Communicate rollout
