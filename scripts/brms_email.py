"""Outlook-friendly BRMS test email templates, shared by flow and local previews."""
from html import escape


TEMPLATE = '''<!doctype html>
<html lang="en" dir="ltr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>[[subject]]</title></head>
<body style="margin:0;background:#f0f3f6;color:#142b40;font-family:Arial,Helvetica,sans-serif">
<div lang="en" dir="ltr" style="padding:28px 12px">
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%"><tr><td align="center">
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="width:100%;max-width:600px;background:#ffffff;border:1px solid #d8e0e7">
<tr><td style="padding:25px 32px;background:#142b40;color:#ffffff;border-top:5px solid #eb8d23"><p style="margin:0;font-size:13px;font-weight:bold;letter-spacing:2px">BRMS</p><p style="margin:7px 0 0;font-size:15px">Business Resilience Management System</p></td></tr>
<tr><td style="padding:14px 32px;background:#fff3d6;color:#533600;font-size:14px"><strong>TEST EMAIL</strong> &nbsp; Synthetic record. No business action required.</td></tr>
<tr><td style="padding:30px 32px 12px"><p style="margin:0 0 12px;font-size:13px;font-weight:bold;color:#765000">[[badge]]</p><h1 style="margin:0 0 16px;font-size:28px;line-height:1.2;color:#142b40">[[heading]]</h1><p style="margin:0;font-size:16px;line-height:1.6">[[intro]]</p></td></tr>
<tr><td style="padding:14px 32px"><table cellspacing="0" cellpadding="0" border="0" width="100%" style="font-size:15px;border-top:1px solid #d8e0e7">
<tr><th scope="row" align="left" style="padding:14px 12px 14px 0;vertical-align:top;width:110px;font-weight:normal;color:#465d70;border-bottom:1px solid #d8e0e7">Document</th><td style="padding:14px 0;font-weight:bold;border-bottom:1px solid #d8e0e7">[[document]]</td></tr>
<tr><th scope="row" align="left" style="padding:14px 12px 14px 0;font-weight:normal;color:#465d70;border-bottom:1px solid #d8e0e7">Review due</th><td style="padding:14px 0;border-bottom:1px solid #d8e0e7">[[due]]</td></tr>
<tr><th scope="row" align="left" style="padding:14px 12px 14px 0;font-weight:normal;color:#465d70;border-bottom:1px solid #d8e0e7">Status</th><td style="padding:14px 0;font-weight:bold;border-bottom:1px solid #d8e0e7">[[status]]</td></tr></table></td></tr>
<tr><td style="padding:12px 32px 30px"><h2 style="margin:0 0 10px;font-size:18px">What to do next</h2><p style="margin:0 0 22px;font-size:16px;line-height:1.6">[[action]]</p>
<table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr><td bgcolor="#142b40" style="border-radius:4px"><a href="[[record_url]]" style="display:inline-block;padding:14px 20px;color:#ffffff;font-size:15px;font-weight:bold;text-decoration:none">Open governance record</a></td></tr></table>
<p style="margin:20px 0 0;font-size:13px;line-height:1.6;color:#465d70">[[note]]</p></td></tr>
<tr><td style="padding:20px 32px;background:#f6f8fa;border-top:1px solid #d8e0e7;font-size:12px;line-height:1.6;color:#465d70">BRMS Governance Control Tower<br>Review dates use Eastern Time. Opening this email does not complete a review.<br>Test reference: [[reference]]</td></tr>
</table></td></tr></table></div></body></html>'''


def sample_values(overdue=False):
    return {
        'subject': '[BRMS TEST] Overdue review: Business continuity plan' if overdue else '[BRMS TEST] Review reminder: Business continuity plan',
        'badge': 'OVERDUE / ESCALATION PREVIEW' if overdue else 'REVIEW REMINDER',
        'heading': 'Review overdue' if overdue else 'Your review is coming up',
        'intro': 'This document has passed its review date and needs attention.' if overdue else 'A scheduled review is approaching. Please check the document and confirm that it remains current.',
        'document': 'Business continuity plan (synthetic example)',
        'due': 'October 9, 2026' if overdue else 'November 15, 2026',
        'status': '7 days overdue' if overdue else 'Due in 30 days',
        'action': 'Complete the review, or agree a completion date with the responsible owner. Update the governance record when the review is complete.' if overdue else 'Review the document, make any necessary changes, and update the last reviewed date in the governance record when finished.',
        'record_url': 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS',
        'note': 'This tests the overdue email appearance. Manager escalation recipients and trigger are still to be confirmed.' if overdue else 'Reminder schedule: 30, 14 and 7 days before review, on the due date, then weekly while overdue.',
        'reference': 'LOCAL-PREVIEW-ONLY',
    }


def render(values):
    html = TEMPLATE
    for key, value in values.items():
        html = html.replace('[[' + key + ']]', escape(str(value), quote=True))
    return html
