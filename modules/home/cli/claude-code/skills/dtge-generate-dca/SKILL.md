---
name: dtge-generate-dca
description: Create and manage Design Compliance Analysis (DCA) for medical device regulatory projects
---

# Design Compliance Analysis (DCA)

Create, update, and manage Design Compliance Analysis documents for medical device projects. The DCA identifies applicable standards and maps requirements to V-Model deliverables.

## Overview

The DCA is a per-project deliverable that:
1. Identifies which standards apply to THIS device based on classification
2. Pulls applicable clauses from the Master Standards Database
3. Assigns traceability IDs (DCA-001, DCA-002...) to each requirement
4. Maps DCA items to V-Model stage deliverables
5. Becomes the foundation of the full traceability matrix

## Usage

```
/dtge-generate-dca <project-path>              # Create new DCA for project
/dtge-generate-dca <project-path> --update     # Update existing DCA
/dtge-generate-dca <project-path> --status     # Show DCA coverage status
```

## Workflow

### Step 1: Device Characterization (LLM-guided)

Gather device information through conversation:
- FDA device classification (Class I, II, III)
- FDA product code and regulation number
- Intended use statement
- Software involvement (yes/no, safety class if yes)
- Predicate device (for 510(k))
- Use environment and user population

### Step 2: Standards Identification

Based on device characterization, query the Master Standards Database:

**Location:** `~/.claude/data/regulatory-standards/`

**Key files to query:**
- `applicability/device-class-matrix.json` - Standards by FDA class
- `applicability/software-level-matrix.json` - IEC 62304 requirements
- `v-model-mapping/stage-mapping.json` - Clause to deliverable mapping

**Always applicable for Class II/III:**
- 21 CFR 820.30 (Design Controls)
- ISO 14971:2019 (Risk Management)
- IEC 62366-1:2015 (Usability)

**Conditional:**
- IEC 62304 (if software present)
- IEC 60601-1 (if medical electrical equipment)
- Device-specific particulars (e.g., IEC 80601-2-30 for NIBP)

### Step 3: Generate DCA Requirements Matrix

For each applicable standard, pull clauses from:
- `fda/21cfr820/clauses.json`
- `iso/14971-2019/clauses.json`
- `iec/62366-1-2015/clauses.json`
- `iec/62304-2015/clauses.json`

Assign DCA IDs sequentially: DCA-001, DCA-002, DCA-003...

### Step 4: Map to V-Model Stages

Using `v-model-mapping/stage-mapping.json`, assign each DCA item to:
- V-Model stage (00-11)
- Expected deliverable type
- Typical document IDs

### Step 5: Generate Outputs

**DCA JSON file:** `<project>/dtge-generate-dca.json`
Schema: `~/Documents/DTGE/Work/workflow/schemas/dtge-generate-dca.schema.json`

**DCA Markdown document:** `<project>/DCA_Design_Compliance_Analysis.md`

## DCA Document Template

```markdown
# Design Compliance Analysis
## {Project Name} - {Device Description}

### 1. Device Classification
- FDA Classification: {Class}
- FDA Product Code: {Code}
- Software Safety Class: {Class or N/A}
- Predicate Device: {510(k) number}

### 2. Applicable Standards Summary
| Standard | Version | Scope | Rationale |
|----------|---------|-------|-----------|

### 3. Compliance Requirements Matrix
| DCA ID | Standard | Clause | Requirement | V-Model Stage | Expected Deliverable | Status |
|--------|----------|--------|-------------|---------------|---------------------|--------|

### 4. Gap Summary
| DCA ID | Gap Status | Gap ID | Notes |
|--------|------------|--------|-------|

### 5. Revision History
| Rev | Date | Description | Author |
|-----|------|-------------|--------|
```

## Integration with Other Services

### Document Audit
After DCA is created, run `/dtge-doc-audit` to:
- Compare DCA requirements against existing documents
- Identify missing or incomplete coverage
- Generate gap report

### Document Creation
Use `/dtge-create-dhf` to generate documents that satisfy DCA requirements.

### Project Management
Use `/dtge-ecr-manager` to track changes that affect DCA compliance.

## Example: Blood Pressure Device

```
User: /dtge-generate-dca Work/Clients/Qualira/Higi/special_510k

Claude: I'll create a DCA for the Higi project. Let me gather device information...

Device Characterization:
- FDA Class II (Product Code: DXN)
- Predicate: K172739
- Contains software (Class B)
- Medical electrical equipment
- Blood pressure measurement

Applicable Standards:
1. 21 CFR 820.30 - Design Controls
2. ISO 14971:2019 - Risk Management
3. IEC 62366-1:2015 - Usability Engineering
4. IEC 62304:2006+A1:2015 - Software Lifecycle (Class B)
5. IEC 60601-1 - Medical Electrical Safety
6. IEC 80601-2-30 - NIBP Particular Standard
7. ISO 81060-2 - NIBP Validation

Generated DCA with 87 requirements across 11 V-Model stages.
Coverage status: 62 covered, 8 partial, 17 gaps
```

## Notes

- DCA is a living document - update when standards change or device scope changes
- Link DCA items to actual documents as they're created/updated
- Use DCA as input to gap analysis workflow
- DCA traceability chain: DCA-xxx → DHFD-xx → Test Case → Validation
