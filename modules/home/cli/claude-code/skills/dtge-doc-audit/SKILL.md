---
name: dtge-doc-audit
description: Audit DHF document inventory and coverage against DCA requirements
---

# Document Audit Service

Audit medical device Design History File (DHF) document inventory and coverage against DCA (Design Compliance Analysis) requirements.

## Overview

The document audit service:
1. Discovers existing documents in the project
2. Compares against DCA requirements (or generates DCA if none exists)
3. Identifies missing, incomplete, or outdated documentation
4. Prioritizes gaps by regulatory severity
5. Generates actionable gap reports

## Usage

```
/dtge-doc-audit <project-path>                    # Full document audit
/dtge-doc-audit <project-path> --domain usability # Audit specific domain
/dtge-doc-audit <project-path> --quick            # Quick summary only
/dtge-doc-audit <project-path> --report           # Generate formal report
```

## Workflow

### Phase 1: Document Discovery (Programmatic)

Scan project directory for DHF documents:

```bash
# File patterns to discover
**/*.docx, **/*.odt, **/*.pdf, **/*.md

# Extract metadata from filenames
# Pattern: [prefix] DHFD-XX Title RXX ECRXXX (date).ext
```

**Extract from each document:**
- Document ID (DHFD-xx, QP-xx, QA-xx)
- Title
- Revision number
- ECR reference
- Date
- File path

**Update registry:** `<project>/registry.json`
Schema: `~/Documents/DTGE/Work/workflow/schemas/registry.schema.json`

### Phase 2: DCA Verification

Check if DCA exists for project:
- If yes: Load `<project>/dca.json`
- If no: Prompt to run `/dtge-generate-dca` first or generate basic DCA

### Phase 3: Document Analysis (Hybrid)

For each document:

1. **[Code] Extract text** via LibreOffice MCP tools:
   ```
   libreoffice/read_document_text
   libreoffice/get_document_info
   ```

2. **[Code] Parse document structure:**
   - Section headings
   - Trace IDs (SYS-xxx, SRS-xxx, HZ-xx, SR-xx, C-xx)
   - Standard references

3. **[LLM] Map to DCA requirements:**
   - Which DCA items does this document address?
   - Is the coverage complete or partial?
   - Are there evidence gaps?

### Phase 4: Gap Identification (LLM)

Compare DCA requirements against document registry:

**Gap Types:**
| Type | Description | Example |
|------|-------------|---------|
| `missing_document` | Required document doesn't exist | No Use Specification |
| `incomplete_coverage` | Document exists but doesn't fully address requirement | FMEA missing cybersecurity hazards |
| `outdated_reference` | Document references old standard version | ISO 14971:2007 instead of 2019 |
| `evidence_gap` | Document exists but lacks required evidence | Missing summative evaluation data |
| `process_gap` | Required process not documented | No vulnerability management plan |

**Categorize by Domain:**
- Usability (IEC 62366-1)
- Cybersecurity (FDA 2023 Guidance)
- Risk Management (ISO 14971)
- Software (IEC 62304)
- Hardware/Electrical Safety (IEC 60601-1)
- Labeling (IFU requirements)

**Assign Severity:**
| Severity | Criteria |
|----------|----------|
| `critical` | Required for regulatory submission, no pathway without it |
| `high` | Strong expectation from FDA/notified body, may delay approval |
| `medium` | Expected documentation, strengthens submission |
| `low` | Best practice, nice to have |

### Phase 5: Output Generation (Hybrid)

**Update gaps.json:** `<project>/gaps.json`
Schema: `~/Documents/DTGE/Work/workflow/schemas/gaps.schema.json`

**Generate Gap Report:** Based on template from existing gap assessments

## Gap Report Template

```markdown
# Gap Assessment - {Project Name}

## 1. Purpose
Brief description of assessment scope and objectives.

## 2. Design Changes Under Assessment
If applicable, list ECRs and changes being evaluated.

## 3. Standards Evolution
Table of standards changes since predicate/last assessment.

## 4. Gap Assessment by Domain

### 4.1 Usability Engineering (IEC 62366-1)
#### Current State
#### Gap Analysis Table
| Requirement | Current Evidence | Gap Status | Priority |
#### Recommendations

### 4.2 Cybersecurity (FDA 2023 Guidance)
[Same structure]

### 4.3 Risk Management (ISO 14971:2019)
[Same structure]

### 4.4 Software Documentation (IEC 62304)
[Same structure]

### 4.5 Hardware Validation
[Same structure]

### 4.6 Labeling
[Same structure]

## 5. Summary and Prioritization

### 5.1 High Priority Gaps
| Gap ID | Domain | Description | Remediation |

### 5.2 Medium Priority Gaps
[Same table structure]

### 5.3 Lower Priority Gaps
[Same table structure]

## 6. Recommended Action Plan
Phased remediation approach.

## 7. Document References
| Document ID | Title | Relevance |

## 8. Revision History
```

## Integration

### From DCA
Document audit uses DCA as the "should have" baseline.

### To Documentation Service
Gaps feed into `/dtge-create-dhf` for remediation document generation.

### To Project Management
Gaps can trigger ECR creation via `/dtge-ecr-manager`.

## Example Output

```
Document Audit Summary - Higi Green Special 510(k)

Documents Scanned: 47
DCA Requirements: 87

Coverage:
  Covered:    62 (71%)
  Partial:     8 (9%)
  Gap:        17 (20%)

Gaps by Severity:
  Critical:   4  (GAP-01, GAP-04, GAP-05, GAP-06)
  High:       5  (GAP-02, GAP-03, GAP-07, GAP-08, GAP-09)
  Medium:     6  (GAP-10 through GAP-15)
  Low:        2  (GAP-16, GAP-17)

Gaps by Domain:
  Usability:      4
  Cybersecurity:  4
  Risk Mgmt:      3
  Software:       4
  Hardware:       1
  Labeling:       1

Run `/dtge-doc-audit --report` for full report.
```

## Reference Documents

- Template: `Work/Clients/Qualira/Higi/special_510k/11-Gap_Assessment/Special_510k_Gap_Assessment.md`
- Existing traceability script: `Work/Clients/Qualira/Higi/scripts/build_traceability_matrix.py`
