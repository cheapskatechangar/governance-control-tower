[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$RegisterListId,

    [Parameter(Mandatory = $true)]
    [string]$NotificationHistoryListId,

    [Parameter(Mandatory = $true)]
    [string]$AutomationRunHistoryListId,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$SolutionUniqueName = 'BRMSGovernanceControlTower',
    [string]$SolutionDisplayName = 'BRMS Governance Control Tower',
    [string]$PublisherUniqueName = 'Cr115e7',
    [string]$PublisherDisplayName = 'CDS Default Publisher',
    [string]$PublisherPrefix = 'cr1e9',
    [string]$ConnectionReferenceLogicalName = 'cr1e9_BRMSSharePoint'
)

$ErrorActionPreference = 'Stop'

foreach ($name in @($SolutionUniqueName, $SolutionDisplayName)) {
    if ($name -match '(?i)\b(?:DEV|PROD)\b') {
        throw 'BRMS solution and flow names must not include DEV or PROD labels.'
    }
}

New-Item -ItemType Directory -Force -Path (Join-Path $OutputDirectory 'Workflows') | Out-Null

$workflows = @(
    @{
        Id = '11111111-1111-4111-8111-111111111111'
        Name = 'BRMS - GCT - Review Schedule Refresh'
        Definition = @{
            triggers = @{
                Recurrence = @{
                    type = 'Recurrence'
                    recurrence = @{
                        frequency = 'Day'
                        interval = 1
                        timeZone = 'Eastern Standard Time'
                        schedule = @{ hours = @('6'); minutes = @(0) }
                    }
                }
            }
            actions = @{
                Get_active_documents = @{
                    runAfter = @{}
                    type = 'OpenApiConnection'
                    inputs = @{
                        parameters = @{
                            dataset = $SiteUrl
                            table = $RegisterListId
                            '$filter' = 'Active eq 1'
                            '$top' = 5000
                        }
                        host = @{
                            apiId = '/providers/Microsoft.PowerApps/apis/shared_sharepointonline'
                            operationId = 'GetItems'
                            connectionName = 'shared_sharepointonline'
                        }
                    }
                }
            }
        }
    },
    @{
        Id = '22222222-2222-4222-8222-222222222222'
        Name = 'BRMS - GCT - Review Reminders'
        Definition = @{
            triggers = @{
                Recurrence = @{
                    type = 'Recurrence'
                    recurrence = @{
                        frequency = 'Day'
                        interval = 1
                        timeZone = 'Eastern Standard Time'
                        schedule = @{ hours = @('7'); minutes = @(0) }
                    }
                }
            }
            actions = @{
                Get_due_documents_for_preview = @{
                    runAfter = @{}
                    type = 'OpenApiConnection'
                    inputs = @{
                        parameters = @{
                            dataset = $SiteUrl
                            table = $RegisterListId
                            '$filter' = "Active eq 1 and (Status eq 'Due Soon' or Status eq 'Overdue')"
                            '$top' = 5000
                        }
                        host = @{
                            apiId = '/providers/Microsoft.PowerApps/apis/shared_sharepointonline'
                            operationId = 'GetItems'
                            connectionName = 'shared_sharepointonline'
                        }
                    }
                }
            }
        }
    },
    @{
        Id = '33333333-3333-4333-8333-333333333333'
        Name = 'BRMS - GCT - Source Document Monitor'
        Definition = @{
            triggers = @{
                Recurrence = @{
                    type = 'Recurrence'
                    recurrence = @{
                        frequency = 'Day'
                        interval = 1
                        timeZone = 'Eastern Standard Time'
                        schedule = @{ hours = @('8'); minutes = @(0) }
                    }
                }
            }
            actions = @{
                Get_registered_documents = @{
                    runAfter = @{}
                    type = 'OpenApiConnection'
                    inputs = @{
                        parameters = @{
                            dataset = $SiteUrl
                            table = $RegisterListId
                            '$filter' = 'Active eq 1'
                            '$top' = 5000
                        }
                        host = @{
                            apiId = '/providers/Microsoft.PowerApps/apis/shared_sharepointonline'
                            operationId = 'GetItems'
                            connectionName = 'shared_sharepointonline'
                        }
                    }
                }
            }
        }
    }
)

foreach ($workflow in $workflows) {
    $clientData = [ordered]@{
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
                parameters = @{
                    '$authentication' = @{ defaultValue = @{}; type = 'SecureObject' }
                    '$connections' = @{ defaultValue = @{}; type = 'Object' }
                }
                triggers = $workflow.Definition.triggers
                actions = $workflow.Definition.actions
                outputs = @{}
            }
        }
    }

    $safeName = ($workflow.Name -replace '[^A-Za-z0-9]+', '')
    $clientData | ConvertTo-Json -Depth 100 |
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
    <Version>1.0.0.1</Version>
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
<ImportExportXml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" OrganizationVersion="9.2.26082.162" OrganizationSchemaType="Standard" CRMServerServiceabilityVersion="9.2.26082.00162">
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
Write-Host "Created $zipPath"
