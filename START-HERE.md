# Start here: resume BRMS with one production deployment

The user stopped the earlier build because it created DEV-suffixed SharePoint lists. **Use one production deployment with no DEV or PROD labels in resource names.** This direction supersedes the earlier two-profile package and naming rules.

## Read in this order

1. [Cleanup and resume instructions](docs/brms-production-cleanup-and-resume.md).
2. [Full build instructions](docs/brms-scout-build-instructions.md).
3. [Loop project reporting requirements](docs/brms-loop-project-workspace.md).
4. The schema, setup guide, flow specifications, and checklist linked from the build brief.

If `LOCAL-PROJECT-LINKS.md` is provided with the local package, read it for the exact user-supplied Loop destination. Keep that file and restricted operational data out of public commits. Otherwise use the destination already supplied in the project task.

## Execute the correction

Preserve local work and inspect the outputs of the interrupted run. Stop only affected BRMS automation, identify the exact new DEV lists from this build, preserve any real data, and recycle the verified unwanted lists. The user has authorized that scoped deletion. Do not delete sites, unrelated resources, source documents, or the original deployment. Do not substitute renaming or hiding for the requested list deletion.

Use `config/brms.json` and the single `deployment` mapping in version 2 of `config/brms-deployment.example.json`. Remove obsolete local dev/prod configuration files and suffix-generation code. Do not just overlay this package and leave old active instructions in place.

Reuse correctly named compatible resources, create only what is missing, and rebind retained flows to the correct list IDs. Continue the complete document-governance build and maintain the supplied Loop page as work progresses. Verify actual cleanup and test outcomes before claiming completion.

## Local folder and GitHub

A downloaded ZIP is a source snapshot, not a Git clone. Extract a replacement package to a separate folder so it cannot overwrite Scout's local work or leave obsolete files mixed into the new source. Point Scout at this START-HERE.md, then have it integrate the correction into the existing working branch while preserving useful implementation changes.

If no clone exists and Git is available, use a fresh clone in a separate empty folder for versioned work. Compare it with this package's recorded source commit, read any newer user corrections, and keep local-only files excluded before staging. If Git is unavailable, continue useful work locally and report synchronization as pending.

Do not run the included PowerShell wrapper as a complete deployment: it only bootstraps one list and requires an existing approved PnP client ID. The full build and the scoped live cleanup require the authenticated tooling and verification described in the instructions.
