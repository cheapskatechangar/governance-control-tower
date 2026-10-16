# BRMS branding checkpoint

2026-10-16. Requested hierarchy: Business Resilience is the primary identity of the BRMS space; Elsevier is the smaller company mark. Preserve the supplied artwork, aspect ratios and orange colors. Use a white logo strip above navy content; do not merge, crop or redraw either mark.

## Verified work and blocker

Both original PNG files were uploaded through the browser to BRMS Site Assets. The library confirmed "Uploaded 2 items to Site Assets" and listed both files. Page image uploads remained at Uploading; a subsequent rich-text attempt reported an unsupported image. A form preview produced both image elements but zero natural image width. Opening the primary asset returned SharePoint AccessDenied with: "Due to organizational policies, you can't download this resource from this untrusted device."

This is a device-policy restriction, not proof that the PNG artwork is invalid. No bypass was attempted. Broken page placeholders were removed and the experimental form preview was cancelled. Logo display is NOT verified or published. The original working form JSON remains the active configuration. No cloud-flow update or email send occurred; solution stays 1.0.0.11.

## Ready for application from an approved device

- Site header: original Business Resilience logo, on white. Verify persistence after saving.
- Homepage: dominant BR logo about 320 px wide; Elsevier about 72 px wide in the same white brand area. Preserve existing actions, documents and handover information.
- Form: `config/brms-document-form-header.branded.pending.json` is an unapplied candidate. Preserve the current body, footer and all 14 fields. Verify both logos render before saving.
- Email: `docs/email-previews/reminder-branded.pending.html` and `escalation-branded.pending.html` are design candidates only, not installed flow templates. Both preserve a text-based system identity if images are blocked.

Authenticated SharePoint image URLs must not be assumed to work in Outlook. Microsoft cloud-flow guidance recommends an anonymously accessible image source and calls out a 100 KB inline-image limit: https://learn.microsoft.com/en-us/power-automate/email-customization . Supplied originals exceed that size. Do not create anonymous links or change access policy as a workaround. Obtain approved email-hosted brand assets or validate an approved inline-image delivery method, then send a controlled synthetic test to the existing approved tester and inspect Outlook desktop/web/mobile. Keep production delivery off until accepted.

## Original assets

- `BR Logo.png`: SHA-256 `3ba3ba5eedf2e4d00dd24ea99d96ed758cb0fa2602a36e6ca0410ed81b134b1b`
- `Elsevier_Stacked Logo_VitalOrange_RGB.png`: SHA-256 `c81559e00570008acdbaaf61989832deb44a72944d222c1fe0863c5b07eba811`

## Follow-up: form applied for user visual review

The project owner authorized the next step after the device-policy limitation was explained. The dual-logo form header is now saved and its two Site Assets image references persisted after reloading NewForm.aspx. The white logo strip sits above the existing navy title, with BR primary and Elsevier secondary. The body, footer and fields were preserved; no record was created. Image rendering remains unverified in the remote browser (zero natural image width). User visual review on the work device is required. `config/brms-document-form-header.json` now reflects this applied configuration; the historical pending candidate is retained. Homepage and email branding remain pending. No production notification or flow changes were made.
