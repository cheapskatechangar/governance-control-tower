"""Resolve owner/manager intent; actual delivery remains restricted to the test address."""

ESCALATION = "@and(lessOrEquals(int(outputs('Compose_days')),mul(int(body('Parse_Notifications')?['escalation']?['startAfterDays']),-1)),equals(mod(sub(mul(int(outputs('Compose_days')),-1),int(body('Parse_Notifications')?['escalation']?['startAfterDays'])),int(body('Parse_Notifications')?['escalation']?['repeatDays'])),0))"


def route_actions(b, after):
    lookup = b.action('OpenApiConnection', {
        'host': {'apiId':'/providers/Microsoft.PowerApps/apis/shared_office365users','connectionName':'shared_office365users','operationId':'Manager_V2'},
        'parameters': {'id':"@outputs('Compose_owner_upn')",'$select':'id,displayName,mail,userPrincipalName'},
        'authentication':"@parameters('$authentication')",
        'retryPolicy':{'type':'exponential','count':3,'interval':'PT10S','minimumInterval':'PT5S','maximumInterval':'PT1M'}
    })
    fallback = "toLower(trim(coalesce(body('Parse_Notifications')?['escalation']?['fallbackRecipient'],'')))"
    manager = "toLower(trim(coalesce(body('Get_owner_manager')?['mail'],'')))"
    failed = b.setvar('Route', {
        'to': "@if(equals(string(outputs('Get_owner_manager')?['statusCode']),'404'),"+fallback+",'')",
        'cc':"@outputs('Compose_owner_email')",
        'status':"@if(equals(string(outputs('Get_owner_manager')?['statusCode']),'404'),'fallback-manager-not-found','manager-lookup-failed')"
    }, 'Get_owner_manager')
    failed['runAfter']={'Get_owner_manager':['Failed','TimedOut']}
    return {
        'Require_escalation_policy':b.check("@and(equals(body('Parse_Notifications')?['escalation']?['enabled'],true),equals(body('Parse_Notifications')?['escalation']?['startAfterDays'],14),equals(body('Parse_Notifications')?['escalation']?['repeatDays'],7),equals(body('Parse_Notifications')?['escalation']?['recipientRule'],'ownerManager'),equals(body('Parse_Notifications')?['escalation']?['copyOwner'],true))",after),
        'Compose_is_escalation':b.compose(ESCALATION,'Require_escalation_policy'),
        'Read_owner_identity':b.http(b.res('governanceRegister','siteUrl'),"@concat('_api/web/siteusers/getbyid(',string(body('Read_current')?['d']?['OwnerId']),')?$select=Id,LoginName,Email')",'Compose_is_escalation'),
        'Compose_owner_email':b.compose("@toLower(trim(coalesce(body('Read_owner_identity')?['d']?['Email'],'')))",'Read_owner_identity'),
        'Compose_owner_upn':b.compose("@last(split(coalesce(body('Read_owner_identity')?['d']?['LoginName'],''),'|'))",'Compose_owner_email'),
        'Require_owner_identity':b.check("@and(contains(outputs('Compose_owner_upn'),'@'),contains(outputs('Compose_owner_email'),'@'),not(contains(outputs('Compose_owner_email'),';')),not(contains(outputs('Compose_owner_email'),',')),not(contains(outputs('Compose_owner_email'),' ')))",'Compose_owner_upn'),
        'Set_owner_route':b.setvar('Route',{'to':"@outputs('Compose_owner_email')",'cc':'','status':'owner'},'Require_owner_identity'),
        'If_manager_escalation':b.condition("@outputs('Compose_is_escalation')",{
            'Get_owner_manager':lookup,
            'Set_manager_route':b.setvar('Route',{'to':'@if(empty('+manager+'),'+fallback+','+manager+')','cc':"@outputs('Compose_owner_email')",'status':'@if(empty('+manager+'),\'fallback-manager-mail-missing\',\'manager\')'},'Get_owner_manager'),
            'Handle_manager_lookup_failure':failed,
        },after='Set_owner_route'),
        # A 404 can use an explicitly configured fallback. Auth/service failures cannot.
        'Require_resolved_route':b.action('ParseJson',{'content':"@and(contains(variables('Route')?['to'],'@'),not(contains(variables('Route')?['to'],';')),not(contains(variables('Route')?['to'],',')),not(contains(variables('Route')?['to'],' ')),not(equals(variables('Route')?['status'],'manager-lookup-failed')))",'schema':{'type':'boolean','enum':[True]}},'If_manager_escalation',['Succeeded','Failed','TimedOut']),
        'Compose_route_description':b.compose("@concat('Intended To: ',variables('Route')?['to'],if(empty(variables('Route')?['cc']),'',concat('; intended Cc: ',variables('Route')?['cc'])),'; resolution: ',variables('Route')?['status'],'. TEST ONLY: delivery redirected to the configured test recipient; no owner or manager was contacted.')",'Require_resolved_route'),
    }
