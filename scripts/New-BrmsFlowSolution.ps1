[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RegisterSiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$RegisterListId,

    [Parameter(Mandatory = $true)]
    [string]$ConfigurationSiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$ConfigurationListId,

    [Parameter(Mandatory = $true)]
    [string]$NotificationHistorySiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$NotificationHistoryListId,

    [Parameter(Mandatory = $true)]
    [string]$AutomationRunHistorySiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$AutomationRunHistoryListId,

    [Parameter(Mandatory = $true)]
    [string]$DefaultSourceSiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$DefaultSourceServerRelativeSitePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$BusinessTimeZone = 'Eastern Standard Time',
    [string]$SolutionUniqueName = 'BRMSGovernanceControlTower',
    [string]$SolutionDisplayName = 'BRMS Governance Control Tower',
    [string]$SolutionVersion = '1.0.0.4',
    [string]$PublisherUniqueName = 'Cr115e7',
    [string]$PublisherDisplayName = 'CDS Default Publisher',
    [string]$PublisherPrefix = 'cr1e9',
    [string]$ConnectionReferenceLogicalName = 'cr1e9_BRMSSharePoint',
    [int]$PaginationMinimumItemCount = 100000
)

$ErrorActionPreference = 'Stop'

foreach ($name in @(
        $SolutionUniqueName,
        $SolutionDisplayName,
        'BRMS - GCT - Review Schedule Refresh',
        'BRMS - GCT - Review Reminders',
        'BRMS - GCT - Source Document Monitor'
    )) {
    if ($name -match '(?i)\b(?:DEV|PROD)\b') {
        throw 'BRMS solution and flow names must not include DEV or PROD labels.'
    }
}

function New-Host {
    param([string]$OperationId)
    [ordered]@{
        apiId = '/providers/Microsoft.PowerApps/apis/shared_sharepointonline'
        operationId = $OperationId
        connectionName = 'shared_sharepointonline'
    }
}

# Retry policy is placed inside inputs.retryPolicy per Logic Apps schema.
# Pagination is expressed via runtimeConfiguration.paginationPolicy on the action.
function New-OpenApiAction {
    param(
        [string]$OperationId,
        [hashtable]$Parameters,
        [hashtable]$RunAfter = @{},
        [switch]$Paginate
    )
    $inputs = [ordered]@{
        host = New-Host $OperationId
        parameters = $Parameters
        retryPolicy = [ordered]@{
            type = 'exponential'
            count = 4
            interval = 'PT20S'
            minimumInterval = 'PT5S'
            maximumInterval = 'PT2M'
        }
    }
    $action = [ordered]@{
        runAfter = $RunAfter
        type = 'OpenApiConnection'
        inputs = $inputs
    }
    if ($Paginate) {
        $action.runtimeConfiguration = [ordered]@{
            paginationPolicy = [ordered]@{ minimumItemCount = $PaginationMinimumItemCount }
        }
    }
    $action
}

function New-InitVariable {
    param([string]$Name, [string]$Type, $Value, [hashtable]$RunAfter = @{})
    [ordered]@{
        runAfter = $RunAfter
        type = 'InitializeVariable'
        inputs = [ordered]@{
            variables = @(
                [ordered]@{ name = $Name; type = $Type; value = $Value }
            )
        }
    }
}

function New-AppendArray {
    param([string]$Name, $Value, [hashtable]$RunAfter)
    [ordered]@{
        runAfter = $RunAfter
        type = 'AppendToArrayVariable'
        inputs = [ordered]@{ name = $Name; value = $Value }
    }
}

function New-IncrementVariable {
    param([string]$Name, [int]$Value, [hashtable]$RunAfter)
    [ordered]@{
        runAfter = $RunAfter
        type = 'IncrementVariable'
        inputs = [ordered]@{ name = $Name; value = $Value }
    }
}

function New-Compose {
    param($Inputs, [hashtable]$RunAfter = @{})
    [ordered]@{ runAfter = $RunAfter; type = 'Compose'; inputs = $Inputs }
}

function New-Terminate {
    param([string]$Status, [string]$Code, [string]$Message, [hashtable]$RunAfter)
    [ordered]@{
        runAfter = $RunAfter
        type = 'Terminate'
        inputs = [ordered]@{
            runStatus = $Status
            runError = [ordered]@{ code = $Code; message = $Message }
        }
    }
}

function New-RecurrenceTrigger {
    param([int]$Hour)
    [ordered]@{
        Recurrence = [ordered]@{
            type = 'Recurrence'
            recurrence = [ordered]@{
                frequency = 'Day'
                interval = 1
                timeZone = $BusinessTimeZone
                schedule = @{ hours = @([string]$Hour); minutes = @(0) }
            }
            runtimeConfiguration = [ordered]@{
                concurrency = @{ runs = 1 }
            }
        }
    }
}

function New-ClientData {
    param(
        [hashtable]$Triggers,
        [hashtable]$Actions
    )
    [ordered]@{
        properties = [ordered]@{
            connectionReferences = [ordered]@{
                shared_sharepointonline = [ordered]@{
                    api = @{ name = 'shared_sharepointonline' }
                    connection = @{ connectionReferenceLogicalName = $ConnectionReferenceLogicalName }
                    runtimeSource = 'invoker'
                }
            }
            definition = [ordered]@{
                metadata = @{ defaultToEmbeddedConnections = $true }
                '$schema' = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
                contentVersion = '1.0.0.0'
                parameters = [ordered]@{
                    '$authentication' = @{ defaultValue = @{}; type = 'SecureObject' }
                    '$connections' = @{ defaultValue = @{}; type = 'Object' }
                }
                triggers = $Triggers
                actions = $Actions
                outputs = @{}
            }
        }
    }
}

# Actions that read and validate the BRMS Configuration list. They resolve
# review-rules, notification-settings, source-library-map, and the current
# refresh state expression used by the reminder gate.
function Add-ConfigurationBootstrap {
    param(
        [System.Collections.Specialized.OrderedDictionary]$Actions,
        [string]$LastRunAfter,
        [switch]$IncludeSourceLibraryMap
    )
    $Actions['Get_configuration'] = New-OpenApiAction -OperationId 'GetItems' -Parameters @{
        dataset = "$($ConfigurationSiteUrl)"
        table = "$($ConfigurationListId)"
        '$filter' = "Enabled eq 1 and (ConfigKey eq 'review-rules-v1' or ConfigKey eq 'notification-settings-v1' or ConfigKey eq 'source-library-map-v1')"
        '$top' = 200
    } -Paginate
    $Actions['Compose_configuration_map'] = New-Compose -RunAfter @{ Get_configuration = @('Succeeded') } -Inputs @{
        reviewRules = "@first(filter(outputs('Get_configuration')?['body/value'], equals(item()?['ConfigKey'],'review-rules-v1')))"
        notificationSettings = "@first(filter(outputs('Get_configuration')?['body/value'], equals(item()?['ConfigKey'],'notification-settings-v1')))"
        sourceLibraryMap = "@first(filter(outputs('Get_configuration')?['body/value'], equals(item()?['ConfigKey'],'source-library-map-v1')))"
    }
    $Actions['Validate_configuration'] = [ordered]@{
        runAfter = @{ Compose_configuration_map = @('Succeeded') }
        type = 'If'
        expression = "@or(empty(outputs('Compose_configuration_map')?['reviewRules']),empty(outputs('Compose_configuration_map')?['notificationSettings']))"
        actions = [ordered]@{
            Terminate_missing_configuration = New-Terminate -Status 'Failed' -Code 'BRMS-CFG-001' -Message 'BRMS Configuration is missing review-rules-v1 or notification-settings-v1.' -RunAfter @{}
        }
        else = [ordered]@{ actions = [ordered]@{} }
    }
    $Actions['Parse_review_rules'] = New-Compose -RunAfter @{ Validate_configuration = @('Succeeded') } -Inputs "@json(outputs('Compose_configuration_map')?['reviewRules']?['Value'])"
    $Actions['Parse_notification_settings'] = New-Compose -RunAfter @{ Parse_review_rules = @('Succeeded') } -Inputs "@json(outputs('Compose_configuration_map')?['notificationSettings']?['Value'])"
    if ($IncludeSourceLibraryMap) {
        $Actions['Parse_source_library_map'] = New-Compose -RunAfter @{ Parse_notification_settings = @('Succeeded') } -Inputs "@if(empty(outputs('Compose_configuration_map')?['sourceLibraryMap']), json('[]'), json(outputs('Compose_configuration_map')?['sourceLibraryMap']?['Value']))"
    }
}

# Read the notification-preview flag; enforce preview-only regardless.
function New-PreviewGuardCompose {
    param([hashtable]$RunAfter)
    New-Compose -RunAfter $RunAfter -Inputs "@coalesce(outputs('Parse_notification_settings')?['mode'],'preview')"
}

function New-RunHistoryPost {
    param(
        [string]$Function,
        [string]$FlowName,
        [hashtable]$RunAfter,
        [string]$ResultExpression,
        [string]$ProcessedExpression,
        [string]$SuccessExpression,
        [string]$FailureExpression,
        [string]$FailedReferencesExpression,
        [string]$SanitizedErrorsExpression
    )
    New-OpenApiAction -OperationId 'PostItem' -RunAfter $RunAfter -Parameters @{
        dataset = "$($AutomationRunHistorySiteUrl)"
        table = "$($AutomationRunHistoryListId)"
        'item/Title' = "@concat('$Function ', utcNow())"
        'item/RunKey' = "@concat('BRMS-', guid())"
        'item/AutomationFunction' = $Function
        'item/FlowIdentity' = $FlowName
        'item/StartTime' = "@triggerOutputs()?['headers']?['x-ms-workflow-run-start-time']"
        'item/EndTime' = '@utcNow()'
        'item/ResourceMapVersion' = 'resource-map-v3'
        'item/ProcessedCount' = $ProcessedExpression
        'item/SuccessCount' = $SuccessExpression
        'item/FailureCount' = $FailureExpression
        'item/RunResult' = @{ Value = $ResultExpression }
        'item/FailedReferences' = $FailedReferencesExpression
        'item/SanitizedErrors' = $SanitizedErrorsExpression
    }
}

function New-RefreshWorkflow {
    $flowName = 'BRMS - GCT - Review Schedule Refresh'
    $forEachActions = [ordered]@{
        Reread_current_document = New-OpenApiAction -OperationId 'GetItem' -RunAfter @{} -Parameters @{
            dataset = "$($RegisterSiteUrl)"
            table = "$($RegisterListId)"
            id = "@items('For_each_active_document')?['ID']"
        }
        Check_eligibility = [ordered]@{
            runAfter = @{ Reread_current_document = @('Succeeded') }
            type = 'If'
            expression = "@or(not(equals(outputs('Reread_current_document')?['body/Active'],true)),not(equals(string(outputs('Reread_current_document')?['body/Modified']),string(items('For_each_active_document')?['Modified']))))"
            actions = [ordered]@{
                Append_skipped_eligibility = New-AppendArray -Name 'SkippedReferences' -Value "@concat('id=',string(items('For_each_active_document')?['ID']),' reason=eligibility-or-modified-changed')" -RunAfter @{}
            }
            else = [ordered]@{
                actions = [ordered]@{
                    Compose_review_frequency = New-Compose -Inputs "@coalesce(outputs('Reread_current_document')?['body/ReviewFrequency']?['Value'], outputs('Reread_current_document')?['body/ReviewFrequency'])"
                    Compose_months_to_add = New-Compose -RunAfter @{ Compose_review_frequency = @('Succeeded') } -Inputs "@int(coalesce(outputs('Parse_review_rules')?['calendarMonthsByFrequency']?[outputs('Compose_review_frequency')],0))"
                    Compose_next_due = New-Compose -RunAfter @{ Compose_months_to_add = @('Succeeded') } -Inputs "@if(or(empty(outputs('Reread_current_document')?['body/LastReviewedDate']),equals(outputs('Compose_months_to_add'),0)),null,formatDateTime(addToTime(outputs('Reread_current_document')?['body/LastReviewedDate'],outputs('Compose_months_to_add'),'Month'),'yyyy-MM-dd'))"
                    Compose_today_local = New-Compose -RunAfter @{ Compose_next_due = @('Succeeded') } -Inputs "@formatDateTime(convertTimeZone(utcNow(),'UTC',$($BusinessTimeZone)),'yyyy-MM-dd')"
                    Compose_days_to_review = New-Compose -RunAfter @{ Compose_today_local = @('Succeeded') } -Inputs "@if(empty(outputs('Compose_next_due')),null,div(sub(ticks(outputs('Compose_next_due')),ticks(outputs('Compose_today_local'))),864000000000))"
                    Compose_status = New-Compose -RunAfter @{ Compose_days_to_review = @('Succeeded') } -Inputs "@if(empty(outputs('Compose_next_due')),'Not Set',if(less(int(outputs('Compose_days_to_review')),0),'Overdue',if(lessOrEquals(int(outputs('Compose_days_to_review')),int(coalesce(outputs('Parse_review_rules')?['dueSoonMaximumDays'],30))),'Due Soon','Current')))"
                    Update_schedule_fields = New-OpenApiAction -OperationId 'PatchItem' -RunAfter @{ Compose_status = @('Succeeded') } -Parameters @{
                        dataset = "$($RegisterSiteUrl)"
                        table = "$($RegisterListId)"
                        id = "@items('For_each_active_document')?['ID']"
                        'item/NextReviewDue' = "@outputs('Compose_next_due')"
                        'item/DaysToReview' = "@outputs('Compose_days_to_review')"
                        'item/Status' = @{ Value = "@outputs('Compose_status')" }
                    }
                    Increment_success = New-IncrementVariable -Name 'SuccessCount' -Value 1 -RunAfter @{ Update_schedule_fields = @('Succeeded') }
                    Record_update_failure = New-AppendArray -Name 'FailedReferences' -Value "@concat('id=',string(items('For_each_active_document')?['ID']),' reason=patch-failed')" -RunAfter @{ Update_schedule_fields = @('Failed','TimedOut','Skipped') }
                    Record_update_error = New-AppendArray -Name 'SanitizedErrors' -Value "@concat('id=',string(items('For_each_active_document')?['ID']),' status=',coalesce(actions('Update_schedule_fields')?['status'],'Unknown'))" -RunAfter @{ Update_schedule_fields = @('Failed','TimedOut','Skipped') }
                    Increment_failure = New-IncrementVariable -Name 'FailureCount' -Value 1 -RunAfter @{ Update_schedule_fields = @('Failed','TimedOut','Skipped') }
                }
            }
        }
        Record_reread_failure = New-AppendArray -Name 'FailedReferences' -Value "@concat('id=',string(items('For_each_active_document')?['ID']),' reason=reread-failed')" -RunAfter @{ Reread_current_document = @('Failed','TimedOut','Skipped') }
        Record_reread_error = New-AppendArray -Name 'SanitizedErrors' -Value "@concat('id=',string(items('For_each_active_document')?['ID']),' status=',coalesce(actions('Reread_current_document')?['status'],'Unknown'))" -RunAfter @{ Reread_current_document = @('Failed','TimedOut','Skipped') }
        Increment_failure_reread = New-IncrementVariable -Name 'FailureCount' -Value 1 -RunAfter @{ Reread_current_document = @('Failed','TimedOut','Skipped') }
    }
    $actions = [ordered]@{
        Init_success_count = New-InitVariable -Name 'SuccessCount' -Type 'Integer' -Value 0
        Init_failure_count = New-InitVariable -Name 'FailureCount' -Type 'Integer' -Value 0 -RunAfter @{ Init_success_count = @('Succeeded') }
        Init_failed_references = New-InitVariable -Name 'FailedReferences' -Type 'Array' -Value @() -RunAfter @{ Init_failure_count = @('Succeeded') }
        Init_sanitized_errors = New-InitVariable -Name 'SanitizedErrors' -Type 'Array' -Value @() -RunAfter @{ Init_failed_references = @('Succeeded') }
        Init_skipped_references = New-InitVariable -Name 'SkippedReferences' -Type 'Array' -Value @() -RunAfter @{ Init_sanitized_errors = @('Succeeded') }
    }
    Add-ConfigurationBootstrap -Actions $actions -LastRunAfter 'Init_skipped_references'
    $actions['Get_configuration'].runAfter = @{ Init_skipped_references = @('Succeeded') }
    $actions['Get_active_documents'] = New-OpenApiAction -OperationId 'GetItems' -RunAfter @{ Parse_notification_settings = @('Succeeded') } -Parameters @{
        dataset = "$($RegisterSiteUrl)"
        table = "$($RegisterListId)"
        '$filter' = 'Active eq 1'
        '$top' = 5000
    } -Paginate
    $actions['For_each_active_document'] = [ordered]@{
        runAfter = @{ Get_active_documents = @('Succeeded') }
        type = 'Foreach'
        foreach = "@outputs('Get_active_documents')?['body/value']"
        runtimeConfiguration = @{ concurrency = @{ repetitions = 1 } }
        actions = $forEachActions
    }
    $actions['Compose_run_result'] = New-Compose -RunAfter @{ For_each_active_document = @('Succeeded','Failed','Skipped','TimedOut') } -Inputs "@if(greater(variables('FailureCount'),0),'SucceededWithWarnings','Succeeded')"
    $actions['Record_refresh_run'] = New-RunHistoryPost -Function 'Review Schedule Refresh' -FlowName $flowName -RunAfter @{ Compose_run_result = @('Succeeded') } -ResultExpression "@outputs('Compose_run_result')" -ProcessedExpression "@length(outputs('Get_active_documents')?['body/value'])" -SuccessExpression "@variables('SuccessCount')" -FailureExpression "@variables('FailureCount')" -FailedReferencesExpression "@join(variables('FailedReferences'),'; ')" -SanitizedErrorsExpression "@join(variables('SanitizedErrors'),'; ')"
    @{
        Id = '11111111-1111-4111-8111-111111111111'
        Name = $flowName
        ClientData = New-ClientData -Triggers (New-RecurrenceTrigger 6) -Actions $actions
    }
}

function New-ReminderWorkflow {
    $flowName = 'BRMS - GCT - Review Reminders'
    $forEachActions = [ordered]@{
        Reread_current_document = New-OpenApiAction -OperationId 'GetItem' -RunAfter @{} -Parameters @{
            dataset = "$($RegisterSiteUrl)"
            table = "$($RegisterListId)"
            id = "@items('For_each_due_document')?['ID']"
        }
        Recheck_eligibility = [ordered]@{
            runAfter = @{ Reread_current_document = @('Succeeded') }
            type = 'If'
            expression = "@and(equals(outputs('Reread_current_document')?['body/Active'],true),or(equals(coalesce(outputs('Reread_current_document')?['body/Status']?['Value'],outputs('Reread_current_document')?['body/Status']),'Due Soon'),equals(coalesce(outputs('Reread_current_document')?['body/Status']?['Value'],outputs('Reread_current_document')?['body/Status']),'Overdue')))"
            actions = [ordered]@{
                Compose_review_cycle = New-Compose -Inputs "@formatDateTime(outputs('Reread_current_document')?['body/NextReviewDue'],'yyyy-MM-dd')"
                Compose_intended_recipient = New-Compose -RunAfter @{ Compose_review_cycle = @('Succeeded') } -Inputs "@coalesce(outputs('Reread_current_document')?['body/Owner']?['Email'], outputs('Reread_current_document')?['body/Reviewer']?['Email'], 'unresolved-recipient')"
                Compose_notification_key = New-Compose -RunAfter @{ Compose_intended_recipient = @('Succeeded') } -Inputs "@concat('BRMS','|',$($RegisterListId),'|',items('For_each_due_document')?['ID'],'|',outputs('Compose_review_cycle'),'|',coalesce(outputs('Reread_current_document')?['body/Status']?['Value'],outputs('Reread_current_document')?['body/Status']),'|',outputs('Compose_intended_recipient'))"
                Find_existing_notification = New-OpenApiAction -OperationId 'GetItems' -RunAfter @{ Compose_notification_key = @('Succeeded') } -Parameters @{
                    dataset = "$($NotificationHistorySiteUrl)"
                    table = "$($NotificationHistoryListId)"
                    '$filter' = "NotificationKey eq '@{replace(outputs('Compose_notification_key'),'''','''''')}'"
                    '$top' = 1
                }
                Attempt_or_suppress = [ordered]@{
                    runAfter = @{ Find_existing_notification = @('Succeeded') }
                    type = 'If'
                    expression = "@equals(length(outputs('Find_existing_notification')?['body/value']),0)"
                    actions = [ordered]@{
                        Try_create_preview_notification = [ordered]@{
                            runAfter = @{}
                            type = 'Scope'
                            actions = [ordered]@{
                                Create_preview_notification = New-OpenApiAction -OperationId 'PostItem' -Parameters @{
                                    dataset = "$($NotificationHistorySiteUrl)"
                                    table = "$($NotificationHistoryListId)"
                                    'item/Title' = "@outputs('Compose_notification_key')"
                                    'item/NotificationKey' = "@outputs('Compose_notification_key')"
                                    'item/RegisterItemIdentity' = "@string(items('For_each_due_document')?['ID'])"
                                    'item/ReviewCycleDueDate' = "@outputs('Compose_review_cycle')"
                                    'item/RuleThreshold' = "@coalesce(outputs('Reread_current_document')?['body/Status']?['Value'],outputs('Reread_current_document')?['body/Status'])"
                                    'item/IntendedRecipient' = "@outputs('Compose_intended_recipient')"
                                    'item/OutcomeState' = @{ Value = "@if(equals(coalesce(outputs('Parse_notification_settings')?['mode'],'preview'),'preview'),'Preview','Preview')" }
                                    'item/AttemptTime' = '@utcNow()'
                                    'item/SafeRunDetails' = "@concat('Preview only; no outbound send. Document=',outputs('Reread_current_document')?['body/Title'],'; Due=',outputs('Compose_review_cycle'),'; Status=',coalesce(outputs('Reread_current_document')?['body/Status']?['Value'],outputs('Reread_current_document')?['body/Status']))"
                                }
                            }
                        }
                        Increment_preview_success = New-IncrementVariable -Name 'SuccessCount' -Value 1 -RunAfter @{ Try_create_preview_notification = @('Succeeded') }
                        Recover_duplicate_conflict = [ordered]@{
                            runAfter = @{ Try_create_preview_notification = @('Failed','TimedOut') }
                            type = 'Scope'
                            actions = [ordered]@{
                                Requery_notification_key = New-OpenApiAction -OperationId 'GetItems' -Parameters @{
                                    dataset = "$($NotificationHistorySiteUrl)"
                                    table = "$($NotificationHistoryListId)"
                                    '$filter' = "NotificationKey eq '@{replace(outputs('Compose_notification_key'),'''','''''')}'"
                                    '$top' = 1
                                }
                                Handle_requery = [ordered]@{
                                    runAfter = @{ Requery_notification_key = @('Succeeded') }
                                    type = 'If'
                                    expression = "@greater(length(outputs('Requery_notification_key')?['body/value']),0)"
                                    actions = [ordered]@{
                                        Append_duplicate_recovered = New-AppendArray -Name 'SkippedReferences' -Value "@concat('key=',outputs('Compose_notification_key'),' reason=duplicate-create-conflict-recovered')" -RunAfter @{}
                                    }
                                    else = [ordered]@{
                                        actions = [ordered]@{
                                            Append_create_failed = New-AppendArray -Name 'FailedReferences' -Value "@concat('key=',outputs('Compose_notification_key'),' reason=create-failed')" -RunAfter @{}
                                            Increment_failure_after_recovery = New-IncrementVariable -Name 'FailureCount' -Value 1 -RunAfter @{ Append_create_failed = @('Succeeded') }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else = [ordered]@{
                        actions = [ordered]@{
                            Suppressed_duplicate = New-AppendArray -Name 'SkippedReferences' -Value "@concat('key=',outputs('Compose_notification_key'),' reason=duplicate-suppressed')" -RunAfter @{}
                        }
                    }
                }
            }
            else = [ordered]@{
                actions = [ordered]@{
                    Append_ineligible_skip = New-AppendArray -Name 'SkippedReferences' -Value "@concat('id=',string(items('For_each_due_document')?['ID']),' reason=ineligible-on-reread')" -RunAfter @{}
                }
            }
        }
    }
    $actions = [ordered]@{
        Init_success_count = New-InitVariable -Name 'SuccessCount' -Type 'Integer' -Value 0
        Init_failure_count = New-InitVariable -Name 'FailureCount' -Type 'Integer' -Value 0 -RunAfter @{ Init_success_count = @('Succeeded') }
        Init_failed_references = New-InitVariable -Name 'FailedReferences' -Type 'Array' -Value @() -RunAfter @{ Init_failure_count = @('Succeeded') }
        Init_sanitized_errors = New-InitVariable -Name 'SanitizedErrors' -Type 'Array' -Value @() -RunAfter @{ Init_failed_references = @('Succeeded') }
        Init_skipped_references = New-InitVariable -Name 'SkippedReferences' -Type 'Array' -Value @() -RunAfter @{ Init_sanitized_errors = @('Succeeded') }
    }
    Add-ConfigurationBootstrap -Actions $actions -LastRunAfter 'Init_skipped_references'
    $actions['Get_configuration'].runAfter = @{ Init_skipped_references = @('Succeeded') }
    $actions['Compose_today_boundary'] = New-Compose -RunAfter @{ Parse_notification_settings = @('Succeeded') } -Inputs "@formatDateTime(convertTimeZone(utcNow(),'UTC',$($BusinessTimeZone)),'yyyy-MM-ddT00:00:00Z')"
    $actions['Get_last_successful_refresh'] = New-OpenApiAction -OperationId 'GetItems' -RunAfter @{ Compose_today_boundary = @('Succeeded') } -Parameters @{
        dataset = "$($AutomationRunHistorySiteUrl)"
        table = "$($AutomationRunHistoryListId)"
        '$filter' = "AutomationFunction eq 'Review Schedule Refresh' and (RunResult eq 'Succeeded' or RunResult eq 'SucceededWithWarnings') and StartTime ge datetime'@{outputs('Compose_today_boundary')}'"
        '$top' = 1
        '$orderby' = 'StartTime desc'
    }
    $actions['Require_current_refresh'] = [ordered]@{
        runAfter = @{ Get_last_successful_refresh = @('Succeeded') }
        type = 'If'
        expression = "@equals(length(outputs('Get_last_successful_refresh')?['body/value']),0)"
        actions = [ordered]@{
            Record_refresh_gate_block = New-RunHistoryPost -Function 'Review Reminders' -FlowName $flowName -RunAfter @{} -ResultExpression 'Blocked' -ProcessedExpression '0' -SuccessExpression '0' -FailureExpression '0' -FailedReferencesExpression "'No successful Review Schedule Refresh recorded for today; reminders skipped.'" -SanitizedErrorsExpression "'refresh-gate: blocked'"
            Terminate_no_refresh = New-Terminate -Status 'Cancelled' -Code 'BRMS-REM-001' -Message 'Reminder run skipped: no successful refresh for today.' -RunAfter @{ Record_refresh_gate_block = @('Succeeded') }
        }
        else = [ordered]@{ actions = [ordered]@{} }
    }
    $actions['Get_due_documents'] = New-OpenApiAction -OperationId 'GetItems' -RunAfter @{ Require_current_refresh = @('Succeeded') } -Parameters @{
        dataset = "$($RegisterSiteUrl)"
        table = "$($RegisterListId)"
        '$filter' = "Active eq 1 and (Status eq 'Due Soon' or Status eq 'Overdue')"
        '$top' = 5000
    } -Paginate
    $actions['For_each_due_document'] = [ordered]@{
        runAfter = @{ Get_due_documents = @('Succeeded') }
        type = 'Foreach'
        foreach = "@outputs('Get_due_documents')?['body/value']"
        runtimeConfiguration = @{ concurrency = @{ repetitions = 1 } }
        actions = $forEachActions
    }
    $actions['Compose_run_result'] = New-Compose -RunAfter @{ For_each_due_document = @('Succeeded','Failed','Skipped','TimedOut') } -Inputs "@if(greater(variables('FailureCount'),0),'SucceededWithWarnings','Succeeded')"
    $actions['Record_reminder_run'] = New-RunHistoryPost -Function 'Review Reminders' -FlowName $flowName -RunAfter @{ Compose_run_result = @('Succeeded') } -ResultExpression "@outputs('Compose_run_result')" -ProcessedExpression "@length(outputs('Get_due_documents')?['body/value'])" -SuccessExpression "@variables('SuccessCount')" -FailureExpression "@variables('FailureCount')" -FailedReferencesExpression "@join(variables('FailedReferences'),'; ')" -SanitizedErrorsExpression "@join(variables('SanitizedErrors'),'; ')"
    @{
        Id = '22222222-2222-4222-8222-222222222222'
        Name = $flowName
        ClientData = New-ClientData -Triggers (New-RecurrenceTrigger 7) -Actions $actions
    }
}

function New-SourceMonitorWorkflow {
    $flowName = 'BRMS - GCT - Source Document Monitor'
    $forEachActions = [ordered]@{
        Reread_current_document = New-OpenApiAction -OperationId 'GetItem' -RunAfter @{} -Parameters @{
            dataset = "$($RegisterSiteUrl)"
            table = "$($RegisterListId)"
            id = "@items('For_each_registered_document')?['ID']"
        }
        Check_still_active = [ordered]@{
            runAfter = @{ Reread_current_document = @('Succeeded') }
            type = 'If'
            expression = "@equals(outputs('Reread_current_document')?['body/Active'],true)"
            actions = [ordered]@{
                Compose_document_url = New-Compose -Inputs "@coalesce(outputs('Reread_current_document')?['body/DocumentLink']?['Url'],outputs('Reread_current_document')?['body/DocumentLink'])"
                Filter_matching_source_mapping = [ordered]@{
                    runAfter = @{ Compose_document_url = @('Succeeded') }
                    type = 'Query'
                    inputs = [ordered]@{
                        from = "@outputs('Parse_source_library_map')"
                        where = "@startsWith(toLower(outputs('Compose_document_url')),toLower(item()?['matchPrefix']))"
                    }
                }
                Compose_resolved_mapping = New-Compose -RunAfter @{ Filter_matching_source_mapping = @('Succeeded') } -Inputs "@first(body('Filter_matching_source_mapping'))"
                Route_by_mapping = [ordered]@{
                    runAfter = @{ Compose_resolved_mapping = @('Succeeded') }
                    type = 'If'
                    expression = "@empty(outputs('Compose_resolved_mapping'))"
                    actions = [ordered]@{
                        Append_unresolved_source = New-AppendArray -Name 'SkippedReferences' -Value "@concat('id=',string(items('For_each_registered_document')?['ID']),' url=',outputs('Compose_document_url'),' reason=source-not-in-configured-map')" -RunAfter @{}
                    }
                    else = [ordered]@{
                        actions = [ordered]@{
                            Compose_resolved_site = New-Compose -Inputs "@outputs('Compose_resolved_mapping')?['siteUrl']"
                            Compose_resolved_folder = New-Compose -RunAfter @{ Compose_resolved_site = @('Succeeded') } -Inputs "@coalesce(outputs('Compose_resolved_mapping')?['folderServerRelativeUrl'],'')"
                            Compose_document_path = New-Compose -RunAfter @{ Compose_resolved_folder = @('Succeeded') } -Inputs "@replace(decodeUriComponent(uriPath(outputs('Compose_document_url'))),coalesce(outputs('Compose_resolved_mapping')?['siteServerRelativePath'],$($DefaultSourceServerRelativeSitePath.TrimEnd('/'))),'')"
                            Get_source_metadata = New-OpenApiAction -OperationId 'GetFileMetadataByPath' -RunAfter @{ Compose_document_path = @('Succeeded') } -Parameters @{
                                dataset = "@outputs('Compose_resolved_site')"
                                path = "@outputs('Compose_document_path')"
                            }
                            Update_source_modified_date = New-OpenApiAction -OperationId 'PatchItem' -RunAfter @{ Get_source_metadata = @('Succeeded') } -Parameters @{
                                dataset = "$($RegisterSiteUrl)"
                                table = "$($RegisterListId)"
                                id = "@items('For_each_registered_document')?['ID']"
                                'item/SourceModifiedDate' = "@outputs('Get_source_metadata')?['body/LastModified']"
                            }
                            Increment_success = New-IncrementVariable -Name 'SuccessCount' -Value 1 -RunAfter @{ Update_source_modified_date = @('Succeeded') }
                            Record_metadata_failure = New-AppendArray -Name 'FailedReferences' -Value "@concat('id=',string(items('For_each_registered_document')?['ID']),' url=',outputs('Compose_document_url'),' reason=metadata-unavailable')" -RunAfter @{ Get_source_metadata = @('Failed','TimedOut') }
                            Record_metadata_error = New-AppendArray -Name 'SanitizedErrors' -Value "@concat('id=',string(items('For_each_registered_document')?['ID']),' status=',coalesce(actions('Get_source_metadata')?['status'],'Unknown'))" -RunAfter @{ Get_source_metadata = @('Failed','TimedOut') }
                            Increment_failure_metadata = New-IncrementVariable -Name 'FailureCount' -Value 1 -RunAfter @{ Get_source_metadata = @('Failed','TimedOut') }
                            Record_patch_failure = New-AppendArray -Name 'FailedReferences' -Value "@concat('id=',string(items('For_each_registered_document')?['ID']),' reason=patch-failed')" -RunAfter @{ Update_source_modified_date = @('Failed','TimedOut','Skipped') }
                            Increment_failure_patch = New-IncrementVariable -Name 'FailureCount' -Value 1 -RunAfter @{ Update_source_modified_date = @('Failed','TimedOut','Skipped') }
                        }
                    }
                }
            }
            else = [ordered]@{
                actions = [ordered]@{
                    Append_skipped_inactive = New-AppendArray -Name 'SkippedReferences' -Value "@concat('id=',string(items('For_each_registered_document')?['ID']),' reason=inactive-on-reread')" -RunAfter @{}
                }
            }
        }
    }
    $actions = [ordered]@{
        Init_success_count = New-InitVariable -Name 'SuccessCount' -Type 'Integer' -Value 0
        Init_failure_count = New-InitVariable -Name 'FailureCount' -Type 'Integer' -Value 0 -RunAfter @{ Init_success_count = @('Succeeded') }
        Init_failed_references = New-InitVariable -Name 'FailedReferences' -Type 'Array' -Value @() -RunAfter @{ Init_failure_count = @('Succeeded') }
        Init_sanitized_errors = New-InitVariable -Name 'SanitizedErrors' -Type 'Array' -Value @() -RunAfter @{ Init_failed_references = @('Succeeded') }
        Init_skipped_references = New-InitVariable -Name 'SkippedReferences' -Type 'Array' -Value @() -RunAfter @{ Init_sanitized_errors = @('Succeeded') }
    }
    Add-ConfigurationBootstrap -Actions $actions -LastRunAfter 'Init_skipped_references' -IncludeSourceLibraryMap
    $actions['Get_configuration'].runAfter = @{ Init_skipped_references = @('Succeeded') }
    $actions['Get_registered_documents'] = New-OpenApiAction -OperationId 'GetItems' -RunAfter @{ Parse_source_library_map = @('Succeeded') } -Parameters @{
        dataset = "$($RegisterSiteUrl)"
        table = "$($RegisterListId)"
        '$filter' = 'Active eq 1'
        '$top' = 5000
    } -Paginate
    $actions['For_each_registered_document'] = [ordered]@{
        runAfter = @{ Get_registered_documents = @('Succeeded') }
        type = 'Foreach'
        foreach = "@outputs('Get_registered_documents')?['body/value']"
        runtimeConfiguration = @{ concurrency = @{ repetitions = 1 } }
        actions = $forEachActions
    }
    $actions['Compose_run_result'] = New-Compose -RunAfter @{ For_each_registered_document = @('Succeeded','Failed','Skipped','TimedOut') } -Inputs "@if(greater(variables('FailureCount'),0),'SucceededWithWarnings','Succeeded')"
    $actions['Record_source_monitor_run'] = New-RunHistoryPost -Function 'Source Document Monitor' -FlowName $flowName -RunAfter @{ Compose_run_result = @('Succeeded') } -ResultExpression "@outputs('Compose_run_result')" -ProcessedExpression "@length(outputs('Get_registered_documents')?['body/value'])" -SuccessExpression "@variables('SuccessCount')" -FailureExpression "@variables('FailureCount')" -FailedReferencesExpression "@join(variables('FailedReferences'),'; ')" -SanitizedErrorsExpression "@join(variables('SanitizedErrors'),'; ')"
    @{
        Id = '33333333-3333-4333-8333-333333333333'
        Name = $flowName
        ClientData = New-ClientData -Triggers (New-RecurrenceTrigger 8) -Actions $actions
    }
}

New-Item -ItemType Directory -Force -Path (Join-Path $OutputDirectory 'Workflows') | Out-Null
$workflows = @((New-RefreshWorkflow), (New-ReminderWorkflow), (New-SourceMonitorWorkflow))

foreach ($workflow in $workflows) {
    $safeName = ($workflow.Name -replace '[^A-Za-z0-9]+', '')
    $workflow.ClientData | ConvertTo-Json -Depth 100 |
        Set-Content -LiteralPath (Join-Path $OutputDirectory "Workflows\$safeName-$($workflow.Id).json") -Encoding UTF8
}

@'
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="xml" ContentType="application/xml" />
  <Default Extension="json" ContentType="application/json" />
</Types>
'@ | Set-Content -LiteralPath (Join-Path $OutputDirectory '[Content_Types].xml') -Encoding UTF8

$rootComponents = ($workflows | ForEach-Object { "      <RootComponent type=""29"" id=""{$($_.Id)}"" behavior=""0"" />" }) -join [Environment]::NewLine
$workflowXml = ($workflows | ForEach-Object {
    $safeName = ($_.Name -replace '[^A-Za-z0-9]+', '')
    @"
    <Workflow WorkflowId="{$($_.Id)}" Name="$($_.Name)">
      <JsonFileName>/Workflows/$safeName-$($_.Id).json</JsonFileName>
      <Type>1</Type><Subprocess>0</Subprocess><Category>5</Category><Mode>0</Mode><Scope>4</Scope>
      <OnDemand>0</OnDemand><TriggerOnCreate>0</TriggerOnCreate><TriggerOnDelete>0</TriggerOnDelete>
      <AsyncAutodelete>0</AsyncAutodelete><SyncWorkflowLogOnFailure>0</SyncWorkflowLogOnFailure>
      <StateCode>0</StateCode><StatusCode>1</StatusCode><RunAs>1</RunAs><IsTransacted>1</IsTransacted>
      <IntroducedVersion>1.0</IntroducedVersion><IsCustomizable>1</IsCustomizable>
      <IsCustomProcessingStepAllowedForOtherPublishers>1</IsCustomProcessingStepAllowedForOtherPublishers>
      <ModernFlowType>1</ModernFlowType><PrimaryEntity>none</PrimaryEntity>
      <LocalizedNames><LocalizedName languagecode="1033" description="$($_.Name)" /></LocalizedNames>
    </Workflow>
"@
}) -join [Environment]::NewLine

@"
<ImportExportXml version="9.2.26082.162" SolutionPackageVersion="9.2" languagecode="1033" generatedBy="Scout" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" OrganizationVersion="9.2.26082.162" OrganizationSchemaType="Standard" CRMServerServiceabilityVersion="9.2.26082.00162">
  <SolutionManifest>
    <UniqueName>$SolutionUniqueName</UniqueName>
    <LocalizedNames><LocalizedName description="$SolutionDisplayName" languagecode="1033" /></LocalizedNames>
    <Descriptions />
    <Version>$SolutionVersion</Version>
    <Managed>0</Managed>
    <Publisher><UniqueName>$PublisherUniqueName</UniqueName><LocalizedNames><LocalizedName description="$PublisherDisplayName" languagecode="1033" /></LocalizedNames><Descriptions /><CustomizationPrefix>$PublisherPrefix</CustomizationPrefix><CustomizationOptionValuePrefix>88894</CustomizationOptionValuePrefix><Addresses /></Publisher>
    <RootComponents>
$rootComponents
    </RootComponents>
    <MissingDependencies />
  </SolutionManifest>
</ImportExportXml>
"@ | Set-Content -LiteralPath (Join-Path $OutputDirectory 'solution.xml') -Encoding UTF8

@"
<ImportExportXml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" OrganizationVersion="9.2.26082.162" OrganizationSchemaType="Standard" CRMServerServiceabilityVersion="9.2.26082.162">
  <Entities></Entities><Roles></Roles>
  <Workflows>
$workflowXml
  </Workflows>
  <FieldSecurityProfiles></FieldSecurityProfiles><Templates /><EntityMaps /><EntityRelationships /><OrganizationSettings /><optionsets /><CustomControls /><EntityDataProviders />
  <connectionreferences><connectionreference connectionreferencelogicalname="$ConnectionReferenceLogicalName"><connectionreferencedisplayname>BRMS SharePoint</connectionreferencedisplayname><connectorid>/providers/Microsoft.PowerApps/apis/shared_sharepointonline</connectorid><iscustomizable>1</iscustomizable><promptingbehavior>0</promptingbehavior><statecode>0</statecode><statuscode>1</statuscode></connectionreference></connectionreferences>
  <Languages><Language>1033</Language></Languages>
</ImportExportXml>
"@ | Set-Content -LiteralPath (Join-Path $OutputDirectory 'customizations.xml') -Encoding UTF8

$zipPath = Join-Path $OutputDirectory "$SolutionUniqueName.zip"
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -LiteralPath (Join-Path $OutputDirectory '[Content_Types].xml'), (Join-Path $OutputDirectory 'customizations.xml'), (Join-Path $OutputDirectory 'solution.xml'), (Join-Path $OutputDirectory 'Workflows') -DestinationPath $zipPath
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Created $zipPath"
Write-Host "SHA256 $hash"
Write-Host "Version $SolutionVersion"

