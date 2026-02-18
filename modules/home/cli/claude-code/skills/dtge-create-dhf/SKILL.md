---
name: dtge-create-dhf
description: Generate DHF documents from templates with regulatory traceability
---

# DHF Document Creation Service

Generate Design History File (DHF) and Quality Management System (QMS) documents with proper formatting, traceability, and regulatory compliance.

## Overview

The document creation service:
1. Selects appropriate template based on document type
2. Generates content addressing specific regulatory requirements
3. Maintains traceability to DCA items, hazards, and requirements
4. Applies consistent formatting and naming conventions
5. Updates the document registry

## Usage

```
/dtge-create-dhf <doc-type> <project-path>              # Create new document
/dtge-create-dhf <doc-type> <project-path> --from-gap GAP-01  # Create to remediate gap
/dtge-create-dhf <doc-type> <project-path> --revision   # Create new revision
```

## Document Types

| Type | Template | Typical IDs | V-Model Stage |
|------|----------|-------------|---------------|
| `requirements` | System/Software Requirements | DHFD-44, DHFD-26 | 02-Requirements |
| `design` | Design Specification | DHFD-27 | 03-Design |
| `risk-analysis` | Risk Analysis / FMEA | DHFD-28 | 06-Risk_Management |
| `risk-plan` | Risk Management Plan | DHFD-5 | 01-Planning |
| `verification` | Verification Protocol/Report | DHFD-29, DHFD-30 | 05-Verification |
| `validation` | Validation Protocol/Report | DHFD-31 | 05-Verification |
| `usability-plan` | Usability Engineering Plan | QA-UEP-007-A | 01-Planning |
| `usability-protocol` | Summative Evaluation Protocol | QA-UEP-007-B | 07-Usability |
| `usability-report` | Summative Evaluation Report | QA-UEP-007-C | 07-Usability |
| `user-manual` | User Manual / IFU | DHFD-89 | 08-Labeling |
| `swha` | Software Hazard Analysis | DHFD-PT-23 | 06-Risk_Management |
| `ecr` | Engineering Change Request | ECR-xxx | 10-Design_Changes |
| `dhf-index` | Design History File Index | DHFD-PT-74 | 11-DHF_Index |

## Workflow

### Phase 1: Initialization (Programmatic)

1. **Determine template** based on document type
2. **Get next document ID** from registry (if new)
3. **Create document shell** via LibreOffice MCP:
   ```
   libreoffice/create_document
   ```
4. **Populate header metadata:**
   - Document ID
   - Title
   - Revision number
   - ECR reference
   - Date
   - Author fields

### Phase 2: Content Generation (LLM)

1. **Read context:**
   - Gap details from `gaps.json` (if --from-gap)
   - Related documents for consistency
   - DCA requirements being addressed

2. **Fetch regulatory text:**
   - Use `/dtge-query-ecfr` for FDA regulations
   - Reference Master Standards Database

3. **Generate content addressing:**
   - Standard clause requirements
   - Existing document patterns
   - Traceability references (DCA-xxx, HZ-xx, SR-xx)

### Phase 3: Traceability (Hybrid)

1. **[Code] Extract trace IDs from content:**
   - System requirements: SYS-xxx
   - Software requirements: SRS-xxx
   - Hazards: HZ-xx
   - Causes: C-xx
   - Safety requirements: SR-xx
   - DCA items: DCA-xxx

2. **[Code] Validate against registry:**
   - Verify referenced IDs exist
   - Flag unknown references

3. **[Code] Update traceability matrix:**
   - Extend existing traceability data
   - Link DCA → Document → Verification

### Phase 4: Assembly (Programmatic)

1. **Insert content via LibreOffice MCP:**
   ```
   libreoffice/insert_text_at_position
   libreoffice/format_text
   ```

2. **Apply formatting:**
   - Use `format_document` Python module from Higi scripts
   - Consistent heading styles
   - Proper list formatting
   - Table formatting

3. **Generate filename:**
   ```
   [DTG] DHFD-XX Title RXX ECRXXX YYYY-MM-DD.odt
   ```

4. **Save to appropriate location:**
   - New documents: `<project>/active/drafts/`
   - Released documents: Appropriate V-Model stage folder

### Phase 5: Registry Update (Programmatic)

1. **Update `registry.json`:**
   - Add new document entry
   - Update revision if existing

2. **Update gap status (if --from-gap):**
   - Set `remediation_doc` in `gaps.json`
   - Update gap `status` to `in_progress`

## Document Naming Convention

```
[Prefix] DHFD-{number}[.variant] {Title} R{revision} ECR{number} {date}.{ext}

Examples:
[DTG] DHFD-89.1 Higi Green AAC User Manual R01 ECR155 2026-02-03.docx
[DTG] DHFD-28 Risk Analysis R7 ECR149 2026-01-28.odt
QA-UEP-007-B Summative Evaluation Protocol R2 ECR149 2026-02-01.docx
```

## Template Sections by Document Type

### Risk Analysis (DHFD-28)

1. Purpose
2. Scope
3. Risk Management Process Overview
4. Hazard Identification
5. Risk Estimation Methodology
6. Design FMEA
   - Hazard List (HZ-xx)
   - Cause Analysis (C-xx)
   - Safety Requirements (SR-xx)
7. Risk Evaluation
8. Risk Control Implementation
9. Residual Risk Evaluation
10. Overall Residual Risk Assessment
11. Traceability References

### Usability Engineering Plan (QA-UEP-007-A)

1. Purpose
2. Scope
3. Use Specification
   - Intended Use
   - Intended Users
   - Use Environment
4. User Interface Characteristics
5. Hazard-Related Use Scenarios (HRUS)
6. Critical Tasks
7. Evaluation Plan
8. Traceability to Risk Analysis

### Software Requirements Specification (DHFD-26)

1. Purpose
2. Scope
3. Definitions
4. System Overview
5. Software Requirements
   - Functional Requirements
   - Performance Requirements
   - Interface Requirements
   - Safety Requirements (from SWHA)
6. Traceability to System Requirements
7. Verification Methods

## Integration

### From Gap Analysis
Use `--from-gap` to create documents that directly address identified gaps.

### To Traceability
Documents link to DCA items and feed into `build_traceability_matrix.py`.

### To Project Management
New documents may trigger review scheduling via `/dtge-ecr-manager`.

## Example

```
User: /dtge-create-dhf usability-protocol Work/Clients/Qualira/Higi/special_510k --from-gap GAP-01

Claude: Creating Summative Evaluation Protocol to address GAP-01 (Missing summative usability evaluation)...

Reading context:
- Gap GAP-01: Missing summative evaluation per IEC 62366-1 Clause 5.9
- DCA items: DCA-045, DCA-046, DCA-047
- Related docs: QA-UEP-007-A (Use Specification)

Generating protocol addressing:
- Critical tasks from HRUS (T1-T12)
- Test setup and environment
- Participant criteria (15 representative users)
- Task scenarios with success criteria
- Data collection forms

Created: [DTG] QA-UEP-007-B Summative Evaluation Protocol R1 ECR149 2026-02-03.odt
Location: special_510k/active/drafts/

Updated:
- registry.json: Added QA-UEP-007-B entry
- gaps.json: GAP-01 status → in_progress, remediation_doc → QA-UEP-007-B
```

## Reference

- Format module: `Work/Clients/Qualira/Higi/scripts/format_document/`
- Protocol template: `Work/Clients/Qualira/Higi/scripts/create_protocol_with_content.py`
- Naming convention: `Work/Clients/Qualira/Higi/CLAUDE.md`
