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
    [string]$PublisherUniqueName = 'Cr115e7',
    [string]$PublisherDisplayName = 'CDS Default Publisher',
    [string]$PublisherPrefix = 'cr1e9',
    [string]$ConnectionReferenceLogicalName = 'cr1e9_BRMSSharePoint'
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

function New-OpenApiAction {
    param(
        [string]$OperationId,
        [hashtable]$Parameters,
        [hashtable]$RunAfter = @{}
    )
    [ordered]@{
        runAfter = $RunAfter
        type = 'OpenApiConnection'
        inputs = [ordered]@{
            parameters = $Parameters
            host = New-Host $OperationId
        }
        runtimeConfiguration = [ordered]@{
            retryPolicy = [ordered]@{
                type = 'exponential'
                interval = 'PT20S'
                count = 3
                minimumInterval = 'PT5S'
                maximumInterval = 'PT2M'
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
                    runtimeSource = 'embedded'
                }
            }
            definition = [ordered]@{
                metadata = @{ defaultToEmbeddedConnections = $true }
                '$schema' = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
                contentVersion = '1.0.0.0'
                parameters = [ordered]@{
                    '$authentication' = @{ defaultValue = @{}; type = 'SecureObject' }
                    '$connections' = @{ defaultValue = @{}; type = 'Object' }
                    brmsRegisterSiteUrl = @{ defaultValue = $RegisterSiteUrl; type = 'String' }
                    brmsRegisterListId = @{ defaultValue = $RegisterListId; type = 'String' }
                    brmsConfigurationSiteUrl = @{ defaultValue = $ConfigurationSiteUrl; type = 'String' }
                    brmsConfigurationListId = @{ defaultValue = $ConfigurationListId; type = 'String' }
                    brmsNotificationHistorySiteUrl = @{ defaultValue = $NotificationHistorySiteUrl; type = 'String' }
                    brmsNotificationHistoryListId = @{ defaultValue = $NotificationHistoryListId; type = 'String' }
                    brmsAutomationRunHistorySiteUrl = @{ defaultValue = $AutomationRunHistorySiteUrl; type = 'String' }
                    brmsAutomationRunHistoryListId = @{ defaultValue = $AutomationRunHistoryListId; type = 'String' }
                    brmsDefaultSourceSiteUrl = @{ defaultValue = $DefaultSourceSiteUrl; type = 'String' }
                    brmsDefaultSourceServerRelativeSitePath = @{ defaultValue = $DefaultSourceServerRelativeSitePath.TrimEnd('/'); type = 'String' }
                    brmsBusinessTimeZone = @{ defaultValue = $BusinessTimeZone; type = 'String' }
                    brmsDeploymentKey = @{ defaultValue = 'BRMS'; type = 'String' }
                }
                triggers = $Triggers
                actions = $Actions
                outputs = @{}
            }
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

function New-RunHistoryAction {
    param(
        [string]$Function,
        [string]$FlowName,
        [hashtable]$RunAfter,
        [string]$ResultExpression,
        [string]$ProcessedExpression,
        [string]$SuccessExpression,
        [string]$FailureExpression,
        [string]$FailedReferences = ''
    )
    New-OpenApiAction -OperationId 'PostItem' -RunAfter $RunAfter -Parameters @{
        dataset = "@parameters('brmsAutomationRunHistorySiteUrl')"
        table = "@parameters('brmsAutomationRunHistoryListId')"
        'item/Title' = "@concat('$Function ', utcNow())"
        'item/RunKey' = "@concat('BRMS-', guid())"
        'item/AutomationFunction' = $Function
        'item/FlowIdentity' = $FlowName
        'item/StartTime' = "@triggerOutputs()?['headers']?['x-ms-workflow-run-start-time']"
        'item/EndTime' = '@utcNow()'
        'item/ResourceMapVersion' = 'resource-map-v2'
        'item/ProcessedCount' = $ProcessedExpression
        'item/SuccessCount' = $SuccessExpression
        'item/FailureCount' = $FailureExpression
        'item/RunResult' = @{ Value = $ResultExpression }
        'item/FailedReferences' = $FailedReferences
        'item/SanitizedErrors' = ''
    }
}

function New-RefreshWorkflow {
    $flowName = 'BRMS - GCT - Review Schedule Refresh'
    $forEachActions = [ordered]@{
        Compose_review_frequency = @{ runAfter = @{}; type = 'Compose'; inputs = "@coalesce(items('For_each_active_document')?['ReviewFrequency']?['Value'], items('For_each_active_document')?['ReviewFrequency'])" }
        Compose_months_to_add = @{ runAfter = @{ Compose_review_frequency = @('Succeeded') }; type = 'Compose'; inputs = "@if(equals(outputs('Compose_review_frequency'),'Monthly'),1,if(equals(outputs('Compose_review_frequency'),'Quarterly'),3,if(equals(outputs('Compose_review_frequency'),'Semi-Annual'),6,if(equals(outputs('Compose_review_frequency'),'Annual'),12,0))))" }
        Compose_next_due = @{ runAfter = @{ Compose_months_to_add = @('Succeeded') }; type = 'Compose'; inputs = "@if(or(empty(items('For_each_active_document')?['LastReviewedDate']),equals(outputs('Compose_months_to_add'),0)),null,formatDateTime(addToTime(items('For_each_active_document')?['LastReviewedDate'],int(outputs('Compose_months_to_add')),'Month'),'yyyy-MM-dd'))" }
        Compose_today_local = @{ runAfter = @{ Compose_next_due = @('Succeeded') }; type = 'Compose'; inputs = "@formatDateTime(convertTimeZone(utcNow(),'UTC',parameters('brmsBusinessTimeZone')),'yyyy-MM-dd')" }
        Compose_days_to_review = @{ runAfter = @{ Compose_today_local = @('Succeeded') }; type = 'Compose'; inputs = "@if(empty(outputs('Compose_next_due')),null,div(sub(ticks(outputs('Compose_next_due')),ticks(outputs('Compose_today_local'))),864000000000))" }
        Compose_status = @{ runAfter = @{ Compose_days_to_review = @('Succeeded') }; type = 'Compose'; inputs = "@if(empty(outputs('Compose_next_due')),'Not Set',if(less(int(outputs('Compose_days_to_review')),0),'Overdue',if(lessOrEquals(int(outputs('Compose_days_to_review')),30),'Due Soon','Current')))" }
        Update_schedule_fields = New-OpenApiAction -OperationId 'PatchItem' -RunAfter @{ Compose_status = @('Succeeded') } -Parameters @{
            dataset = "@parameters('brmsRegisterSiteUrl')"
            table = "@parameters('brmsRegisterListId')"
            id = "@items('For_each_active_document')?['ID']"
            'item/NextReviewDue' = "@outputs('Compose_next_due')"
            'item/DaysToReview' = "@outputs('Compose_days_to_review')"
            'item/Status' = @{ Value = "@outputs('Compose_status')" }
        }
    }
    $actions = [ordered]@{
        Get_active_documents = New-OpenApiAction -OperationId 'GetItems' -Parameters @{
            dataset = "@parameters('brmsRegisterSiteUrl')"
            table = "@parameters('brmsRegisterListId')"
            '$filter' = 'Active eq 1'
            '$top' = 5000
        }
        For_each_active_document = [ordered]@{
            runAfter = @{ Get_active_documents = @('Succeeded') }
            type = 'Foreach'
            foreach = "@outputs('Get_active_documents')?['body/value']"
            runtimeConfiguration = @{ concurrency = @{ repetitions = 1 } }
            actions = $forEachActions
        }
        Record_refresh_run = New-RunHistoryAction -Function 'Review Schedule Refresh' -FlowName $flowName -RunAfter @{ For_each_active_document = @('Succeeded', 'Failed', 'Skipped', 'TimedOut') } -ResultExpression 'SucceededWithWarnings' -ProcessedExpression "@length(outputs('Get_active_documents')?['body/value'])" -SuccessExpression "@length(outputs('Get_active_documents')?['body/value'])" -FailureExpression '0'
    }
    @{
        Id = '11111111-1111-4111-8111-111111111111'
        Name = $flowName
        ClientData = New-ClientData -Triggers (New-RecurrenceTrigger 6) -Actions $actions
    }
}

function New-ReminderWorkflow {
    $flowName = 'BRMS - GCT - Review Reminders'
    $forEachActions = [ordered]@{
        Compose_review_cycle = @{ runAfter = @{}; type = 'Compose'; inputs = "@formatDateTime(items('For_each_due_document')?['NextReviewDue'],'yyyy-MM-dd')" }
        Compose_intended_recipient = @{ runAfter = @{ Compose_review_cycle = @('Succeeded') }; type = 'Compose'; inputs = "@coalesce(items('For_each_due_document')?['Owner']?['Email'], items('For_each_due_document')?['Reviewer']?['Email'], 'unresolved-recipient')" }
        Compose_notification_key = @{ runAfter = @{ Compose_intended_recipient = @('Succeeded') }; type = 'Compose'; inputs = "@concat(parameters('brmsDeploymentKey'),'|',parameters('brmsRegisterListId'),'|',items('For_each_due_document')?['ID'],'|',outputs('Compose_review_cycle'),'|',coalesce(items('For_each_due_document')?['Status']?['Value'],items('For_each_due_document')?['Status']),'|',outputs('Compose_intended_recipient'))" }
        Find_existing_notification = New-OpenApiAction -OperationId 'GetItems' -RunAfter @{ Compose_notification_key = @('Succeeded') } -Parameters @{
            dataset = "@parameters('brmsNotificationHistorySiteUrl')"
            table = "@parameters('brmsNotificationHistoryListId')"
            '$filter' = "NotificationKey eq '@{replace(outputs('Compose_notification_key'),'''','''''')}'"
            '$top' = 1
        }
        Suppress_or_preview = [ordered]@{
            runAfter = @{ Find_existing_notification = @('Succeeded') }
            type = 'If'
            expression = "@equals(length(outputs('Find_existing_notification')?['body/value']),0)"
            actions = [ordered]@{
                Create_preview_notification = New-OpenApiAction -OperationId 'PostItem' -Parameters @{
                    dataset = "@parameters('brmsNotificationHistorySiteUrl')"
                    table = "@parameters('brmsNotificationHistoryListId')"
                    'item/Title' = "@outputs('Compose_notification_key')"
                    'item/NotificationKey' = "@outputs('Compose_notification_key')"
                    'item/RegisterItemIdentity' = "@string(items('For_each_due_document')?['ID'])"
                    'item/ReviewCycleDueDate' = "@outputs('Compose_review_cycle')"
                    'item/RuleThreshold' = "@coalesce(items('For_each_due_document')?['Status']?['Value'],items('For_each_due_document')?['Status'])"
                    'item/IntendedRecipient' = "@outputs('Compose_intended_recipient')"
                    'item/OutcomeState' = @{ Value = 'Preview' }
                    'item/AttemptTime' = '@utcNow()'
                    'item/SafeRunDetails' = "@concat('Preview only; no outbound send. Document=',items('For_each_due_document')?['Title'],'; Due=',outputs('Compose_review_cycle'),'; Status=',coalesce(items('For_each_due_document')?['Status']?['Value'],items('For_each_due_document')?['Status']))"
                }
            }
            else = [ordered]@{
                actions = [ordered]@{
                    Suppressed_duplicate = @{ runAfter = @{}; type = 'Compose'; inputs = 'Duplicate notification suppressed by NotificationKey.' }
                }
            }
        }
    }
    $actions = [ordered]@{
        Get_due_documents = New-OpenApiAction -OperationId 'GetItems' -Parameters @{
            dataset = "@parameters('brmsRegisterSiteUrl')"
            table = "@parameters('brmsRegisterListId')"
            '$filter' = "Active eq 1 and (Status eq 'Due Soon' or Status eq 'Overdue')"
            '$top' = 5000
        }
        For_each_due_document = [ordered]@{
            runAfter = @{ Get_due_documents = @('Succeeded') }
            type = 'Foreach'
            foreach = "@outputs('Get_due_documents')?['body/value']"
            runtimeConfiguration = @{ concurrency = @{ repetitions = 1 } }
            actions = $forEachActions
        }
        Record_reminder_run = New-RunHistoryAction -Function 'Review Reminders' -FlowName $flowName -RunAfter @{ For_each_due_document = @('Succeeded', 'Failed', 'Skipped', 'TimedOut') } -ResultExpression 'SucceededWithWarnings' -ProcessedExpression "@length(outputs('Get_due_documents')?['body/value'])" -SuccessExpression "@length(outputs('Get_due_documents')?['body/value'])" -FailureExpression '0' -FailedReferences 'Outbound notifications disabled; preview records only.'
    }
    @{
        Id = '22222222-2222-4222-8222-222222222222'
        Name = $flowName
        ClientData = New-ClientData -Triggers (New-RecurrenceTrigger 7) -Actions $actions
    }
}

function New-SourceMonitorWorkflow {
    $flowName = 'BRMS - GCT - Source Document Monitor'
    $forEachActions = [ordered]@{
        Compose_document_url = @{ runAfter = @{}; type = 'Compose'; inputs = "@coalesce(items('For_each_registered_document')?['DocumentLink']?['Url'],items('For_each_registered_document')?['DocumentLink'])" }
        Compose_document_site_url = @{ runAfter = @{ Compose_document_url = @('Succeeded') }; type = 'Compose'; inputs = "@if(contains(outputs('Compose_document_url'),'/sites/'),concat(first(split(outputs('Compose_document_url'),'/sites/')),'/sites/',first(skip(split(outputs('Compose_document_url'),'/sites/'),1))),parameters('brmsDefaultSourceSiteUrl'))" }
        Compose_document_path = @{ runAfter = @{ Compose_document_site_url = @('Succeeded') }; type = 'Compose'; inputs = "@replace(decodeUriComponent(uriPath(outputs('Compose_document_url'))),parameters('brmsDefaultSourceServerRelativeSitePath'),'')" }
        Get_source_metadata = New-OpenApiAction -OperationId 'GetFileMetadataByPath' -RunAfter @{ Compose_document_path = @('Succeeded') } -Parameters @{
            dataset = "@outputs('Compose_document_site_url')"
            path = "@outputs('Compose_document_path')"
        }
        Update_source_modified_date = New-OpenApiAction -OperationId 'PatchItem' -RunAfter @{ Get_source_metadata = @('Succeeded') } -Parameters @{
            dataset = "@parameters('brmsRegisterSiteUrl')"
            table = "@parameters('brmsRegisterListId')"
            id = "@items('For_each_registered_document')?['ID']"
            'item/SourceModifiedDate' = "@outputs('Get_source_metadata')?['body/LastModified']"
        }
        Compose_source_observation_failure = @{
            runAfter = @{ Get_source_metadata = @('Failed', 'TimedOut') }
            type = 'Compose'
            inputs = "@concat('Source unresolved or inaccessible for item ',items('For_each_registered_document')?['ID'],'. Governance review fields preserved.')"
        }
    }
    $actions = [ordered]@{
        Get_registered_documents = New-OpenApiAction -OperationId 'GetItems' -Parameters @{
            dataset = "@parameters('brmsRegisterSiteUrl')"
            table = "@parameters('brmsRegisterListId')"
            '$filter' = 'Active eq 1'
            '$top' = 5000
        }
        For_each_registered_document = [ordered]@{
            runAfter = @{ Get_registered_documents = @('Succeeded') }
            type = 'Foreach'
            foreach = "@outputs('Get_registered_documents')?['body/value']"
            runtimeConfiguration = @{ concurrency = @{ repetitions = 1 } }
            actions = $forEachActions
        }
        Record_source_monitor_run = New-RunHistoryAction -Function 'Source Document Monitor' -FlowName $flowName -RunAfter @{ For_each_registered_document = @('Succeeded', 'Failed', 'Skipped', 'TimedOut') } -ResultExpression 'SucceededWithWarnings' -ProcessedExpression "@length(outputs('Get_registered_documents')?['body/value'])" -SuccessExpression "@length(outputs('Get_registered_documents')?['body/value'])" -FailureExpression '0' -FailedReferences 'Per-record inaccessible sources are composed in-run and must be reviewed in run history.'
    }
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
    <Version>1.0.0.2</Version>
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
