\# Governance Control Tower Field Schema



\## Core Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Title | Title | Single line of text | Yes | Product / Application / Platform name |

| Department | BU | Choice/Text | No | Business unit or department |

| Cloud | Cloud | Choice | No | Azure, AWS, Other, SaaS, etc. |

| Cloud Account ID | CloudAccountID | Single line of text | No | Subscription/account identifier |



\## Ownership Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Owner | Owner | Person | No | Primary accountable owner |

| Manager | Manager | Person | No | Manager / escalation contact |

| CIO / CTO | CIOCTO | Person | No | Senior leadership contact |



\## RTO Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Scope Status | RTOScopeStatus | Choice | Yes | In-Scope or N/A reason |

| Last RTO Test (Required) | LastRTOTestRequired | Date | No | Last completed RTO test date |

| Next RTO Due | NextRTODue | Date | No | Calculated/updated by flow |

| Days to RTO | DaystoRTO | Number | No | Calculated/updated by flow |

| RTO Status | RTOStatus | Choice | No | Green, Amber, Red, Unknown |



\## Immutable Backup Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Immutable N/A reason | ImmutableN\_x002f\_Areason | Choice | Yes | Applicable or N/A reason |

| Last Immutable Verification (Required) | LastImmutableVerificationRequired | Date | No | Last IMM verification date |

| Next IMM Due | NextIMMDue | Date | No | Calculated/updated by flow |

| Days to IMM | DaystoIMM | Number | No | Calculated/updated by flow |

| IMM Status | IMMStatus | Choice | No | Green, Amber, Red, Unknown |



\## Recovery Playbook Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Playbook N/A Reason | PlaybookN\_x002f\_AReason | Choice | No | Applicable or N/A reason |

| Last Playbook Update (Required) | Last\_x0020\_Playbook\_x0020\_Update | Date | No | Last update date |

| Playbook URL | PlaybookURL | Hyperlink | No | Link to recovery playbook |

| Playbook Status | PlaybookStatus | Choice | No | Current freshness status |

| Playbook Age Days | PlaybookAgeDays | Number | No | Calculated/updated by flow |



\## Blue/Green Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Blue/Green N/A Reason | BlueGreenN\_x002f\_AReason | Choice | No | Applicable or N/A reason |

| Blue-Green Deployment | Blue\_x002d\_GreenDeployment | Choice | No | Yes, No, N/A |

| Last Blue/Green Test | LastBlueGreenTest | Date | No | Last validation date |

| Blue/Green Status | BlueGreenStatus | Choice | No | Green, Amber, Red, Unknown |



\## Evidence Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Evidence Folder URL | EvidenceFolder | Hyperlink | No | Link to evidence folder |

| Evidence Status | EvidenceStatus | Choice | No | Missing, Submitted, Accepted, Needs Review |



\## Exception Fields



| Display Name | Internal Name | Type | Required | Notes |

|---|---|---|---|---|

| Exception ID | ExceptionID | Single line of text | No | Linked EDR exception ID |

| Exception Type | ExceptionType | Choice | No | RTO, IMM, Playbook, Blue/Green |

| Exception Expiry / Review Date | ExceptionExpiryReviewDate | Date | No | Used for lifecycle review |

| Exception Lifecycle Status | ExceptionLifecycleStatus | Choice | No | Active, Expired, Closed, Superseded |

