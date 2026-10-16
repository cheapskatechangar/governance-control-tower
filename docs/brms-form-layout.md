# Governance document form layout

Applied through the SharePoint Configure layout UI on 2026-10-16 and verified after reloading the actual NewForm page for Governance Control Tower (`249e7c48-b75e-4b14-9ff0-eb00a854111a`). No list item was created by the formatting operation.

The form has a navy BRMS header, orange accent, a clear title, required-field guidance, and four sections:

1. Document details: name, type, link and department.
2. Ownership and accountability: owner, reviewer and active flag.
3. Review settings: last reviewed date, frequency and notes.
4. Automation results: next review due, days to review, status and source modified date.

The footer explains that updating Last Reviewed Date confirms an actual completed review; editing a source document does not complete its review. All 14 existing fields, types and required flags are preserved. System output fields are labelled as maintained by BRMS but remain editable; layout formatting is not a permissions boundary.

Saved source files:

- `config/brms-document-form-header.json`: Header
- `config/brms-document-form.json`: Body
- `config/brms-document-form-footer.json`: Footer

Apply each JSON to its corresponding Configure layout selector. SharePoint can retain its existing field order within a section. The live page was checked visually and through the rendered field labels.
