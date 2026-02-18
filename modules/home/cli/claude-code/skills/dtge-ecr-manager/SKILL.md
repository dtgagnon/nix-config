---
name: dtge-ecr-manager
description: Create and manage Engineering Change Requests (ECRs) for medical device projects
---

# ECR Management Service

Create, track, and coordinate Engineering Change Requests (ECRs) for medical device design history files.

## Overview

The ECR Manager service:
1. Creates new ECR packages with proper numbering
2. Tracks ECR status through approval workflow
3. Links changes to affected documents
4. Coordinates document reviews
5. Triggers re-assessment when changes affect compliance

## Usage

```
/dtge-ecr-manager create <project-path>               # Create new ECR
/dtge-ecr-manager status <project-path>               # Show ECR status summary
/dtge-ecr-manager status <project-path> ECR149        # Show specific ECR details
/dtge-ecr-manager review <project-path> ECR149        # Schedule/coordinate review
/dtge-ecr-manager close <project-path> ECR149         # Close completed ECR
```

## ECR Workflow

```
CREATE → DRAFT → UNDER_REVIEW → APPROVED → IMPLEMENTED → VERIFIED → CLOSED
                     ↓
                 REJECTED → (revise) → UNDER_REVIEW
```

## Create ECR

### Step 1: Get Next ECR Number

Query existing ECRs in project to determine next number:
```bash
# Check 10-Design_Changes/ folders for existing ECRs
# Pattern: ECR{number}_{description}/
```

### Step 2: Gather Change Information (LLM-guided)

Collect through conversation:
- **Change Description:** What is being changed?
- **Reason for Change:** Why is this change needed?
- **Affected Documents:** Which documents need revision?
- **Regulatory Impact:** Does this affect:
  - Intended use?
  - Safety/risk profile?
  - Labeling claims?
  - Predicate comparison?
- **Risk Assessment:** Does change require new/updated risk analysis?
- **Verification/Validation:** What testing is needed?

### Step 3: Create ECR Package

**Directory structure:**
```
<project>/10-Design_Changes/ECR{number}_{short_description}/
├── ECR{number}_Form.md           # ECR form
├── ECR{number}_Impact_Assessment.md
├── affected_documents/           # Documents to be revised
├── verification/                 # Verification records
└── approval_records/             # Review and approval evidence
```

### Step 4: Generate ECR Form

```markdown
# Engineering Change Request

## ECR Information
| Field | Value |
|-------|-------|
| ECR Number | ECR{number} |
| Title | {short title} |
| Date Initiated | {date} |
| Initiated By | {name} |
| Status | DRAFT |

## 1. Change Description
{Detailed description of the change}

## 2. Reason for Change
{Justification for the change}

## 3. Affected Items

### 3.1 Affected Documents
| Document ID | Title | Current Rev | Action |
|-------------|-------|-------------|--------|
| DHFD-26 | SRS | R8 | Revise |
| DHFD-28 | Risk Analysis | R6 | Revise |

### 3.2 Affected Hardware/Software
| Component | Description | Change Type |
|-----------|-------------|-------------|

## 4. Regulatory Assessment

### 4.1 Impact on Intended Use
[ ] No impact on intended use
[ ] Affects intended use (describe):

### 4.2 Impact on Safety/Risk
[ ] No new hazards introduced
[ ] New hazards identified (update DHFD-28)
[ ] Existing risk controls affected

### 4.3 Impact on Predicate Comparison
[ ] No impact on substantial equivalence
[ ] Affects comparison (describe):

### 4.4 Standards Affected
| Standard | Impact | Action Required |
|----------|--------|-----------------|

## 5. Verification/Validation Plan
| Activity | Protocol | Status |
|----------|----------|--------|

## 6. Implementation Plan
| Task | Owner | Target Date | Status |
|------|-------|-------------|--------|

## 7. Approvals

### Initiation Approval
| Role | Name | Signature | Date |
|------|------|-----------|------|
| Originator | | | |
| Project Lead | | | |

### Implementation Approval
| Role | Name | Signature | Date |
|------|------|-----------|------|
| Engineering | | | |
| Quality | | | |
| Regulatory | | | |

## 8. Revision History
| Rev | Date | Description | Author |
|-----|------|-------------|--------|
| 01 | {date} | Initial ECR | |
```

## ECR Impact Assessment

When an ECR is created, automatically assess impact on:

### DCA Re-evaluation
- Does the change affect device classification?
- Does the change add new applicable standards?
- Does the change affect existing DCA coverage?

### Gap Analysis Trigger
- If change affects risk profile → re-run gap analysis for Risk Management domain
- If change affects user interface → re-run gap analysis for Usability domain
- If change affects software → re-run gap analysis for Software domain

### Traceability Update
- Identify affected trace chains
- Flag documents needing revision
- Update `registry.json` with ECR association

## Track ECR Status

### Status Summary

```
ECR Status Summary - Higi Green Special 510(k)

Open ECRs: 3
  ECR149 - A&D BP Module Integration [UNDER_REVIEW]
  ECR150 - Cybersecurity Documentation [DRAFT]
  ECR151 - User Manual Updates [IMPLEMENTED]

Recently Closed: 2
  ECR148 - Storm Keypad Update [CLOSED - 2025-12-15]
  ECR147 - UI Resolution Changes [CLOSED - 2025-11-30]

Pending Actions:
  ECR149: Awaiting QA review (due: 2026-02-10)
  ECR150: Impact assessment incomplete
  ECR151: Verification testing in progress
```

### ECR Details

```
ECR149 - A&D BP Module Integration

Status: UNDER_REVIEW
Created: 2026-01-15
Target Close: 2026-03-01

Affected Documents:
  ✓ DHFD-26 SRS R9 (revised)
  ✓ DHFD-27 SDS R10 (revised)
  ◐ DHFD-28 Risk Analysis R7 (in progress)
  ○ DHFD-30 Traceability (pending)
  ○ DHFD-89 User Manual (pending)

Verification Status:
  ✓ Unit testing complete
  ✓ Integration testing complete
  ○ System testing (scheduled: 2026-02-15)
  ○ Usability validation (scheduled: 2026-02-20)

Review Status:
  ✓ Engineering review: Approved (2026-01-28)
  ◐ QA review: In progress
  ○ Regulatory review: Pending
```

## Coordinate Reviews

### Schedule Review

```
/dtge-ecr-manager review Work/Clients/Qualira/Higi/special_510k ECR149

Review Coordination for ECR149:

Required Reviewers:
  - Engineering (risk analysis changes)
  - QA (verification adequacy)
  - Regulatory (impact assessment)

Documents for Review:
  1. DHFD-28 Risk Analysis R7 DRAFT
  2. ECR149_Impact_Assessment.md

Suggested review meeting: [propose date based on calendar]

Draft review request email? [Y/n]
```

### Review Request Template

```markdown
Subject: Review Request - ECR149 A&D BP Module Integration

Review Package: ECR149 A&D BP Module Integration
Review Type: Design Change Review
Target Date: {date}

Documents for Review:
1. [DHFD-28 Risk Analysis R7 DRAFT](link)
2. [ECR149 Impact Assessment](link)

Review Focus:
- Risk analysis completeness for new BP module
- Verification test coverage
- Regulatory impact assessment accuracy

Please provide comments by {date}.

Review Meeting: {date/time} (optional)
```

## Close ECR

### Pre-closure Checklist

```
ECR149 Closure Checklist:

Documents:
  [✓] All affected documents revised and approved
  [✓] Document revisions match ECR scope
  [✓] Registry.json updated

Verification:
  [✓] All verification activities complete
  [✓] All tests passed or deviations documented
  [✓] Verification records filed

Reviews:
  [✓] Engineering review complete
  [✓] QA review complete
  [✓] Regulatory review complete

Traceability:
  [✓] DCA updated if needed
  [✓] Traceability matrix updated
  [✓] Gap status updated if applicable

Ready to close ECR149? [Y/n]
```

## Integration

### With Gap Analysis
ECR creation can trigger gap re-assessment:
- Change to risk profile → Risk Management domain
- Change to UI → Usability domain
- Change to software → Software domain

### With Document Creation
ECR provides context for `/dtge-create-dhf`:
- ECR number for document naming
- Change scope for content generation
- Affected requirements for traceability

### With DCA
Significant changes may require DCA update:
- New standards become applicable
- Device classification changes
- New regulatory requirements identified

## Project Integration

### Higi Project ECR Tracking

ECR packages are stored in:
- `original_510k/10-Design_Changes/` (ECR ≤135)
- `prior_changes/10-Design_Changes/` (ECR 136-148)
- `special_510k/10-Design_Changes/` (ECR 149+)

### Regulatory Tasks Integration

ECRs feed into `regulatory_tasks.json` for project tracking:
```json
{
  "ecr_id": "ECR149",
  "status": "under_review",
  "tasks": [
    {"id": "T-149-01", "description": "Update DHFD-28", "status": "complete"},
    {"id": "T-149-02", "description": "System testing", "status": "in_progress"}
  ],
  "blockers": [],
  "target_date": "2026-03-01"
}
```
