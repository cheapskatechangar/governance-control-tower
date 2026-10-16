"""Cadence and email delivery actions. Test delivery only, never production mail."""
from brms_email import TEMPLATE
from brms_routing import route_actions


CADENCE = "@and(not(equals(outputs('Compose_days'),null)),or(contains(body('Parse_Notifications')?['reminderOffsetsDays'],int(coalesce(outputs('Compose_days'),999999))),and(less(int(coalesce(outputs('Compose_days'),999999)),0),equals(mod(mul(int(coalesce(outputs('Compose_days'),999999)),-1),int(body('Parse_Notifications')?['overdueRepeatDays'])),0))))"


def html_escape(expression):
    return "replace(replace(replace(replace(string(" + expression + "),'&','&amp;'),'<','&lt;'),'>','&gt;'),'\"','&quot;')"


def build_reminder(b):
    a = b.calculations()
    a['Require_current_schedule'] = b.check("@and(equals(outputs('Compose_due'),if(empty(body('Read_current')?['d']?['NextReviewDue']),null,convertTimeZone(body('Read_current')?['d']?['NextReviewDue'],'UTC','Eastern Standard Time','yyyy-MM-dd'))),equals(outputs('Compose_days'),body('Read_current')?['d']?['DaysToReview']),equals(outputs('Compose_status'),body('Read_current')?['d']?['Status']))", 'Compose_status')
    a['Require_approved_cadence'] = b.check("@and(equals(body('Parse_Notifications')?['cadenceApproval'],'approved'),equals(length(body('Parse_Notifications')?['reminderOffsetsDays']),4),contains(body('Parse_Notifications')?['reminderOffsetsDays'],30),contains(body('Parse_Notifications')?['reminderOffsetsDays'],14),contains(body('Parse_Notifications')?['reminderOffsetsDays'],7),contains(body('Parse_Notifications')?['reminderOffsetsDays'],0),equals(body('Parse_Notifications')?['overdueRepeatDays'],7))", 'Require_current_schedule')
    eligible = {
        'Compose_recipient': b.compose("@toLower(trim(first(body('Parse_Notifications')?['testRecipients'])))"),
        'Require_test_recipient': b.check("@and(equals(length(body('Parse_Notifications')?['testRecipients']),1),contains(outputs('Compose_recipient'),'@'),not(contains(outputs('Compose_recipient'),';')),not(contains(outputs('Compose_recipient'),',')),not(contains(outputs('Compose_recipient'),' ')))", 'Compose_recipient'),
        'Require_send_allowlist': b.check("@or(equals(body('Parse_Notifications')?['mode'],'preview'),and(equals(body('Parse_Notifications')?['testEmailEnabled'],true),lessOrEquals(length(coalesce(body('Parse_Notifications')?['testItemIds'],json('[]'))),2),contains(coalesce(body('Parse_Notifications')?['testItemIds'],json('[]')),int(items('For_each_document')?['ID']))))", 'Require_test_recipient'),
        'Compose_occurrence': b.compose("@concat(if(outputs('Compose_is_escalation'),'escalation-',if(less(int(outputs('Compose_days')),0),'overdue-','due-')),string(if(less(int(outputs('Compose_days')),0),mul(int(outputs('Compose_days')),-1),int(outputs('Compose_days')))))", 'Compose_route_description'),
        # Do not include package version or run time: upgrades/reruns must not resend.
        'Compose_key': b.compose("@concat('BRMS|',variables('Resources')?['governanceRegister']?['listId'],'|',string(items('For_each_document')?['ID']),'|',outputs('Compose_due'),'|',outputs('Compose_occurrence'),'|',body('Parse_Notifications')?['mode'],'|',outputs('Compose_recipient'))", 'Compose_occurrence'),
        'Require_key_length': b.check("@lessOrEquals(length(outputs('Compose_key')),255)", 'Compose_key'),
        'Find_notification': b.api('GetItems', {'dataset': b.res('notificationHistory','siteUrl'), 'table': b.res('notificationHistory','listId'), '$filter': "NotificationKey eq '@{replace(outputs('Compose_key'),'''','''''')}'", '$top': 2}, 'Require_key_length'),
        'Require_unique_notification': b.check("@lessOrEquals(length(body('Find_notification')?['value']),1)", 'Find_notification'),
    }
    eligible.update(route_actions(b,'Require_send_allowlist'))
    history_uri = "@concat('_api/web/lists(guid''',variables('Resources')?['notificationHistory']?['listId'],''')/items(',string(body('Create_claim')?['ID']),')')"

    def save_outcome(state, after, read, sent=False):
        payload = "setProperty(setProperty(json('{}'),'OutcomeState','" + state + "'),'SafeRunDetails',concat('Test email; run=',workflow()?['run']?['name'],'; route=',outputs('Compose_route_description'),'; outcome=" + state + "; connector acceptance is not proof of inbox delivery.'))"
        if sent:
            payload = "setProperty(" + payload + ",'SentTime',utcNow())"
        return b.http(b.res('notificationHistory','siteUrl'), history_uri, after, 'POST', '@string(' + payload + ')', {'Content-Type':'application/json;odata=nometadata', 'X-HTTP-Method':'MERGE', 'IF-MATCH':"@body('" + read + "')?['d']?['__metadata']?['etag']"}, retry=False)

    values = {
        'subject': "outputs('Compose_subject')",
        'badge': "if(less(int(outputs('Compose_days')),0),if(outputs('Compose_is_escalation'),'MANAGER ESCALATION','OVERDUE REVIEW'),'REVIEW REMINDER')",
        'heading': "if(less(int(outputs('Compose_days')),0),if(outputs('Compose_is_escalation'),'Manager action requested','Review overdue'),if(equals(int(outputs('Compose_days')),0),'Your review is due today','Your review is coming up'))",
        'intro': "if(less(int(outputs('Compose_days')),0),'This document has passed its review date and needs attention.','A scheduled review is due. Please check the document and confirm that it remains current.')",
        'document': "body('Read_current')?['d']?['Title']",
        'due': "formatDateTime(outputs('Compose_due'),'MMMM d, yyyy')",
        'status': "if(less(int(outputs('Compose_days')),0),concat(string(mul(int(outputs('Compose_days')),-1)),' days overdue'),if(equals(int(outputs('Compose_days')),0),'Due today',concat('Due in ',string(outputs('Compose_days')),' days')))",
        'action': "if(less(int(outputs('Compose_days')),0),'Complete the review, or agree a completion date with the responsible owner. Update the governance record when the review is complete.','Review the document, make any necessary changes, and update the last reviewed date in the governance record when finished.')",
        'record_url': "concat(variables('Resources')?['governanceRegister']?['siteUrl'],'/_layouts/15/listform.aspx?PageType=4&ListId=',uriComponent(variables('Resources')?['governanceRegister']?['listId']),'&ID=',string(items('For_each_document')?['ID']))",
        'note': "if(less(int(outputs('Compose_days')),0),concat('Manager escalation begins 14 days overdue and repeats weekly. ',outputs('Compose_route_description')),concat('Reminder schedule: 30, 14 and 7 days before review, on the due date, then weekly while overdue. ',outputs('Compose_route_description')))",
        'reference': "workflow()?['run']?['name']",
    }
    html = TEMPLATE
    for key, expression in values.items():
        html = html.replace('[[' + key + ']]', '@{' + html_escape(expression) + '}')

    send = {
        'Compose_subject': b.compose("@concat('[BRMS TEST] ',if(less(int(outputs('Compose_days')),0),if(outputs('Compose_is_escalation'),'Manager escalation: ','Overdue review: '),'Review reminder: '),body('Read_current')?['d']?['Title'],' | Due ',outputs('Compose_due'))"),
        'Compose_email_html': b.compose(html, 'Compose_subject'),
        'Recheck_notification_settings': b.api('GetItem', {'dataset': b.SITE, 'table': b.CONFIG, 'id': "@first(body('Filter_Notifications'))?['ID']"}, 'Compose_email_html'),
        'Require_unchanged_settings': b.check("@and(equals(body('Recheck_notification_settings')?['Enabled'],true),equals(body('Recheck_notification_settings')?['Modified'],first(body('Filter_Notifications'))?['Modified']))", 'Recheck_notification_settings'),
        'Read_before_send': b.read_item('Require_unchanged_settings'),
        'Require_unchanged_send': b.check("@and(equals(body('Read_before_send')?['d']?['Active'],true),equals(body('Read_before_send')?['d']?['__metadata']?['etag'],body('Read_current')?['d']?['__metadata']?['etag']))", 'Read_before_send'),
        'Send_test_email': b.action('OpenApiConnection', {
            'host': {'apiId':'/providers/Microsoft.PowerApps/apis/shared_office365','connectionName':'shared_office365','operationId':'SendEmailV2'},
            'parameters': {'emailMessage/To':"@outputs('Compose_recipient')",'emailMessage/Subject':"@outputs('Compose_subject')",'emailMessage/Body':"@outputs('Compose_email_html')",'emailMessage/Importance':'Normal'},
            'authentication':"@parameters('$authentication')", 'retryPolicy':{'type':'none'},
        }, 'Require_unchanged_send'),
        'Read_sent_claim': b.http(b.res('notificationHistory','siteUrl'),history_uri,'Send_test_email'),
        'Record_sent': save_outcome('Sent', 'Read_sent_claim','Read_sent_claim',True),
        'Mark_sent': b.setvar('ItemState','Succeeded','Record_sent'),
        'Record_ambiguous_delivery': b.scope({
            'Read_unknown_claim': b.http(b.res('notificationHistory','siteUrl'),history_uri),
            'Record_unknown': save_outcome('Unknown','Read_unknown_claim','Read_unknown_claim'),
            'Fail_ambiguous_send': b.check('@false','Record_unknown'),
        },'Send_test_email',['Failed','TimedOut']),
    }
    create = {
        'Read_before_claim': b.read_item(),
        'Require_same_claim': b.check("@and(equals(body('Read_before_claim')?['d']?['Active'],true),equals(body('Read_before_claim')?['d']?['__metadata']?['etag'],body('Read_current')?['d']?['__metadata']?['etag']))",'Read_before_claim'),
        'Try_create_claim': b.scope({'Create_claim': b.api('PostItem', {
            'dataset':b.res('notificationHistory','siteUrl'),'table':b.res('notificationHistory','listId'),
            'item/Title':"@outputs('Compose_key')",'item/NotificationKey':"@outputs('Compose_key')",
            'item/RegisterItemIdentity':"@string(items('For_each_document')?['ID'])",'item/ReviewCycleDueDate':"@outputs('Compose_due')",
            'item/RuleThreshold':"@outputs('Compose_occurrence')",'item/IntendedRecipient':"@outputs('Compose_recipient')",
            'item/OutcomeState':{'Value':"@if(equals(body('Parse_Notifications')?['mode'],'preview'),'Preview','Pending')"},
            'item/AttemptTime':'@utcNow()', 'item/SafeRunDetails':"@concat('Mode=',body('Parse_Notifications')?['mode'],'; route=',outputs('Compose_route_description'),'; atomic claim; run=',workflow()?['run']?['name'],'; Pending/Unknown must be reconciled manually; never blindly resend.')",
        },retry=False)},'Require_same_claim'),
        'If_test_delivery': b.condition("@equals(body('Parse_Notifications')?['mode'],'test')",send,{'Mark_preview_created':b.setvar('ItemState','Succeeded')},after='Try_create_claim'),
        'Recover_claim_conflict': b.scope({
            'Requery_claim': b.api('GetItems',{'dataset':b.res('notificationHistory','siteUrl'),'table':b.res('notificationHistory','listId'),'$filter':"NotificationKey eq '@{replace(outputs('Compose_key'),'''','''''')}'",'$top':2}),
            'Require_recovered_claim': b.check("@equals(length(body('Requery_claim')?['value']),1)",'Requery_claim'),
            'Require_recovered_terminal_state': b.check("@contains(createArray('Preview','Sent','Suppressed'),coalesce(first(body('Requery_claim')?['value'])?['OutcomeState']?['Value'],first(body('Requery_claim')?['value'])?['OutcomeState']))",'Require_recovered_claim'),
        },'Try_create_claim',['Failed','TimedOut']),
    }
    existing = {'Require_existing_terminal_state': b.check("@contains(createArray('Preview','Sent','Suppressed'),coalesce(first(body('Find_notification')?['value'])?['OutcomeState']?['Value'],first(body('Find_notification')?['value'])?['OutcomeState']))")}
    eligible['Create_or_suppress'] = b.condition("@equals(length(body('Find_notification')?['value']),0)",create,existing,after='Require_unique_notification')
    # Non-selected synthetic records are skipped in test mode, not counted as failed sends.
    selected = "or(equals(body('Parse_Notifications')?['mode'],'preview'),contains(coalesce(body('Parse_Notifications')?['testItemIds'],json('[]')),int(items('For_each_document')?['ID'])))"
    a['If_reminder_due'] = b.condition('@and(' + selected + ',' + CADENCE[1:] + ')',eligible,after='Require_approved_cadence')
    return a
