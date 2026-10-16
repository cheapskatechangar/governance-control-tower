"""Build native, disabled Power Automate flows for browser-based solution import.

Uses the existing BRMS configuration contract. No tenant API calls or PowerShell.
The initial package is deliberately limited to the existing BRMS-TEST- records in the BRMS Test department.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from brms_email import TEMPLATE

SITE = 'https://reedelsevier.sharepoint.com/sites/ELSBUProjects/BRMS'
ENV = '2c2b2f3f-eec6-ea9e-a492-7114c0975e11'
CONFIG = '8a5524c7-01bd-4608-899f-62281313a8c6'
RUNS = 'f0f62faf-86bb-4257-9c0d-f4f8571e71e2'
VERSION = '1.0.0.10'
ALL = ['Succeeded', 'Failed', 'TimedOut', 'Skipped']


def action(kind, inputs=None, after=None, states=None, **kwargs):
    a = {'type': kind, 'runAfter': {after: states or ['Succeeded']} if after else {}}
    if inputs is not None:
        a['inputs'] = inputs
    a.update(kwargs)
    return a


def compose(value, after=None):
    return action('Compose', value, after)


def check(expression, after=None):
    return action('ParseJson', {'content': expression, 'schema': {'type': 'boolean', 'enum': [True]}}, after)


def scope(actions, after=None, states=None):
    return action('Scope', after=after, states=states, actions=actions)


def condition(expression, yes, no=None, after=None):
    return action('If', after=after, expression=expression, actions=yes, **{'else': {'actions': no or {}}})


def setvar(name, value, after=None):
    return action('SetVariable', {'name': name, 'value': value}, after)


def query(source, expression, after=None):
    return action('Query', {'from': source, 'where': expression}, after)


def api(operation, params, after=None, pages=False, retry=True):
    if operation == 'PostItem':
        # Runtime-resolved lists have no design-time expanded item schema.
        # Supply the required dynamic item object instead of flattened paths.
        params = {**{k: v for k, v in params.items() if not k.startswith('item/')},
                  'item': {k[5:]: v for k, v in params.items() if k.startswith('item/')}}
    a = action('OpenApiConnection', {
        'host': {'apiId': '/providers/Microsoft.PowerApps/apis/shared_sharepointonline',
                 'connectionName': 'shared_sharepointonline', 'operationId': operation},
        'parameters': params,
        'authentication': "@parameters('$authentication')",
        'retryPolicy': {'type': 'exponential', 'count': 4, 'interval': 'PT20S', 'minimumInterval': 'PT5S', 'maximumInterval': 'PT2M'} if retry else {'type': 'none'}
    }, after)
    if pages:
        a['runtimeConfiguration'] = {'paginationPolicy': {'minimumItemCount': 100000}}
    return a


def res(role, field):
    return f"@variables('Resources')?['{role}']?['{field}']"


def http(site, uri, after=None, method='GET', body=None, headers=None, retry=True):
    p = {'dataset': site, 'parameters/method': method, 'parameters/uri': uri,
         'parameters/headers': {'Accept': 'application/json;odata=verbose', **(headers or {})}}
    if body is not None:
        p['parameters/body'] = body
    return api('HttpRequest', p, after, retry=retry)


def item_uri(read=False):
    suffix = '?$select=Id,Title,Department,Active,Modified,LastReviewedDate,ReviewFrequency,NextReviewDue,DaysToReview,Status,DocumentLink,SourceModifiedDate' if read else ''
    return "@concat('_api/web/lists(guid''',variables('Resources')?['governanceRegister']?['listId'],''')/items(',string(items('For_each_document')?['ID']),')" + suffix + "')"


def read_item(after=None):
    return http(res('governanceRegister', 'siteUrl'), item_uri(True), after)


def patch(after, read='Read_current'):
    return http(res('governanceRegister', 'siteUrl'), item_uri(), after, 'POST', "@string(outputs('Compose_patch'))", {
        'Content-Type': 'application/json;odata=nometadata', 'X-HTTP-Method': 'MERGE',
        'IF-MATCH': f"@body('{read}')?['d']?['__metadata']?['etag']"
    }, retry=False)


def bootstrap():
    a = {'Get_configuration': api('GetItems', {'dataset': SITE, 'table': CONFIG,
        '$filter': "Enabled eq 1 and (ConfigKey eq 'resource-map-v2' or ConfigKey eq 'review-rules-v1' or ConfigKey eq 'notification-settings-v1')", '$top': 20})}
    previous = 'Get_configuration'
    for label, key in [('Map', 'resource-map-v2'), ('Rules', 'review-rules-v1'), ('Notifications', 'notification-settings-v1')]:
        a['Filter_' + label] = query("@body('Get_configuration')?['value']", f"@equals(item()?['ConfigKey'],'{key}')", previous)
        a['Require_' + label] = check(f"@equals(length(body('Filter_{label}')),1)", 'Filter_' + label)
        a['Parse_' + label] = action('ParseJson', {'content': f"@json(first(body('Filter_{label}'))?['Value'])", 'schema': {'type': 'object'}}, 'Require_' + label)
        previous = 'Parse_' + label
    a['Set_resources'] = setvar('Resources', "@body('Parse_Map')?['resources']", previous)
    a['Require_test_scope'] = check("@and(equals(body('Parse_Map')?['powerAutomate']?['environmentId'],'" + ENV + "'),equals(body('Parse_Map')?['powerAutomate']?['validationScope'],'synthetic-records-only'),contains(createArray('preview','test'),body('Parse_Notifications')?['mode']),equals(body('Parse_Notifications')?['outboundRemindersEnabled'],false))", 'Set_resources')
    a['Compose_local_day'] = compose("@formatDateTime(convertTimeZone(variables('Started'),'UTC','Eastern Standard Time'),'yyyy-MM-dd')", 'Require_test_scope')
    a['Compose_day_start'] = compose("@convertToUtc(concat(outputs('Compose_local_day'),'T00:00:00'),'Eastern Standard Time')", 'Compose_local_day')
    a['Set_context'] = setvar('Context', "@concat('v9|" + ENV + "|',variables('Resources')?['governanceRegister']?['listId'],'|',first(body('Filter_Map'))?['Modified'],'|',first(body('Filter_Rules'))?['Modified'])", 'Compose_day_start')
    return a


def calculations():
    return {
        'Compose_months': compose("@int(coalesce(body('Parse_Rules')?['calendarMonthsByFrequency']?[body('Read_current')?['d']?['ReviewFrequency']],0))"),
        'Require_frequency': check("@or(empty(body('Read_current')?['d']?['LastReviewedDate']),greater(outputs('Compose_months'),0))", 'Compose_months'),
        'Compose_reviewed_day': compose("@if(empty(body('Read_current')?['d']?['LastReviewedDate']),null,convertTimeZone(body('Read_current')?['d']?['LastReviewedDate'],'UTC','Eastern Standard Time','yyyy-MM-dd'))", 'Require_frequency'),
        'Compose_due': compose("@if(empty(outputs('Compose_reviewed_day')),null,formatDateTime(addToTime(concat(outputs('Compose_reviewed_day'),'T00:00:00'),outputs('Compose_months'),'Month'),'yyyy-MM-dd'))", 'Compose_reviewed_day'),
        'Compose_days': compose("@if(empty(outputs('Compose_due')),null,div(sub(ticks(outputs('Compose_due')),ticks(outputs('Compose_local_day'))),864000000000))", 'Compose_due'),
        'Compose_status': compose("@if(empty(outputs('Compose_due')),'Not Set',if(less(int(outputs('Compose_days')),0),'Overdue',if(lessOrEquals(int(outputs('Compose_days')),int(body('Parse_Rules')?['dueSoonMaximumDays'])),'Due Soon','Current')))", 'Compose_days')
    }


def refresh_item():
    a = calculations()
    a['Compose_patch'] = compose({'NextReviewDue': "@if(empty(outputs('Compose_due')),null,convertToUtc(concat(outputs('Compose_due'),'T00:00:00'),'Eastern Standard Time'))", 'DaysToReview': "@outputs('Compose_days')", 'Status': "@outputs('Compose_status')"}, 'Compose_status')
    a['Update_schedule'] = patch('Compose_patch')
    a['Mark_refresh_success'] = setvar('ItemState', 'Succeeded', 'Update_schedule')
    return a


def reminder_item():
    # Kept in a separate module so email delivery can be reviewed independently.
    from brms_reminder import build_reminder
    from types import SimpleNamespace
    return build_reminder(SimpleNamespace(**globals()))


def source_item():
    mapped = {
        'Compose_mapping': compose("@first(body('Match_source'))"),
        'Compose_site_path': compose("@decodeUriComponent(uriPath(outputs('Compose_mapping')?['siteUrl']))",'Compose_mapping'),
        'Require_same_source_site': check("@and(equals(toLower(uriHost(body('Read_current')?['d']?['DocumentLink']?['Url'])),toLower(uriHost(outputs('Compose_mapping')?['siteUrl']))),startsWith(toLower(decodeUriComponent(uriPath(body('Read_current')?['d']?['DocumentLink']?['Url']))),toLower(concat(outputs('Compose_site_path'),'/'))))",'Compose_site_path'),
        'Compose_source_path': compose("@substring(decodeUriComponent(uriPath(body('Read_current')?['d']?['DocumentLink']?['Url'])),length(outputs('Compose_site_path')))",'Require_same_source_site'),
        'Read_source_metadata': api('GetFileMetadataByPath',{'dataset': "@outputs('Compose_mapping')?['siteUrl']",'path': "@outputs('Compose_source_path')"},'Compose_source_path'),
        'Read_before_source_update': read_item('Read_source_metadata'),
        'Require_unchanged_source': check("@and(equals(body('Read_before_source_update')?['d']?['Active'],true),equals(body('Read_before_source_update')?['d']?['__metadata']?['etag'],body('Read_current')?['d']?['__metadata']?['etag']))",'Read_before_source_update'),
        'Compose_patch': compose({'SourceModifiedDate': "@body('Read_source_metadata')?['LastModified']"},'Require_unchanged_source'),
        'Update_source_observation': patch('Compose_patch','Read_before_source_update'),
        'Mark_source_success': setvar('ItemState','Succeeded','Update_source_observation')
    }
    return {
        'Require_document_link': check("@not(empty(body('Read_current')?['d']?['DocumentLink']?['Url']))"),
        'Match_source': query("@body('Parse_Map')?['sourceLibraries']", "@and(equals(item()?['enabled'],true),equals(toLower(uriHost(body('Read_current')?['d']?['DocumentLink']?['Url'])),toLower(uriHost(item()?['siteUrl']))),startsWith(toLower(decodeUriComponent(uriPath(body('Read_current')?['d']?['DocumentLink']?['Url']))),toLower(concat(item()?['folderServerRelativeUrl'],'/'))))",'Require_document_link'),
        'Require_unambiguous_source': check("@lessOrEquals(length(body('Match_source')),1)",'Match_source'),
        'If_source_mapped': condition("@equals(length(body('Match_source')),1)",mapped,after='Require_unambiguous_source')
    }


def workflow(function, hour, item_actions):
    a = {}
    previous = None
    for name, typ, value in [('Started','String','@utcNow()'),('Outcomes','Array',[]),('ItemState','String','Skipped'),('Context','String','bootstrap-unresolved'),('Resources','Object',{'automationRunHistory':{'siteUrl':SITE,'listId':RUNS}})]:
        key='Init_'+name
        a[key]=action('InitializeVariable',{'variables':[{'name':name,'type':typ.lower(),'value':value}]},previous)
        previous=key
    work=bootstrap()
    after='Set_context'
    if function=='Review Reminders':
        work['Check_unique_notification_key']=http(res('notificationHistory','siteUrl'),"@concat('_api/web/lists(guid''',variables('Resources')?['notificationHistory']?['listId'],''')/fields/getbyinternalnameortitle(''NotificationKey'')?$select=EnforceUniqueValues')",after)
        work['Require_unique_notification_key']=check("@equals(body('Check_unique_notification_key')?['d']?['EnforceUniqueValues'],true)",'Check_unique_notification_key')
        work['Find_successful_refresh']=api('GetItems',{'dataset':res('automationRunHistory','siteUrl'),'table':res('automationRunHistory','listId'),
            '$filter':"AutomationFunction eq 'Review Schedule Refresh' and RunResult eq 'Succeeded' and ResourceMapVersion eq '@{variables('Context')}' and StartTime ge datetime'@{outputs('Compose_day_start')}'",'$orderby':'EndTime desc','$top':1},'Require_unique_notification_key')
        work['Require_current_refresh']=check("@equals(length(body('Find_successful_refresh')?['value']),1)",'Find_successful_refresh')
        after='Require_current_refresh'
    work['Get_documents']=api('GetItems',{'dataset':res('governanceRegister','siteUrl'),'table':res('governanceRegister','listId'),'$filter':"startswith(Title,'BRMS-TEST-') and Department eq 'BRMS Test'",'$top':5000},after,pages=True)
    work['Require_complete_read']=check("@less(length(body('Get_documents')?['value']),100000)",'Get_documents')
    work['Select_acceptance_records']=query("@body('Get_documents')?['value']","@and(startsWith(item()?['Title'],'BRMS-TEST-'),equals(item()?['Department'],'BRMS Test'))",'Require_complete_read')
    work['Require_all_acceptance_records']=check("@greater(length(body('Select_acceptance_records')),0)",'Select_acceptance_records')
    process={'Read_current':read_item(), 'If_still_active':condition("@and(equals(body('Read_current')?['d']?['Active'],true),startsWith(body('Read_current')?['d']?['Title'],'BRMS-TEST-'),equals(body('Read_current')?['d']?['Department'],'BRMS Test'))",item_actions,after='Read_current')}
    work['For_each_document']=action('Foreach',after='Require_all_acceptance_records',foreach="@body('Select_acceptance_records')",runtimeConfiguration={'concurrency':{'repetitions':1}},actions={
        'Reset_item_state':setvar('ItemState','Skipped'), 'Process_document':scope(process,'Reset_item_state'),
        'Record_one_outcome':action('AppendToArrayVariable',{'name':'Outcomes','value':{'id':"@items('For_each_document')?['ID']",'state':"@if(equals(actions('Process_document')?['status'],'Succeeded'),variables('ItemState'),'Failed')"}},'Process_document',ALL)
    })
    a['Work']=scope(work,previous)
    finish={
        'Successful_items':query("@variables('Outcomes')","@equals(item()?['state'],'Succeeded')"),
        'Failed_items':query("@variables('Outcomes')","@equals(item()?['state'],'Failed')",'Successful_items'),
        'Skipped_items':query("@variables('Outcomes')","@equals(item()?['state'],'Skipped')",'Failed_items'),
        'Compose_result':compose("@if(not(equals(actions('Work')?['status'],'Succeeded')),'Failed',if(greater(length(body('Failed_items')),0),if(equals(length(body('Successful_items')),0),'Failed','SucceededWithWarnings'),'Succeeded'))",'Skipped_items'),
        'Record_run':api('PostItem',{'dataset':res('automationRunHistory','siteUrl'),'table':res('automationRunHistory','listId'),
            'item/Title':"@concat('"+function+" ',variables('Started'))",'item/RunKey':"@workflow()?['run']?['name']",'item/AutomationFunction':function,
            'item/FlowIdentity':"@concat('"+ENV+"|',workflow()?['name'])",'item/StartTime':"@variables('Started')",'item/EndTime':'@utcNow()',
            'item/ResourceMapVersion':"@variables('Context')",'item/ProcessedCount':"@length(variables('Outcomes'))",'item/SuccessCount':"@length(body('Successful_items'))",'item/FailureCount':"@length(body('Failed_items'))",
            'item/RunResult':{'Value':"@outputs('Compose_result')"},'item/FailedReferences':"@string(take(body('Failed_items'),100))",
            'item/SanitizedErrors':"@concat('Scope=',actions('Work')?['status'],'; skipped=',string(length(body('Skipped_items'))),'; skippedIds=',string(take(body('Skipped_items'),100)),'; failureListTruncated=',string(greater(length(body('Failed_items')),100)),'; skippedListTruncated=',string(greater(length(body('Skipped_items')),100)),'; run=',workflow()?['run']?['name'])"
        },'Compose_result'),
        'Fail_if_work_failed':condition("@equals(outputs('Compose_result'),'Failed')",{'End_failed':action('Terminate',{'runStatus':'Failed','runError':{'code':'BRMS_VALIDATION_FAILED','message':'BRMS processing failed. See the actual flow run and BRMS Automation Run History.'}})},after='Record_run')
    }
    a['Finalize']=scope(finish,'Work',ALL)
    return {'schemaVersion':'1.0.0.0','properties':{'connectionReferences':({**({'shared_office365':{'api':{'name':'shared_office365'},'connection':{'connectionReferenceLogicalName':'cr1e9_BRMSOutlook'},'runtimeSource':'embedded'}} if function=='Review Reminders' else {}),'shared_sharepointonline':{'api':{'name':'shared_sharepointonline'},'connection':{'connectionReferenceLogicalName':'cr1e9_BRMSSharePoint'},'runtimeSource':'embedded'}}),
        'definition':{'metadata':{'defaultToEmbeddedConnections':True},'$schema':'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#','contentVersion':'1.0.0.0',
            'parameters':{'$authentication':{'type':'SecureObject','defaultValue':{}},'$connections':{'type':'Object','defaultValue':{}}},
            'triggers':{'Recurrence':{'type':'Recurrence','recurrence':{'frequency':'Day','interval':1,'timeZone':'Eastern Standard Time','schedule':{'hours':[str(hour)],'minutes':[0]}},'runtimeConfiguration':{'concurrency':{'runs':1}}}},'actions':a,'outputs':{}}}}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    (out/'Workflows').mkdir(exist_ok=True)
    for f in (Path(__file__).parent/'native-brms').glob('*.xml'):
        shutil.copyfile(f,out/f.name)
    for fn,n,h,builder in [('Review Schedule Refresh','1',6,refresh_item),('Review Reminders','2',8,reminder_item),('Source Document Monitor','3',7,source_item)]:
        guid=n*8+'-'+n*4+'-4'+n*3+'-8'+n*3+'-'+n*12
        (out/'Workflows'/('BRMSGCT'+fn.replace(' ','')+'-'+guid+'.json')).write_text(json.dumps(workflow(fn,h,builder()),indent=2))
    archive=out/'BRMSGovernanceControlTower.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for f in sorted(out.rglob('*')):
            if f.is_file() and f!=archive:
                z.write(f,f.relative_to(out))
    print(json.dumps({'path':str(archive),'version':VERSION,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}))


if __name__=='__main__':
    main()
