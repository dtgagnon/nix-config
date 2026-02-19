---
name: dtge-populate-template
description: Populate styled ODT/OTT templates with content while preserving formatting
---

# ODT Template Population

Populate styled ODT/OTT templates with structured content by replacing placeholder text while preserving all paragraph styles, table formatting, heading levels, and document structure.

## Overview

LibreOffice MCP tools (`libreoffice/create_document`, `libreoffice/insert_text_at_position`) can create documents with content but cannot selectively replace text within a pre-styled template while preserving formatting. This skill solves that problem by manipulating the ODT's internal XML (`content.xml`) directly via Python and `lxml`.

The expected input is a **markdown file** containing structured content. The populate script parses the markdown to extract sections, tables, and list items, then maps them onto the template's XML elements. Markdown is the ideal intermediate format because it's trivial to parse, easy to review, and naturally represents the document structure (headings, paragraphs, tables, lists).

**Use this skill when:**
- You have a branded/styled ODT template with placeholder text
- You have structured content (typically as markdown) that needs to be placed into the template
- The template has styled headings, colored tables, separator borders, cover page layouts, or other visual elements that must be preserved

**Do NOT use this skill when:**
- You just need to create a plain document from scratch (use `libreoffice/create_document` instead)
- The document has no special formatting to preserve

## Prerequisites

- Python with `lxml` available in the project's devShell (check `scripts/flake.nix`)
- If `lxml` is not available, add it to the flake's Python packages before proceeding

## Workflow

### Phase 1: Analyze Template

Write a small Python script to dump the template's body elements with indices, tags, styles, and text content. This reveals the exact XML structure needed for targeted replacement.

**Analysis script pattern:**

```python
#!/usr/bin/env python3
"""Dump template structure for analysis."""
import zipfile
from lxml import etree

NS = {
    'text': 'urn:oasis:names:tc:opendocument:xmlns:text:1.0',
    'table': 'urn:oasis:names:tc:opendocument:xmlns:table:1.0',
    'office': 'urn:oasis:names:tc:opendocument:xmlns:office:1.0',
}

def get_full_text(elem):
    parts = []
    if elem.text:
        parts.append(elem.text)
    for child in elem:
        parts.append(get_full_text(child))
        if child.tail:
            parts.append(child.tail)
    return ''.join(parts)

TEMPLATE = '<path-to-template.odt>'

with zipfile.ZipFile(TEMPLATE, 'r') as z:
    root = etree.fromstring(z.read('content.xml'))

body = root.find('.//office:body/office:text', NS)
for i, elem in enumerate(body):
    tag = etree.QName(elem.tag).localname
    style = elem.get('{urn:oasis:names:tc:opendocument:xmlns:text:1.0}style-name', '')
    text = get_full_text(elem).strip()[:80]

    if tag == 'table':
        tname = elem.get('{urn:oasis:names:tc:opendocument:xmlns:table:1.0}name', '')
        rows = elem.findall('.//table:table-row', NS)
        print(f"[{i:3d}] <{tag}> name={tname} rows={len(rows)}")
        for ri, row in enumerate(rows):
            cells = row.findall('table:table-cell', NS)
            cell_texts = [get_full_text(c).strip()[:30] for c in cells]
            print(f"      row[{ri}]: {cell_texts}")
    elif tag == 'h':
        level = elem.get('{urn:oasis:names:tc:opendocument:xmlns:text:1.0}outline-level', '')
        print(f"[{i:3d}] <{tag}> level={level} style={style} | {text}")
    else:
        print(f"[{i:3d}] <{tag}> style={style} | {text}")
```

Run this from the `scripts/` directory. The output tells you:
- Which element index corresponds to which content
- What paragraph styles are used (needed to preserve formatting)
- How tables are structured (header rows vs data rows)
- Where placeholder text appears

### Phase 2: Map Content

Write a markdown file containing all the content that will go into the template. Use a consistent structure that mirrors the template layout so the populate script can parse it predictably.

**Markdown content conventions:**

- Use heading levels (`#`, `##`, `###`, `####`) to delimit major sections
- Use markdown tables (`| col | col |`) for tabular data
- Use numbered/bulleted lists for list items
- Use `**bold**` markers to tag field labels (e.g., `**Severity:** Critical`)
- Use `---` horizontal rules to separate repeating blocks (e.g., between gap findings)
- Keep section headings consistent so the parser can locate content by heading text

Then define the mapping between markdown sections and template elements. Identify three operation types:

1. **Simple text replacement** — A markdown section's body text replaces the text in a `text:p` or `text:h` element at a known index
2. **Table row cloning** — A markdown table's rows are parsed and each row clones a template data row
3. **Paragraph block cloning** — A repeating markdown section (delimited by `---`) clones a group of template elements for each entry

For each placeholder in the template, note:
- Element index (from Phase 1 analysis)
- Operation type (replace, clone row, clone block)
- Which markdown heading/section provides the source content

### Phase 3: Write Populate Script

Using the utility functions below, write a script specific to the template that:
1. Reads and parses the markdown file to extract content
2. Copies the template to produce the output file (template stays pristine)
3. Replaces placeholder content in the output with parsed markdown content

**Script structure:**

```python
#!/usr/bin/env python3
"""Populate <template-name> with content from markdown."""
import zipfile, shutil, copy, re, sys
from lxml import etree

# --- Paths ---
TEMPLATE = '<path-to-template.odt>'     # Pristine template (never modified)
MARKDOWN = '<path-to-content.md>'        # Markdown content source
OUTPUT = '<path-to-output.odt>'          # Populated output file

# --- ODF Namespaces ---
NS = { ... }  # (see utility functions below)

# --- Utility functions ---
# (see utility functions below)

# --- Markdown parsing functions ---
def parse_markdown(md_path):
    """Parse markdown file into a structured dict of sections."""
    with open(md_path, 'r') as f:
        text = f.read()
    # Parse headings, tables, lists, field values...
    # Return a dict keyed by section name
    ...

# --- Main script ---
def main():
    # Parse markdown content
    content = parse_markdown(MARKDOWN)

    # Copy template to output (template stays untouched)
    shutil.copy2(TEMPLATE, OUTPUT)

    # Read output ODT
    with zipfile.ZipFile(OUTPUT, 'r') as z:
        content_xml = z.read('content.xml')
        all_files = z.namelist()
        file_data = {n: z.read(n) for n in all_files if n != 'content.xml'}

    root = etree.fromstring(content_xml)
    body = root.find('.//office:body/office:text', NS)
    elements = list(body)

    # Map parsed markdown content onto template elements...

    # Save output
    new_content_xml = etree.tostring(root, xml_declaration=True, encoding='UTF-8')
    with zipfile.ZipFile(OUTPUT, 'w', zipfile.ZIP_DEFLATED) as zout:
        zout.writestr('content.xml', new_content_xml)
        for name, data in file_data.items():
            zout.writestr(name, data)

if __name__ == '__main__':
    main()
```

**Key difference from in-place modification:** The template is copied to the output path first, then the output is modified. The template file is never altered, so it can be reused for future reports.

### Phase 4: Verify

After running the populate script, verify the output:

1. **Check for remaining placeholders** — Search the output document's XML for any `<` or `>` placeholder markers that weren't replaced
2. **Check element counts** — Verify cloned sections have the expected number of elements (e.g., 15 gap blocks should produce 15 headings)
3. **Open in LibreOffice** — Use `libreoffice/open_document_in_libreoffice` to visually confirm formatting is preserved
4. **Spot-check content** — Verify representative content appears correctly in the output

**Verification script pattern:**

```python
#!/usr/bin/env python3
"""Verify populated template."""
import zipfile
from lxml import etree

NS = { ... }

with zipfile.ZipFile('<output.odt>', 'r') as z:
    root = etree.fromstring(z.read('content.xml'))

body = root.find('.//office:body/office:text', NS)

# Check for remaining placeholders
for elem in body.iter():
    text = (elem.text or '') + (elem.tail or '')
    if '<' in text and '>' in text:
        print(f"PLACEHOLDER REMAINING: {text[:80]}")

# Count specific elements
headings = body.findall('.//text:h', NS)
tables = body.findall('.//table:table', NS)
print(f"Headings: {len(headings)}")
print(f"Tables: {len(tables)}")
```

## Utility Functions Reference

These are the reusable Python functions for ODT template manipulation. Copy them into your populate script.

### ODF Namespace Constants

```python
NS = {
    'text': 'urn:oasis:names:tc:opendocument:xmlns:text:1.0',
    'table': 'urn:oasis:names:tc:opendocument:xmlns:table:1.0',
    'office': 'urn:oasis:names:tc:opendocument:xmlns:office:1.0',
    'style': 'urn:oasis:names:tc:opendocument:xmlns:style:1.0',
    'fo': 'urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0',
}
```

### Core Functions

```python
def qn(ns_prefix, local):
    """Create a qualified XML name from namespace prefix and local name."""
    return '{%s}%s' % (NS[ns_prefix], local)


def get_full_text(elem):
    """Recursively get all text from an element and its children."""
    parts = []
    if elem.text:
        parts.append(elem.text)
    for child in elem:
        parts.append(get_full_text(child))
        if child.tail:
            parts.append(child.tail)
    return ''.join(parts)


def set_para_text(elem, new_text):
    """Set paragraph text, removing any child spans while preserving the paragraph's style."""
    for child in list(elem):
        elem.remove(child)
    elem.text = new_text


def set_cell_text(cell, new_text):
    """Set text in a table cell's first paragraph, creating one if needed."""
    paras = cell.findall('text:p', NS)
    if paras:
        set_para_text(paras[0], new_text)
    else:
        p = etree.SubElement(cell, qn('text', 'p'))
        p.text = new_text


def clone_table_row(table, template_row_index, data_list):
    """
    Clone a template data row for each entry in data_list.

    Args:
        table: The table:table element
        template_row_index: Index of the row to use as template (0 = header, 1 = first data row)
        data_list: List of lists — one list of cell values per new row

    The template row is cloned once per entry, populated, and the original template row is removed.
    """
    rows = table.findall('table:table-row', NS)
    template_row = rows[template_row_index]
    parent = template_row.getparent()
    insert_point = template_row

    for row_data in data_list:
        new_row = copy.deepcopy(template_row)
        cells = new_row.findall('table:table-cell', NS)
        for ci, val in enumerate(row_data):
            if ci < len(cells):
                set_cell_text(cells[ci], val)
        insert_point.addnext(new_row)
        insert_point = new_row

    parent.remove(template_row)
```

### ODT ZIP Read/Write Pattern

```python
import zipfile, shutil

# Copy template to output (template stays pristine)
shutil.copy2(template_path, output_path)

# Read output ODT
with zipfile.ZipFile(output_path, 'r') as z:
    content_xml = z.read('content.xml')
    all_files = z.namelist()
    file_data = {n: z.read(n) for n in all_files if n != 'content.xml'}

root = etree.fromstring(content_xml)
body = root.find('.//office:body/office:text', NS)

# ... modify body elements ...

# Write — repack ALL files in the output, replacing only content.xml
new_content_xml = etree.tostring(root, xml_declaration=True, encoding='UTF-8')
with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zout:
    zout.writestr('content.xml', new_content_xml)
    for name, data in file_data.items():
        zout.writestr(name, data)
```

## ODT XML Structure Reference

Quick reference for common ODF element patterns encountered in templates.

### Paragraphs

```xml
<text:p text:style-name="P9">Body text content here</text:p>
```
- Style name (e.g., `P9`, `Standard`) controls font, size, spacing, alignment
- `set_para_text()` preserves the style while replacing text

### Headings

```xml
<text:h text:style-name="P10" text:outline-level="2">Section Title</text:h>
```
- `text:outline-level` determines heading level (1 = H1, 2 = H2, etc.)
- Style name controls appearance (font size, bold, color, etc.)

### Tables

```xml
<table:table table:name="Table1">
  <table:table-column ... />
  <table:table-row>                          <!-- header row -->
    <table:table-cell>
      <text:p text:style-name="P12">Header</text:p>
    </table:table-cell>
  </table:table-row>
  <table:table-row>                          <!-- data row (clone this) -->
    <table:table-cell>
      <text:p text:style-name="P13">Data</text:p>
    </table:table-cell>
  </table:table-row>
</table:table>
```
- Row 0 is typically the header row — never clone it
- Row 1 is typically the template data row — clone it for each data entry
- `clone_table_row()` handles this pattern

### Line Breaks

```python
# Insert a line break within a paragraph
lb = etree.SubElement(paragraph, qn('text', 'line-break'))
lb.tail = "Text after the line break"
```
- Use instead of `\n` — ODT does not interpret newlines as line breaks

### Element Navigation

```python
next_elem = elem.getnext()           # Next sibling element
prev_elem = elem.getprevious()       # Previous sibling element
parent = elem.getparent()            # Parent element
elem.addnext(new_elem)               # Insert new_elem after elem
elem.addprevious(new_elem)           # Insert new_elem before elem
parent.remove(elem)                  # Remove elem from parent
```

### Finding Elements After Modification

After inserting or removing elements, the original `elements = list(body)` snapshot is stale. To find elements after modification:

```python
# By table name attribute
for t in body.findall('.//table:table', NS):
    if t.get(qn('table', 'name')) == 'Table4':
        target_table = t

# By text content
for elem in body:
    if get_full_text(elem).strip().startswith('Some heading text'):
        target = elem
```

## Template Design Conventions

When creating ODT templates intended for population with this skill:

1. **Use `< angle bracket >` placeholders** for variable content (e.g., `<Client Name>`, `<Date>`). These are easy to search for during verification.

2. **Include exactly one example data row** in tables that need cloning. The `clone_table_row()` function uses this row as a template and removes it after cloning.

3. **Include exactly one example block** for repeating sections (e.g., gap findings). The populate script clones this block for each entry and removes the original.

4. **Keep placeholder text in paragraph `.text`** (not inside child `<text:span>` elements) for simplest replacement. If you need styled sub-ranges within a paragraph, use spans, but `set_para_text()` will strip them.

5. **Name tables** in LibreOffice (right-click table > Table Properties > Name) so they can be found reliably by name after element indices shift during population.

6. **Use consistent paragraph styles** — each visual pattern (body text, citations, sub-headings, list items) should use a distinct named paragraph style so cloned elements inherit the correct appearance.

## Reference Implementation

A complete working example is available:

- **Template:** `Work/Clients/Qualira/Higi/special_510k/11-Gap_Assessment/[DTG] Higi_Gap_Analysis_QP-07-10.odt`
- **Populate script:** `Work/Clients/Qualira/Higi/scripts/populate_gap_report.py`
- **Markdown content:** `Work/Clients/Qualira/Higi/special_510k/11-Gap_Assessment/Higi_Gap_Analysis_QP-07-10.md`

This implementation demonstrates the full pattern:
1. Gap analysis outputs structured content as markdown
2. Analyze template structure (element indices, styles, tables)
3. Write a populate script that parses the markdown and maps content onto template elements
4. Populate cover page, executive summary, multiple tables (with row cloning), repeating gap finding blocks (with block cloning), and recommendation sections
5. Handle line breaks, dynamic paragraph insertion, and post-modification element lookup

## Integration

### With `/dtge-gap-analysis`

The gap analysis skill generates structured content as a markdown file, then uses this skill to populate a branded `[DTG]`-prefixed template. The workflow is:
1. Gap analysis produces a markdown file with all analysis content
2. This skill's populate script reads the markdown, parses it, and maps content onto the template
3. The template is copied (never modified) and the copy is populated to produce the formatted deliverable

### With `/dtge-create-dhf`

DHF document generation can use this skill for template-based document creation where branded formatting must be preserved.

### General Usage

Any skill that produces structured content for a pre-formatted ODT template can use this skill's approach. The expected flow is:
1. Upstream skill generates content as markdown
2. This skill's workflow populates a branded template from that markdown
3. The template file remains pristine and reusable
